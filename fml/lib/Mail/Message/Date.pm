#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi
# Copyright (C) 2009,2010,2012 Ken'ichi Fukamachi
#
# $FML: Date.pm,v 1.32 2012/04/15 06:42:52 fukachan Exp $
#

package Mail::Message::Date;

=head1 NAME

Mail::Message::Date - utilities for date and time.

=head1 SYNOPSIS

   use Mail::Message::Date;
   $date = new Mail::Message::Date time;

   # get the date in $style format
   $date->{ log_file_style }
   $date->log_file_style

=head1 DESCRIPTION

The style you can use follows:

    style                       example
    ----------------------------------------------
    log_file_style              01/01/07 21:06:19
    mail_header_style           Sun, 7 Jan 2001 21:06:19 +0900
    YYYYMMDD                    20010107
    current_time                200101072106
    precise_current_time        20010107210619


=head1 METHODS

You can also method like $date->$style() style.
specify the C<style> name described above as a method.

=head2 log_file_style()

=head2 mail_header_style()

=head2 YYYYMMDD()

=head2 current_time()

=head2 precise_current_time()

=head2 stardate()

return STAR TREK stardate :-)

=cut


use vars qw($TimeZone);
use strict;
use Carp;


#
# XXX-TOOD: OLD STYLE -> NEW .
#


# Descriptions: constructor.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: create date object by _date()
# Return Value: OBJ
sub new
{
    my ($self, $time) = @_;

    if (defined($time) && time && $time !~ /^\d+$/o) {
	my $me = {};
	$time = date_to_unixtime($me, $time);
    }

    my $date_set = _date($time);
    return bless $date_set, $self;
}


# Descriptions: prepare date by several time format.
#    Arguments: NUM($time)
# Side Effects: create object
# Return Value: HASH_REF
sub _date
{
    my ($time) = @_;
    my ($date) = {};

    # use the current UTC if $time is not given.
    $time ||= time;

    my @WDay  = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    my @Month = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
		 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

    $TimeZone ||= _speculate_timezone();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = (localtime($time))[0..6];

    $date->{'log_file_style'} =
	sprintf("%02d/%02d/%02d %02d:%02d:%02d",
		($year % 100), $mon + 1, $mday, $hour, $min, $sec);

    $date->{'mail_header_style'} =
	sprintf("%s, %d %s %d %02d:%02d:%02d %s",
		$WDay[$wday], $mday, $Month[$mon],
		1900 + $year, $hour, $min, $sec, $TimeZone);

    $date->{'YYYY'} = sprintf("%04d", 1900 + $year);
    $date->{'MM'}   = sprintf("%02d", $mon + 1);
    $date->{'DD'}   = sprintf("%02d", $mday);

    $date->{'YYYYMMDD'} =
	sprintf("%04d%02d%02d", 1900 + $year, $mon + 1, $mday);

    $date->{'current_time'} =
	sprintf("%04d%02d%02d%02d%02d",
		1900 + $year, $mon + 1, $mday, $hour, $min);

    $date->{'precise_current_time'} =
	sprintf("%04d%02d%02d%02d%02d%02d",
		1900 + $year, $mon + 1, $mday, $hour, $min, $sec);

    return $date;
}


=head2 set($date)

    $date = new Mail::Message::Date;
    $date->set("Tue Dec 30 17:06:34 JST 2003");
    $date->to_unixtime();
    print $date->as_str(), "\n";

=cut


# Descriptions: set date.
#    Arguments: OBJ($self) STR($date)
# Side Effects: none
# Return Value: none
sub set
{
    my ($self, $date) = @_;
    my $time = $self->date_to_unixtime($date);
    my $type = _date($time);
    my ($k, $v);

    while(($k, $v) = each %$type) {
	$self->{ $k } = $v;
    }

    # flag on
    $self->{ _default_unixtime } = $time;
}


# Descriptions: return date as logfile style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub log_file_style
{
    my ($self, $time) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);
    return $p->{'log_file_style'};
}


# Descriptions: return date as Date: style date.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub mail_header_style
{
    my ($self, $time) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);
    return $p->{'mail_header_style'};
}


# Descriptions: return date as YYYYMMDD style date.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub YYYYMMDD
{
    my ($self, $time) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);
    return $p->{'YYYYMMDD'};
}


# Descriptions: return date as e.g. 1999/09/13 style.
#    Arguments: OBJ($self) NUM($time) STR($sep)
# Side Effects: none
# Return Value: STR
sub YYYYxMMxDD
{
    my ($self, $time, $sep) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);

    $sep ||= '/'; # 1999/09/13 by default
    return $p->{ YYYY }. $sep . $p->{ MM }. $sep. $p->{ DD };
}


# Descriptions: return date as YYYYMMDD.HHMM.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);
    return $p->{'current_time'};
}


# Descriptions: return date as YYYYMMDD.HHMMSS.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub precise_current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || $self->{ _default_unixtime } || time);
    return $p->{'precise_current_time'};
}


