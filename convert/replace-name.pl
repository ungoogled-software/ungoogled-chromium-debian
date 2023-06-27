# replace-name.pl
#
# This script operates on files under the debian/ directory. It (very)
# selectively replaces instances of "chromium" and "Chromium" to $name
# and $display_name, respectively. It also makes a few additional edits
# related to this name change.
#

use strict;
use warnings;

my $name = 'ungoogled-chromium';
my $display_name = 'Ungoogled-Chromium';

s,\b(	  apps
	| bin
	| bug
	| debian
	| etc
	| lib
	| pixmaps
	| scripts
	| share
)/(chromium)\b,$1/$name,gx;

s,\b(	  CHROME_DESKTOP="?
	| Icon=
	| StartupWMClass=
	| man[ ]
)(chromium)\b,$1$name,gx;

s,(	  <executable>
	| <icon-name>
	| \$dest/
)(chromium)\b,$1$name,gx;

s,(<name>)(Chromium)\b,$1$display_name,g;

# for man page and associated postprocessing in debian/rules
if (m,^\tsed -e s/\@\@PACKAGE\@\@/,)
{
	my $orig_exprs = $_;
	$orig_exprs =~ s/\bsed\b/   /;
	$orig_exprs =~ s,\b(chromium)\b,$name,g;
	# don't change the user config/cache directory locations
	s#-e .+$#-r -e 's,(\\\$HOME/\\.[a-z]+/\@\@)PACKAGE(\@\@),\\1CONFIGNAME\\2,g' \\#;
	$_ .= "\t    -e s/\@\@CONFIGNAME\@\@/chromium/ \\\n";
	$_ .= $orig_exprs;
}
#
s,\b(out/Release)/(chromium)\.(\d)\b,$1/$name.$3,g;

# for .bug-control file
/^report-with:/ and s/\b(chromium)\b/$name/g;

# for .desktop file
/^Name(\[\w+\])?=/ and s,\b(Chromium)\b,$display_name,g;

# for launcher script
if (/^APPNAME=(chromium)$/)
{
	s/=/_INT=/;
	$_ = "APPNAME=$name\n" . $_;
}
#
/\$(CHROMIUM_FLAGS|GDB)/ and s,(\$LIBDIR/\$APPNAME)\b,${1}_INT,g;

# EOF
