#!/bin/bash
# obs-upload.sh
#
# Upload Debian source package files to the openSUSE Build Service
# (https://build.opensuse.org/)
#

set -e

test -n "$DOWNLOAD_DIR"
test -n "$OUTPUT_DIR"
test -n "$WORK_DIR"

upload_dir=$WORK_DIR/upload

for var in OSC_USERNAME OSC_PASSWORD
do
	if test -z "$(eval echo \$$var)"
	then
		echo "$var is not set in the environment. Aborting."
		exit 1
	fi
done

test -n "$OSC" || OSC=osc
test -n "$OBS_PROJECT" || export OBS_PROJECT="home:$OSC_USERNAME"

# Do NOT use a config file, just rely on the env vars
#
export OSC_CONFIG=/dev/null

if ! $OSC --help > /dev/null 2>&1
then
	echo 'osc(1) is not available. Aborting.'
	exit 1
fi

# API reference: https://api.opensuse.org/apidocs/

osc_add_file()
{
	local project="$1" package="$2" local_file="$3" remote_file="$4"
	test -n "$remote_file" || remote_file="$local_file"

	$OSC api -T "$local_file" "/source/$project/$package/$remote_file" > /dev/null
}

osc_delete_file()
{
	local project="$1" package="$2" file="$3"

	$OSC api -X DELETE "/source/$project/$package/$file" > /dev/null
}

osc_commit()
{
	local project="$1" package="$2" comment="$3"
	local comment_enc=$(printf '%s' "$comment" | jq -Rrs @uri)

	# Note: The regular "osc commit" command requires a checked-out
	# package directory, and is thus not suitable for our use here

	$OSC api -m POST "/source/$project/$package?cmd=commit&comment=$comment_enc" > /dev/null
}

obs_sync_files()
{
	local codename="$1" dir="$2" commit_message="$3"
	local remote_list=$WORK_DIR/remote-files.txt

	echo "Syncing files to OBS project/package: $OBS_PROJECT/$codename"

	$OSC list -l $OBS_PROJECT $codename > $remote_list

	(cd $dir

	do_commit=false

	while read md5 rev size d1 d2 d3 remote_file
	do
		if [ ! -f "$remote_file" ]
		then
			echo "D    $codename/$remote_file ..."
			osc_delete_file $OBS_PROJECT $codename "$remote_file"
			do_commit=true
		fi
	done < $remote_list

	for local_file in *
	do
		do_upload=false

		if awk -v file="$local_file" \
			'$7 == file {print "found"}' $remote_list \
		   | grep -q .
		then
			# File present on OBS, check MD5 sum
			md5=$(md5sum "$local_file" | awk '{print $1}')
			awk \
				-v md5="$md5" \
				-v file="$local_file" \
				'$1 == md5 && $7 == file {print "found"}' \
				$remote_list \
			| grep -q . || do_upload=true
		else
			# File not present on OBS
			do_upload=true
		fi

		if $do_upload
		then
			echo "A    $codename/$local_file ..."
			osc_add_file $OBS_PROJECT $codename "$local_file"
			do_commit=true
		fi
	done

	if $do_commit
	then
		echo 'Committing update ...'
		osc_commit $OBS_PROJECT $codename "$commit_message"
	else
		echo 'No changes to commit.'
	fi

	) # return to previous dir

	rm -f $remote_list
}

for dsc_file in $OUTPUT_DIR/*/*.dsc
do
	dir=$(dirname $dsc_file)
	codename=$(basename $dir)

	package=$(sed -n 's/^Source: //p'  $dsc_file)
	version=$(sed -n 's/^Version: //p' $dsc_file)

	sums=$(grep -E '^ [0-9a-f]{64} ' $dsc_file)

	orig_src=$(echo   "$sums" | awk '/\.orig\.tar\./   {print $3}')
	debian_src=$(echo "$sums" | awk '/\.debian\.tar\./ {print $3}')

	dsc_sha256=$(sha256sum $dsc_file | awk '{print $1}')

	orig_src_sha256=$(echo   "$sums" | awk '/\.orig\.tar\./   {print $1}')
	debian_src_sha256=$(echo "$sums" | awk '/\.debian\.tar\./ {print $1}')

	chromium_orig_src=$DOWNLOAD_DIR/${orig_src#ungoogled-}
	test -s $chromium_orig_src

	run_url=
	test -z "$GITHUB_RUN_ID" || run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

	if [ -n "$run_url" ]
	then
		comment="Origin: $run_url"
	else
		comment="Origin: manual upload"
	fi

	rm -rf   $upload_dir
	mkdir -p $upload_dir

	ln $dsc_file $dir/$debian_src $upload_dir/
	ln $chromium_orig_src $upload_dir/$orig_src

	# Reference: https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService
	#
	cat > $upload_dir/_service << END
<!-- $comment -->
<services>
  <service name="verify_file">
    <param name="file">$orig_src</param>
    <param name="verifier">sha256</param>
    <param name="checksum">$orig_src_sha256</param>
  </service>
  <service name="verify_file">
    <param name="file">$debian_src</param>
    <param name="verifier">sha256</param>
    <param name="checksum">$debian_src_sha256</param>
  </service>
  <service name="verify_file">
    <param name="file">$(basename $dsc_file)</param>
    <param name="verifier">sha256</param>
    <param name="checksum">$dsc_sha256</param>
  </service>
</services>
END

	commit_message="$package $version

$comment"

	obs_sync_files $codename $upload_dir "$commit_message"
	echo ' '
done

# end obs-upload.sh
