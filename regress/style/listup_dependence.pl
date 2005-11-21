#!/usr/bin/env perl
#
# $FML: list_up_dependence.pl,v 1.1 2003/05/31 04:42:31 fukachan Exp $
#

use strict;
use Carp;
use vars qw(@filter %MODULE %LOCK_CHANNEL);

(@filter) = qw(CGI
	     Calendar::Lite
	       Carp
	       Config
	     Crypt::UnixCrypt
	     Data::Dumper
	       DirHandle
	       ErrorStatus
	       Exporter
	     File::Basename
	     File::Copy
	     File::Find
	     File::Path
	     File::SimpleLock
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
	     IPC::Open2
	       Jcode
	       MD5
	     MIME::Lite
	     MIME::Base64
	     MIME::QuotedPrint
	     Mail::Address
	     Mail::Bounce
	     Mail::Header
	     Mail::Message
	       Socket
	       Socket6
	       Something
	     Term::ReadLine
	     Tie::JournaledFile 
	     Time::ParseDate
	     Unicode::Japanese
	     User::grent
	     User::pwent);

my $aggregate_to_two_level = 1;
my $shlink_key = defined $ENV{ shlink_key } ? $ENV{ shlink_key } : 1;
my $on = 0;

while (<>) {
    if (/^=head/o) { $on = 1;}
    if (/^=cut/o)  { $on = 0;}
    next if $on;

    chomp;

    if (/LOCK.*CHANNEL:\s*(\S+)/) {
	add_channel_entry($ARGV, $1);
    }

    s/\#.*$//;

    if (/(use|require)\s+([A-Z]\S+)/) {
	add_entry($ARGV, $2);
    }
}


for my $k (sort keys %MODULE) {
    my @a = keys %{$MODULE{ $k }};

    print "\n";
    printf "%-15s %s\n", $k, "";

    for my $x (@a) {
	printf "%-15s %s\n", "", module($x);
    }
}

print "\n--- lock channel list ---\n\n";

for my $k (sort keys %LOCK_CHANNEL) {
    printf "%-30s %s\n", $k, $LOCK_CHANNEL{ $k };
}

exit 0;


sub module
{
    my ($x) = @_;
    my $file = $LOCK_CHANNEL{ $x };

    return( $file ? "$x (lock at $file)" : $x);  
}


sub _clean_up
{
    my ($key) = @_;

    $key =~ s@\s*$@@g;
    $key =~ s@//@/@g;
    $key =~ s@;@@g;
    $key =~ s@\}@@g;
    $key =~ s@lib/@@g;

    return $key;
}


sub add_entry
{
    my ($file, $class) = @_;
    $file  = _clean_up($file);
    $class = _clean_up($class);

    # cut off the 3rd layer.
    if ($shlink_key && $class =~ /::/o) {
	my @c  = split(/::/, $class);
	$class = join("::", $c[0], $c[1]);
    }

    if ($aggregate_to_two_level) {
	my $xfile = $file;
	$xfile =~ s@.pm$@@;
	$xfile =~ s@/@::@g;
	if ($xfile =~ /$class/) {
	    return;
	}
    }

    unless (ignore($class)) {
	$MODULE{ $class }->{ $file } = $file;
    }
}


sub add_channel_entry
{
    my ($file, $channel) = @_;
    $file  = _clean_up($file);

    $LOCK_CHANNEL{ $file } .= " ".$channel;
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
