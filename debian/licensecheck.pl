#!/usr/bin/perl -w

# Check licenses of a large subtree. It uses licensecheck from devscripts
# then postprocess the results
# (c) 2009, Fabien Tassin <fta@sofaraway.org>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use Getopt::Std;

my $white_listed_licenses = [
  'global BSD-style Chromium',
  'global BSD-style Webkit/LGPL 2.1',
  'Public domain',
  'Apache (v2.0)',
  'Apache (v2.0) GENERATED FILE',
  'Apache (v2.0) BSD (2 clause)',
  'BSD (2 clause)',
  'BSD (3 clause)',
  'BSD (3 clause) GENERATED FILE',
  'BSD (4 clause)',
  'BSL (v1.0)',
  'BSL (v1) BSD (3 clause) GENERATED FILE',
  'dual GPLv1+/Artistic License',
  'GPL (with incorrect FSF address)',
  'GPL (unversioned/unknown version)',
  'GPL (v2 or later)',
  'GPL (v2 or later) (with incorrect FSF address)',
  'GPL (v2 or later) GENERATED FILE',
  'ISC',
  'LGPL',
  'LGPL (v2)',
  'LGPL (v2 or later)',
  'LGPL (v2 or later) GENERATED FILE',
  'LGPL (v2 or later) (with incorrect FSF address)',
  'LGPL (v2 or later) (with incorrect FSF address) GENERATED FILE',
  'LGPL (v2.1 or later)',
  'LGPL (v2.1 or later) (with incorrect FSF address)',
  'MIT/X11 (BSD like)',
  'MIT/X11 (BSD like) GENERATED FILE',
  'MPL (v1.1,) GPL (unversioned/unknown version) LGPL (v2.1 or later)',
  'MPL (v1.1,) GPL (unversioned/unknown version) LGPL (v2 or later)',
  'MPL (v1.1) GPL (unversioned/unknown version)',
  'MPL (v1.1) GPL (unversioned/unknown version) GENERATED FILE',
  'zlib/libpng',
  'GENERATED FILE',
];

my $manually_identified = {
  '/third_party/sqlite/'   => [
    'Public domain',
    'The author disclaims all copyright. The library is in the public domain.'
  ],
  '/third_party/WebKit/WebKitLibraries/WebCoreSQLite3/' => [
    'Public domain',
    'The author disclaims all copyright. The library is in the public domain.'
  ],
  '/third_party/zlib/' => [
    'zlib/libpng',
    'This software is provided \'as-is\', without any express or implied'
  ],
  '/third_party/lzma_sdk/' => [
    'Public domain',
    'LZMA SDK is placed in the public domain.'
  ],
  '/third_party/hunspell/src/hunspell/' => [
    'MPL 1.1/GPL 2.0/LGPL 2.1',
    'The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License")'
  ],
  '/webkit/data/layout_tests' => [
    'global BSD-style Webkit/LGPL 2.1',
    'http://webkit.org/projects/goals.html'
  ],
};

my $opt = {};
getopts('ah', $opt) || &Usage();
&Usage() if $$opt{'h'};

sub Usage {
  die "Usage: $0 [options] directory\n" .
    "  -a           display all licenses found (default will hide whitelisted licenses)\n" .
    "  -h           this help screen\n";
}

my $dir = shift @ARGV;

sub get_license {
  my $file      = shift;
  my $license   = shift;
  my $copyright = shift;

  return("empty file", "empty") if -z $file;
  open(FILE, $file) || die "Can't open $file: $!\n";
  my $maxline = 60;
  my $linenum = 0;
  while (!eof(FILE) && defined (my $line = <FILE>) && $linenum < $maxline) {
    $linenum++;
    next unless $line =~ m/Copyright/i;
    chomp $line;
    # Remove indents/comments
    $line =~ s,^\s*(\#|/\*|//)\s*,,;
    # remove everything before the copyright
    $line =~ s/.*(Copyright)/$1/i;
    my $text = $line;
     while (!eof(FILE) && defined (my $line = <FILE>) && $linenum < $maxline) {
       chomp $line;
       # Remove indents/comments
       $line =~ s,^\s*(\#|/\*|//)\s*,,;
       $text .= " " .$line;
       $text =~ m/Copyright.*?The Chromium Authors. All rights reserved.*?BSD-style license.*?found.*?in the.*?LICENSE file/ && do {
         close FILE;
         return("global BSD-style Chromium", $text);
       } ||
       $text =~ m/It is free software.*?under the.*?terms of either.*?GNU General Public License.*?either version (\d+).*?any later version.*?Artistic License/ && do {
         close FILE;
         return("dual GPLv$1+/Artistic License", $text);
       } ||
       $text =~ m/The use and distribution terms for this software are covered by the.*?Microsoft Permissive License \(Ms-PL\).*?/ && do {
         close FILE;
         return("Ms-PL", $text);
       }
    }
  }
  close FILE;
  ($license, $copyright);
}

my $data = {};
my $line;
local *LC;
open(LC, "/usr/bin/licensecheck -r --copyright $dir |") ||
  die "Can't open /usr/bin/licensecheck: $!\n";
while (!eof(LC) && defined($line = <LC>)) {
  chomp $line;
  my ($file, $license, $copyright) = (undef, undef, 'UNKNOWN');
  if ($line =~ m/^(\S[^:]+): (.*)/) {
    $file = $1;
    $license = $2;
    $license =~ s/\s*$//;
    $line = <LC>;
    if ($line =~ m/^  \[(.*.)\]/) {
      $copyright = $1;
      $line = <LC>;
    }
    # check for manual identification
    for my $manual (keys %$manually_identified) {
      if ($file =~ m,$manual,) {
        my $res = $$manually_identified{$manual};
        ($license, $copyright) = @$res;
        last;
      }
    }
    if ($license eq 'UNKNOWN') {
      # Look further into that file. licensecheck may have missed something
      ($license, $copyright) = get_license($file, $license, $copyright);
    }
    #printf "%-80s %-30s %s\n", $file, $license, $copyright;
    my $path = $file;
    $path =~ s,/[^/]*$,,;
    push @{$$data{$path}{$license}}, [ $file, $copyright ];
    next if $line =~ m/^$/;
  }
  die "line='$line'\n";
}
close LC;

print "Whitelisted licenses: \n  - '" . (join "'\n  - '", @$white_listed_licenses) . "'\n\n" unless $$opt{'a'};

for my $dir (sort keys %$data) {
  my $l = 0;
  for my $license (sort keys %{$$data{$dir}}) {
    my $skip = 0;
    for my $w (@$white_listed_licenses) {
      $skip++ if $w eq $license;
    }
    next if !$$opt{'a'} && $skip;
    print "$dir/\n" if $l == 0;;
    $l++;
    print "  [ $license ]:\n";
    for my $file (sort { $$a[0] cmp $$b[0] } @{$$data{$dir}{$license}}) {
      printf "      %-80s  %s\n", $$file[0], $$file[1];
    }
  }
  print "\n" if $l;
}
