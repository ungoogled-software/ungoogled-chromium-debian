#!/bin/bash
#
# Check for new "chromium" package(s) on Debian without all the overhead of
# the GitHub workflow. This script can be invoked from cron(8), from a mail
# delivery agent (e.g. maildrop(1)), or directly.
#
# Recommended crontab entry:
#
#     15 */4 * * *  /path/to/remote-check.sh --cron
#
# Mail invocation is intended for use with the Debian package tracker at
# https://tracker.debian.org/ . Create an account with your e-mail address,
# and subscribe to the "chromium" source package, with the "upload-source"
# keyword. Configure your MDA to match on messages with the following
# header fields:
#
#     From: Debian FTP Masters <ftpmaster@ftp-master.debian.org>
#     Subject: Accepted chromium *** (source) into ***
#
# (where "***" is a short string match, like a /.+/ regex. You can see past
# instances of these messages under the "news" section at the tracker's
# Chromium page: https://tracker.debian.org/pkg/chromium)
#
# Then, have it execute this script as
#
#     /path/to/remote-check.sh --mail
#
# To invoke the GitHub workflow, you'll need to create a "fine-grained
# personal access token" here:
#
#   https://github.com/settings/tokens?type=beta
#
# Under "Repository access", specify the ungoogled-chromium-debian repo,
# and under "Repository permissions -> Contents", grant "read and write"
# access. Then place the token string in a file token.txt in the state
# directory (see below).
#
# You can invoke the workflow directly with "remote-check.sh --start".
#

state_dir=$HOME/.cache/uc-remote-check
github_repo=ungoogled-software/ungoogled-chromium-debian

debian_incoming_url=https://incoming.debian.org/debian-buildd
debian_security_url=https://security.debian.org/debian-security

common_curl_args="--hsts $state_dir/curl-hsts.txt --max-time 30 --no-progress-meter"

log()
{
	local message="$1"
	local dt=$(date --rfc-3339=sec)
	echo "[$dt]${message:+ $message}"
}

start_workflow()
{
	local github_token=$(cat $state_dir/token.txt 2>/dev/null)

	case "$github_token" in
		github_pat_*) ;;
		'') echo 'Cannot start workflow, no GitHub token present'; return 0 ;;
		*) echo 'Error: Invalid GitHub token'; return 2 ;;
	esac

	log "Starting release workflow at $github_repo"

	local headers_file=$state_dir/tmp.headers.txt

	(umask 077; cat > $headers_file) << END
Accept: application/vnd.github+json
Authorization: token $github_token
END

	curl \
		--header @$headers_file \
		--data '{"event_type": "new-debian-version"}' \
		--fail-with-body \
		$common_curl_args \
		https://api.github.com/repos/$github_repo/dispatches
}

do_check()
{
	local hash_dsc_file=$state_dir/debian-hash-dsc.txt
	local seen_dsc_file=$state_dir/debian-seen-dsc.txt

	local index=$state_dir/tmp.index-1.txt
	local index_concat=$state_dir/tmp.index-2.txt
	local new_dsc_file=$state_dir/tmp.new-dsc.txt

	log 'Checking Debian servers ...'

	: > $index_concat
	: > $new_dsc_file

	local url
	for url in \
		$debian_incoming_url \
		$debian_security_url
	do
		curl \
			--output $index \
			--compressed \
			--fail \
			$common_curl_args \
			$url/pool/main/c/chromium/

		# Note: The "incoming" server may return a 404 when no
		# recent package release is available

		cat $index >> $index_concat 2>/dev/null
	done

	# First-level check

	local dsc_hash=$(grep -F .dsc $index_concat | md5sum | awk '{print $1}')
	local prev_dsc_hash=$(cat $hash_dsc_file 2>/dev/null)

	if [ "_$dsc_hash" = "_$prev_dsc_hash" ]
	then
		echo 'No change in available .dsc files'
		return 1
	fi

	# Second-level check

	grep -Eo ' href="[^ "]+\.dsc"' $index_concat \
	| cut -d'"' -f2 \
	| while read dsc
	do
		if ! grep -Fqx "$dsc" $seen_dsc_file 2>/dev/null
		then
			echo "Found new .dsc file: $dsc"
			echo "$dsc" >> $new_dsc_file
		fi
	done

	if [ ! -s $new_dsc_file ]
	then
		echo 'No new .dsc file(s) found'
		rm -f $new_dsc_file
		return 1
	fi

	# New release found

	if [ -f $seen_dsc_file ]
	then
		start_workflow || return
	else
		echo 'Initial run, not starting workflow'
	fi

	cat $new_dsc_file >> $seen_dsc_file
	echo $dsc_hash > $hash_dsc_file

	rm -f $new_dsc_file
}

from_cron=false
from_mail=false
start=false

case "$1" in
	--cron) from_cron=true ;;
	--mail) from_mail=true ;;
	--start) start=true ;;
esac

mkdir -p $state_dir || exit
tty -s || exec >> $state_dir/log.txt 2>&1

if $from_cron
then
	sleep_time=$((RANDOM % 300))
	log "Started from cron, waiting $sleep_time seconds ..."
	sleep $sleep_time
	do_check
elif $from_mail
then
	log 'Started by mail message'
	for try in $(seq 1 20)
	do
		! do_check || break
		sleep_time=$((90 + RANDOM % 30))
		log "Waiting $sleep_time seconds ..."
		sleep $sleep_time
	done
elif $start
then
	start_workflow
else
	do_check
fi

rm -f $state_dir/tmp.*
echo

# EOF
