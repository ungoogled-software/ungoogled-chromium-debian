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
  'global BSD-style libjingle',
  'Public domain',
  'Apache (v2.0)',
  'Apache (v2.0) GENERATED FILE',
  'Apache (v2.0) BSD (2 clause)',
  'BSD (2 clause)',
  'BSD (2 clause) GENERATED FILE',
  'BSD (2 clause)/LGPL 2 (or later)/LGPL 2.1 (or later)',
  'BSD (2 or 3 clause)',
  'BSD (3 clause)',
  'BSD (3 clause) GENERATED FILE',
  'BSD (2 clause) MIT/X11 (BSD like)',
  'BSL (v1.0)',
  'BSL (v1) BSD (3 clause) GENERATED FILE',
  'ICU-License',
  'dual GPLv1+/Artistic License',
  'GPL (with incorrect FSF address)',
  'GPL (unversioned/unknown version)',
  'GPL (v2 or later)',
  'GPL (v2 or later) compatible',
  'GPL (v2 or later) (with incorrect FSF address)',
  'GPL (v2 or later) GENERATED FILE',
  'GPL 2.0/LGPL 2.1/MPL 1.1 tri-license',
  'harfbuzz-License',
  'ISC GENERATED FILE',
  'ISC',
  'LGPL',
  'LGPL (v2)',
  'LGPL (v2 or later)',
  'LGPL (v2 or later) GENERATED FILE',
  'LGPL (v2.1 or later) GENERATED FILE',
  'LGPL (v2 or later) (with incorrect FSF address)',
  'LGPL (v2 or later) (with incorrect FSF address) GENERATED FILE',
  'LGPL (v2.1)',
  'LGPL (v2.1 or later)',
  'LGPL (v2.1 or later) (with incorrect FSF address)',
  'MIT/X11 (BSD like)',
  'MIT/X11 (BSD like) GENERATED FILE',
  'MIT/X11-like (expat)',
  'MPL (v1.1,) GPL (unversioned/unknown version) LGPL (v2.1 or later)',
  'MPL (v1.1,) GPL (unversioned/unknown version) LGPL (v2 or later)',
  'MPL (v1.1,) BSD (3 clause) GPL (unversioned/unknown version) LGPL (v2.1 or later)',
  'MPL (v1.1) GPL (unversioned/unknown version)',
  'MPL (v1.1) GPL (unversioned/unknown version) GENERATED FILE',
  'MPL 1.1/GPL 2.0/LGPL 2.1',
  'zlib/libpng',
  'GENERATED FILE',
  '*No copyright* Apache (v2.0)',
  '*No copyright* BSD (2 clause)',
  '*No copyright* GPL (v2 or later)',
  '*No copyright* LGPL (v2 or later)',
  '*No copyright* LGPL (v2.1 or later)',
  '*No copyright* GENERATED FILE',
  '*No copyright* Public domain',
  'ZERO-CODE-FILES or GENERATED',
];

