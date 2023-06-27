#!/usr/bin/env perl
# editcontrol.pl
#
# Script to simplify automated editing of Debian control files
# (see deb-src-control(5) for information on the format)
#
# Usage samples:
#
#   editcontrol -e '$package =~ /foo/ and s/foo/bar/' control >control.new
#
#   editcontrol -i -e 's/foo/bar/;' -e 's/bar/qux/' debian/control
#
#   editcontrol -i=.orig -f script.pl debian/control
#

use strict;
use warnings;

use Dpkg::Control::Info;
use Getopt::Long;

my @expr_list = ();
my $script_file;
my $inplace;

sub load_script_file
{
	my ($opt_name, $opt_value) = @_;
	open(F, $opt_value) or die "$opt_value: $!";
	local $/;
	my $script = <F>;
	close(F);
	push @expr_list, $script;
}

GetOptions(
	'expr=s' => \@expr_list,
	'file=s' => \&load_script_file,
	'inplace:s' => \$inplace
) or exit 1;

push @expr_list, ';1;';
my $expr = join("\n", @expr_list);
my $input_file = $ARGV[0];

my $control_info = Dpkg::Control::Info->new(filename => $input_file);
my $in_order_ref = ${$control_info->get_source()}->{'in_order'};

foreach our $control (@{$control_info})
{
	my $source  = $control->{'Source'}  || '';
	my $package = $control->{'Package'} || '';
	my $INPUT_FIELD_NUMBER = 0;

	# Subroutine callable from the user expression
	#
	sub set_field($$) {
		my ($name, $value) = @_;
		my $is_new = !exists($control->{$name});
		$control->{$name} = $value;
		if ($is_new)
		{
			# Insert new field after the current one
			splice @{$in_order_ref}, $INPUT_FIELD_NUMBER, 0, ($name);
			pop @{$in_order_ref};
		}
	}

	foreach my $field (keys(%{$control}))
	{
		local $_ = $control->{$field};
		++$INPUT_FIELD_NUMBER;

		eval $expr or die $@;

		if (defined($_)) { $control->{$field} = $_; }
		else { delete $control->{$field}; }
	}
}

my $out = $control_info->output() or die;

if (defined($inplace))
{
	local @ARGV = $input_file;
	local $^I = $inplace;
	local $/;
	my $orig = <>;
	print($out);
}
else
{
	print($out);
}

exit 0;

# end editcontrol.pl
