#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#
# $FML: Date.pm,v 1.15 2002/12/22 03:09:56 fukachan Exp $
#

package Mail::Message::Date;

=head1 NAME

Mail::Message::Date - utilities for date and time

=head1 SYNOPSIS

   use Mail::Message::Date;
   $date = new Mail::Message::Date time;

   # get the date in $style format
   $date->{ log_file_style }
   $date->log_file_style

=head1 DESCRIPTION

The style you use follows:

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

=head2 C<log_file_style()>

=head2 C<mail_header_style()>

=head2 C<YYYYMMDD()>

=head2 C<current_time()>

=head2 C<precise_current_time()>

=head2 C<stardate()>

return STAR TREK stardate :-)

=cut


use vars qw($TimeZone);
use strict;
use Carp;


# Descriptions: constructor.
#    Arguments: OBJ($self) NUM($time)
# Side Effects: create date object by _date()
# Return Value: OBJ
sub new
{
    my ($self, $time) = @_;
    my $type = _date($time);
    return bless $type, $self;
}


# Descriptions: prepare date by several time format
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

    # XXX-TODO: default timezone is +0900. o.k. ? :-)
    $TimeZone ||= '+0900';
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


# Descriptions: return logfile style
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub log_file_style
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    return $p->{'log_file_style'};
}


# Descriptions: return Date: style date
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub mail_header_style
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    return $p->{'mail_header_style'};
}


# Descriptions: return YYYYMMDD style date
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub YYYYMMDD
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    return $p->{'YYYYMMDD'};
}


# Descriptions: return e.g. 1999/09/13 style
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub YYYYxMMxDD
{
    my ($self, $time, $sep) = @_;
    my $date = _date($time || time);

    $sep ||= '/'; # 1999/09/13 by default
    return $date->{ YYYY }. $sep . $date->{ MM }. $sep. $date->{ DD };
}


# Descriptions: return YYYYMMDD.HHMM
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    return  $p->{'current_time'};
}


# Descriptions: return YYYYMMDD.HHMMSS
#    Arguments: OBJ($self) NUM($time)
# Side Effects: none
# Return Value: STR
sub precise_current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    return $p->{'precise_current_time'};
}


# Descriptions: return Star Trek stardate()
#                  stardate(tm, issue, integer, fraction)
#                           unsigned long tm;
#                           long *issue, *integer, *fraction;
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR(stardate)
sub stardate
{
    my ($self, $args) = @_;
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


=head2 C<date_to_unixtime($date)>

eat patter in Date: and return the corresponding unix time.
For example, let C<$date> be

   Mon Jul  2 22:59:45 2001

C<date_to_unixtime($date)> returns

   994082385

You can use like this.

    use Mail::Message::Date;
    $unixtime = Mail::Message::Date::date_to_unixtime( $date );

=cut

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


# Descriptions: dummy log function
#    Arguments: STR($s)
# Side Effects: none
# Return Value: none
sub _log
{
    my ($s) = @_;
    print STDERR $s, "\n" if defined $s;
}


# Descriptions: convert Date: string to UNIXTIME (sec)
#    Arguments: STR($in)
# Side Effects: none
# Return Value: NUM(unix time)
sub date_to_unixtime
{
    my ($in) = @_;
    my ($input) = $in;
    my ($day, $month, $year, $hour, $min, $sec, $pm);
    my ($shift, $shift_t, $shift_m);
    my (%month);
    my ($zone);

    # XXX-TODO: method-ify date_to_unixtime() ?
    # XXX-TODO: more documents

    $in =~ s/[\s\n]*$//;

    require 'timelocal.pl';

    # hints
    my $c = 1;
    for ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
	 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec') {
	$month{ $_ } = $c++;
    }

    if ($in =~ /([A-Z]+)\s*$/) {
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
	$day   = $1;
	$month = ($month{$2} || $month) - 1;
	$year  = $3 > 1900 ? $3 - 1900 : $3;
	$hour  = $4;
	$min   = $5;
	$sec   = $6;

	# time zone
	$pm    = $7;
	$shift_t = $8;
	$shift_m = $9;
    }
    elsif ($in =~
	/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)\s+([\+\-])(\d\d)(\d\d)/) {
	if ($debug_mti) {
	    print STDERR "Date2UnixTime: Standard without \$sec\n";
	}

	$day   = $1;
	$month = ($month{$2} || $month) - 1;
	$year  = $3 > 1900 ? $3 - 1900 : $3;
	$hour  = $4;
	$min   = $5;
	$sec   = 0;

	# time zone
	$pm    = $6;
	$shift_t = $7;
	$shift_m = $8;
    }
    # INVALID BUT MANY Only in Japan ??? e.g. "Apr 1 04:01:00 1999"
    # no timezone case ... WHAT SHOULD WE DO ? ;_;
    elsif ($in =~ /([A-Za-z]+)\s+(\d{1,2})\s+(\d+):(\d+):(\d+)\s+(\d{4})\s*/) {
	if ($debug_mti) { print STDERR "Date2UnixTime: Japan specific?\n";}
	$month = ($month{$1} || $month) - 1;
	$day   = $2;
	$hour  = $3;
	$min   = $4;
	$sec   = $5;
	$year  = $6 > 1900 ? $6 - 1900 : $6;

	# time zone
	$pm    = '+';
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

    # get gmtime
    $shift_t =~ s/^0*//;
    $shift_m =~ s/^0*//;
    $shift_m = 0 unless $shift_m;

    $shift = $shift_t + ($shift_m/60);
    $shift = ($pm eq '+' ? -1 : +1) * $shift;

    if ($debug_mti) {
	print STDERR
	    "timegm($sec,$min,$hour,$day,$month,$year) + $shift*3600')\n";
    }

    my $t;
    eval('$t = &timegm($sec,$min,$hour,$day,$month,$year) + $shift*3600');
    _log($@) if $@;

    return $t;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Date first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<date_to_unixtime> is imported from fml 4.0-current libmti.pl.

=cut


1;
