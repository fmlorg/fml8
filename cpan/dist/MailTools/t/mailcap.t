#!/usr/bin/env perl

require Mail::Cap;
use warnings;
use strict;

use Test::More tests => 6;

# First we create a mailcap file to test
my $mcfile = "mailcap-$$";

open MAILCAP, '>', $mcfile
    or die "Can't create $mcfile: $!";

print MAILCAP <<EOT;

# This is a comment and should be ignored

image/*; xv %s \\; echo "Showing image %s"; description=Simple image format

text/plain; cat %s;\\
  test=$^X -e "exit (!(q{%{charset}} =~ /^iso-8859-1\$/i))";\\
  copiousoutput

text/plain; smartcat %s; copiousoutput

local;cat %s;print=lpr %{foo} %{bar} %t %s

video/example; echo \\"; none

EOT
close MAILCAP;

# OK, lets parse it
my $mc = Mail::Cap->new($mcfile);
unlink($mcfile);  # no more need for this file

my $desc = $mc->description('image/gif');

print "GIF desc: $desc\n";
is($desc, "Simple image format");

my $cmd1 = $mc->viewCmd('text/plain; charset=iso-8859-1', 'file.txt');
print "$cmd1\n";
is($cmd1, "cat file.txt");

my $cmd2 = $mc->viewCmd('text/plain; charset=iso-8859-2', 'file.txt');
print "$cmd2\n";
is($cmd2, "smartcat file.txt");

my $cmd3 = $mc->viewCmd('image/gif', 'gisle.gif');
print "$cmd3\n";
is($cmd3, qq(xv gisle.gif ; echo "Showing image gisle.gif"));

my $cmd4 = $mc->printCmd('local; foo=bar', 'myfile');
print "$cmd4\n";
like($cmd4, qr/^lpr\s+bar\s+local\s+myfile$/);

my $cmd5 = $mc->viewCmd('video/example', 'myfile');
print "$cmd5\n";
is($cmd5, 'echo \"');

#$mc->dump;