# Descriptions: return date as Star Trek stardate()
#                  stardate(tm, issue, integer, fraction)
#                           unsigned long tm;
#                           long *issue, *integer, *fraction;
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR(stardate)
sub stardate
{
    my ($self) = @_;
    my ($issue, $integer, $fraction);

    # It would be convenient to calculate the fractional part with
    # *fraction = ( (tm%17280) *1000000) / 17280;
    # but the long int type may not be long enough for this (it requires 36
    # bits).  Cancelling the 1000000 with the 17280 gives an expression that
    # takes only 27 bits.

    $fraction = int (    (((time % 17280) * 3125) / 54)   );

    # Get integer part.
    $integer = time / 17280 + 9350;

    # At this stage, *integer contains the issue number in the obvious place,
    # biased to always be non-negative.  The issue number can be extracted by
    # simply dividing *integer by 10000 and offsetting it appropriately:

    $issue = int($integer / 10000) - 36;

    # Remove the issue number from *integer.

    $integer = $integer % 10000;

    return sprintf("[%d]%04d.%02.2s", $issue, $integer, $fraction);
}


my $debug_mti = 0;

# TIME ZONES: RFC822 except for "JST"
my %zone = ("JST", "+0900",
	    "UT",  "+0000",
	    "GMT", "+0000",
	    "EST", "-0500",
	    "EDT", "-0400",
	    "CST", "-0600",
	    "CDT", "-0500",
	    "MST", "-0700",
	    "MDT", "-0600",
	    "PST", "-0800",
	    "PDT", "-0700",
	    "Z",   "+0000",
	    );


# Descriptions: dummy log function.
#    Arguments: STR($s)
# Side Effects: none
# Return Value: none
sub _log
{
    my ($s) = @_;

    # XXX_TODO: valid use of STDERR ???
    print STDERR $s, "\n" if defined $s;
}


# Descriptions: return unix time converted from given date string.
#    Arguments: OBJ($self) STR($time)
# Side Effects: none
# Return Value: NUM
sub unixtime
{
    my ($self, $time) = @_;

    return( $time || $self->{ _default_unixtime } || time );
}


=head1 YET ANOTHER STYLE

=cut


# Descriptions: return date as mail_header_style style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_mail_header_style
{
     my ($self, $time) = @_;
     $self->mail_header_style($time);
}


# Descriptions: return date as YYYYMMDD style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_YYYYMMDD
{
     my ($self, $time) = @_;
     $self->YYYYMMDD($time);
}


# Descriptions: return date as YYYYxMMxDD style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_YYYYxMMxDD
{
     my ($self, $time) = @_;
     $self->YYYYxMMxDD($time);
}


# Descriptions: return date as current_time style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_current_time
{
     my ($self, $time) = @_;
     $self->current_time($time);
}


# Descriptions: return date as precise_current_time style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_precise_current_time
{
     my ($self, $time) = @_;
     $self->precise_current_time($time);
}


# Descriptions: return date as stardate style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_stardate
{
     my ($self, $time) = @_;
     $self->stardate($time);
}


# Descriptions: return date as unixtime style.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub as_unixtime
{
     my ($self, $time) = @_;
     $self->unixtime($time);
}


=head1 UTILITIES

=head2 date_to_unixtime($date)

eat date string in several patterns and return the corresponding unix
time.  For example, let C<$date> be

   Mon Jul  2 22:59:45 2001

C<date_to_unixtime($date)> returns

   994082385

You can use like this.

    use Mail::Message::Date;
    $dp = Mail::Message::Date;
    $unixtime = $dp->date_to_unixtime( $date );

=cut


