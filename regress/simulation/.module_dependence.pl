#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use vars qw(@filter %MODULE);

(@filter) = qw(CGI
	     Calendar::Lite
	       Carp
	       Config
	     Crypt::UnixCrypt
	       DirHandle
	       ErrorStatus
	     File::Basename
	     File::Copy
	     File::Find
	     File::Path
	     File::Spec
	     File::stat
	       FileHandle
	       Fcntl
	     Getopt::Long
	     HTML::CalendarMonthSimple
	     HTML::FromText
	     IM::EncDec
	     IM::Iso2022jp
	     IO::File
	     IO::Handle
	     IO::Socket
	       Jcode
	       MD5
	     MIME::Lite
	     MIME::Base64
	     MIME::QuotedPrint
	     Mail::Address
	     Mail::Header
	     Mail::Message
	       Socket
	       Socket6
	       Something
	     Term::ReadLine
	     Time::ParseDate
	     Unicode::Japanese
	     User::grent
	     User::pwent);


my $on = 0;
while (<>) {
    if (/^=head/o) { $on = 1;}
    if (/^=cut/o)  { $on = 0;}
    next if $on;

    chomp;

    s/\#.*$//;

    if (/use\s+([A-Z]\S+)/) {
	add_entry($ARGV, $1);
    }
}


for my $k (sort keys %MODULE) {
    my @a = keys %{$MODULE{ $k }};

    print "\n";
    printf "%-20s %s\n", $k, "";

    for my $x (@a) {
	printf "%-20s %s\n", "", $x;
    }
}

exit 0;


sub add_entry
{
    my ($file, $class) = @_;

    $file =~ s@\s*$@@g;
    $file =~ s@//@/@g;
    $file =~ s@;@@g;
    $file =~ s@\}@@g;
    $file =~ s@lib/@@g;

    $class =~ s@\s*$@@g;
    $class =~ s@//@/@g;
    $class =~ s@;@@g;
    $class =~ s@\}@@g;
    $class =~ s@lib/@@g;

    # cut off the 3rd layer.
    if (1 && $class =~ /::/o) {
	my @c  = split(/::/, $class);
	$class = join("::", $c[0], $c[1]);
    }


    unless (ignore($class)) {
	$MODULE{ $class }->{ $file } = $file;
    }
}


sub ignore
{
    my ($class) = @_;
    my $filter  = join("|", @filter);

    if ($class =~ /^FML/) {
	return 1;
    }
    elsif ($class =~ /^($filter)/) {
	return 1;
    }

    return 0;
}