my $manually_identified = {
  '/base/third_party/dmg_fp/'   => [
    'MIT/X11 (BSD like)',
    'Copyright (c) 1991, 2000, 2001 by Lucent Technologies.'
  ],
  '/base/third_party/purify/pure_api.c'   => [
    'Public domain',
    'Explicitly no copyright'
  ],
  '/base/third_party/purify/pure.h'   => [
    'Public domain',
    '(C) Copyright IBM Corporation. 2006, 2006. All Rights Reserved.'
  ],
  '/third_party/sqlite/'   => [
    'Public domain',
    'The author disclaims all copyright. The library is in the public domain.'
  ],
  '/src/chrome/'   => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/depot_tools/tests/pymox/'   => [
    'Apache (v2.0)',
    'No copyright'
  ],
  '/googleurl/'   => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/gpu/command_buffer/common/GLES2/'   => [
    'SGI Free Software B License (v2.0)',
    'No copyright'
  ],
  '/media/tools/qt_faststart/qt_faststart.c'   => [
    'Public domain',
    'No copyright'
  ],
  '/native_client/src/third_party/libxt/'   => [
    'MIT/X11 (BSD like)',
    'No copyright'
  ],
  '/native_client/'   => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/v8/test/cctest/'   => [
    'BSD (3 clause)',
    'No copyright'
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
  '/third_party/WebKit/JavaScriptCore/icu' => [
    'ICU-License',
    'Copyright (c) 1995-2006 International Business Machines Corporation and others'
  ],
  '/third_party/WebKit/WebCore/icu/' => [
    'ICU-License',
    'Copyright (c) 1995-2006 International Business Machines Corporation and others'
  ],
  '/third_party/icu/' => [
    'ICU-License',
    'Copyright (c) 1995-2009 International Business Machines Corporation and others'
  ],
  '/third_party/harfbuzz/' => [
    'harfbuzz-License',
    'Copyright: 2000-2009 Red Hat, Inc'
  ],
  '/third_party/WebKit/JavaScriptCore/ForwardingHeaders/' => [
    'ZERO-CODE-FILES or GENERATED',
    'No copyright'
  ],
  '/third_party/WebKit/WebCore/ForwardingHeaders/' => [
    'ZERO-CODE-FILES or GENERATED',
    'No copyright'
  ],
  'build-tree/src/third_party/WebKit/WebCore/' => [
    'BSD (2 clause)/LGPL 2 (or later)/LGPL 2.1 (or later)',
    'No copyright'
  ],
  'third_party/WebKit/JavaScriptCore/' => [
    'BSD (2 clause)/LGPL 2 (or later)/LGPL 2.1 (or later)',
    'No copyright'
  ],
  'version.h' => [
    'ZERO-CODE-FILES or GENERATED',
    'No copyright'
  ],
  '/third_party/libjingle/files/talk/' => [
    'global BSD-style libjingle',
    'No copyright'
  ],
  '/third_party/skia/' => [
    'Apache (v2.0)',
    'No copyright'
  ],
  '/third_party/hunspell/' => [
    'GPL 2.0/LGPL 2.1/MPL 1.1 tri-license',
    'No copyright'
  ],
  '/third_party/expat/' => [
    'MIT/X11-like (expat)',
    'No copyright'
  ],
  '/third_party/yasm/source/patched-yasm/modules/parsers/nasm/' => [
    'LGPL',
    'No copyright'
  ],
  '/third_party/yasm/source/patched-yasm/modules/preprocs/' => [
    'LGPL',
    'No copyright'
  ],
  '/third_party/yasm/source/patched-yasm/modules/' => [
    'BSD (2 or 3 clause)',
    'No copyright'
  ],
  '/third_party/yasm/source/patched-yasm/tools/python-yasm/' => [
    'LGPL',
    'No copyright'
  ],
  '/third_party/yasm/' => [
    'GPL (v2 or later) compatible',
    'Copyright (c) 2001-2009 Peter Johnson and other Yasm developers.'
  ],
  '/third_party/tlslite/' => [
    'Public domain',
    'No copyright'
  ],
  '/third_party/ffmpeg/' => [
    'GPL (v2 or later) compatible',
    'No copyright'
  ],
  '/third_party/libevent/' => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/third_party/protobuf2/src/' => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/third_party/tcmalloc/tcmalloc/' => [
    'BSD (3 clause)',
    'No copyright'
  ],
  '/third_party/xdg-utils/' => [
    'MIT/X11 (BSD like)',
    'No copyright'
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
        my $tmp_license = "";
        my $tmp_copyright = "";
        ($tmp_license, $tmp_copyright) = @$res;
        if (!$copyright || $copyright =~ /.*no copyright.*/ ) {
          $copyright = $tmp_copyright;
        }
        if (!$license || $license eq "UNKNOWN" || $license eq "*No copyright* UNKNOWN") {
          $license = $tmp_license;
        }
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
    push @{$$data{$path}{$license}{$copyright}}, [ $file ];
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
    $l++;
    for my $copyright (sort keys %{$$data{$dir}{$license}}) {
      my @values = values %{$$data{$dir}{$license}};
      if ($#values == 1) {
        printf "Files: %s/*\n", $dir;
      } else {
        printf "Files: %s/{", $dir;
        my $first = 1;
        for my $file (sort { $$a[0] cmp $$b[0] } @{$$data{$dir}{$license}{$copyright}}) {
          if ($first) {
            $first = 0;
          } else { 
            printf ",";
          }
          my $filename = $$file[0];
          $filename =~ s/$dir\///;
          printf "%s", $filename;
        }
        printf "}\n";
      }
      print "Copyright: $copyright:\n";
      print "License: $license\n";
      print "\n";
    }
  }
}