# Descriptions: convert Date: string to UNIXTIME (sec).
#    Arguments: OBJ($self) STR($in)
# Side Effects: none
# Return Value: NUM(unix time)
sub date_to_unixtime
{
    my ($self, $in) = @_;
    my ($day, %month, $month, $year, $hour, $min, $sec, $pm, $zone,
	$shift, $shift_t, $shift_m);

    # cheap sanity, but "return 0" is ok?;)
    return 0 unless defined $in;
    return 0 unless $in;

    # hints
    my $c = 1;
    for my $month ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
		   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec') {
	$month{ $month } = $c++;
    }

    # $in = clean up-ed string. $input = original one.
    my $input = $in;
    $in =~ s/[\s\n]*$//o;
    if ($in =~ /([A-Z]+)\s*$/o) {
	$zone = $1;
	if ($zone{$zone} ne "") {
	    $in =~ s/$zone/$zone{$zone}/;
	}
    }

    # RFC822
    # date        =  1*2DIGIT month 2DIGIT        ; day month year
    #                                             ;  e.g. 20 Jun 82
    # date-time   =  [ day "," ] date time        ; dd mm yy
    #                                             ;  hh:mm:ss zzz
    # hour        =  2DIGIT ":" 2DIGIT [":" 2DIGIT]
    # time        =  hour zone                    ; ANSI and Military
    #
    # RFC1123
    # date = 1*2DIGIT month 2*4DIGIT
    #
    #
    #
    if ($in =~
	/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+([\+\-])(\d\d)(\d\d)/) {
	if ($debug_mti) { print STDERR "Date2UnixTime: Standard\n";}
	$day     = $1;
	$month   = ($month{$2} || $month) - 1;
	$year    = $3 > 1900 ? $3 - 1900 : $3;
	$hour    = $4;
	$min     = $5;
	$sec     = $6;

	# time zone
	$pm      = $7;
	$shift_t = $8;
	$shift_m = $9;
    }
    elsif ($in =~
	/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)\s+([\+\-])(\d\d)(\d\d)/) {
	if ($debug_mti) {
	    print STDERR "Date2UnixTime: Standard without \$sec\n";
	}

	$day     = $1;
	$month   = ($month{$2} || $month) - 1;
	$year    = $3 > 1900 ? $3 - 1900 : $3;
	$hour    = $4;
	$min     = $5;
	$sec     = 0;

	# time zone
	$pm      = $6;
	$shift_t = $7;
	$shift_m = $8;
    }
    # INVALID BUT MANY Only in Japan ??? e.g. "Apr 1 04:01:00 1999"
    # no timezone case ... WHAT SHOULD WE DO ? ;_;
    elsif ($in =~ /([A-Za-z]+)\s+(\d{1,2})\s+(\d+):(\d+):(\d+)\s+(\d{4})\s*/) {
	if ($debug_mti) { print STDERR "Date2UnixTime: Japan specific?\n";}
	$month   = ($month{$1} || $month) - 1;
	$day     = $2;
	$hour    = $3;
	$min     = $4;
	$sec     = $5;
	$year    = $6 > 1900 ? $6 - 1900 : $6;

	# time zone
	$pm      = '+';
	$shift_t = '09';
	$shift_m = '00';
    }
    elsif ($in =~ /\;\s*(\d{9,})\s*$/) {
	if ($debug_mti) { print STDERR "Date2UnixTime: unixtime case\n";}
	if (abs($1 - time) < 7*24*3600) {
	    return $1;
	}
	elsif ($debug_mti) {
	    my ($package,$filename,$line) = caller;
	    _log("date_to_unixtime: invalid [$input]");
	    _log("date_to_unixtime: callded from \@caller");
	}
    }
    else {
	if ($debug_mti) {
	    my ($package,$filename,$line) = caller;
	    _log("date_to_unixtime: invalid [$input]");
	    _log("date_to_unixtime: callded from \@caller");
	}
	return 0;
    }

    # calculate shift between local time and UTC
    $shift_t =~ s/^0*//o;
    $shift_m =~ s/^0*//o;
    $shift_t = 0 unless $shift_t;
    $shift_m = 0 unless $shift_m;
    $shift   = $shift_t + ($shift_m/60);
    $shift   = ($pm eq '+' ? -1 : +1) * $shift;

    # conversion to gmtime (UTC)
    # require 'timelocal.pl'; # which will be removed from perl 5.16 release.
    use Time::Local;

    if ($debug_mti) {
	print STDERR
	    "timegm($sec,$min,$hour,$day,$month,$year) + $shift*3600')\n";
    }

    my $t;
    eval('$t = timegm($sec,$min,$hour,$day,$month,$year) + $shift*3600');
    _log($@) if $@;

    return $t;
}


# Descriptions: speculate timezone and return the string e.g. +0900.
#    Arguments: NUM($_offset)
# Side Effects: none
# Return Value: STR
sub _speculate_timezone
{
    my ($_offset) = @_;

    use Time::Timezone;
    my $offset = $_offset || tz_local_offset();
    my $hour   = int(abs($offset)/3600);
    my $shift  = (abs($offset) - $hour*3600)/3600;

    if ($offset > 0) {
	return sprintf("+%02d%02d", $hour, $shift*60);
    }
    elsif ($offset < 0) {
	return sprintf("-%02d%02d", $hour, $shift*60);
    }
    else {
	return '+0000';
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    print "// 1. time zone.\n";
    print "default\ttimezone = ", _speculate_timezone(), "\n";
    for my $t (qw(-5400 1800 3600 5400 7200)) {
	print "$t\ttimezone = ",  _speculate_timezone($t), "\n";
    }
    print "\n";

    print "// 2. date -> unixtime -> date\n";
    my $dstr = 'Tue, 03 Feb 2004 10:33:24 +0900';
    my $date = new Mail::Message::Date;

    print "//    \$date->set(\"$dstr\"); \$date->unixtime(); ... \n";
    print $dstr, "\n";
    $date->set($dstr);
    my $time = $date->unixtime();

    # require 'ctime.pl'; # will be removed from Perl 5.16.
    use Time::localtime;

    my $ctime = ctime($time); chomp $ctime;
    printf "unixtime=%s\n", $time;
    printf "   ctime=%s\n", $ctime;
    printf " precise=%s\n", $date->precise_current_time();
    print "\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi
Copyright (C) 2009,2010,2012 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Date first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<date_to_unixtime> is imported from fml 4.0-current libmti.pl.

=cut


1;
