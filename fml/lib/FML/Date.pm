#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $Id$
# $FML$
#

package FML::Date;

=head1 NAME

FML::Date - utilities for date and time 

=head1 SYNOPSIS


   use FML::Date;
   $date = new FML::Date time;

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

=item    log_file_style()

=item    mail_header_style()

=item    YYYYMMDD()

=item    current_time()

=item    precise_current_time()

=item    stardate()

return STAR TREK stardate :-)

=cut


require Exporter;
use vars qw($TimeZone);
@ISA = qw(Exporter);

use strict;
use Carp;


sub new
{
    my ($class, $time) = @_;
    my $type = _date($time);
    return bless $type, $class;
}


sub _date
{
    my ($time) = @_;
    my ($date) = {};

    # use the current UTC if $time is not given.
    $time ||= time;
	
    my @WDay  = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    my @Month = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
		 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

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


sub log_file_style
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    $p->{'log_file_style'};
}


sub mail_header_style
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    $p->{'mail_header_style'};
}


sub YYYYMMDD
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    $p->{'YYYYMMDD'};
}


sub YYYYxMMxDD
{
    my ($self, $time, $sep) = @_;
    my $date = _date($time || time);

    $sep ||= '/'; # 1999/09/13 by default
    $date->{ YYYY }. $sep . $date->{ MM }. $sep. $date->{ DD };
}


sub current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    $p->{'current_time'};
}


sub precise_current_time
{
    my ($self, $time) = @_;
    my $p = _date($time || time);
    $p->{'precise_current_time'};
}

# Descriptions: return Star Trek stardate()
#                  stardate(tm, issue, integer, fraction)
#                           unsigned long tm;
#                           long *issue, *integer, *fraction;
#    Arguments: $self $args
# Side Effects: 
# Return Value: stardate
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

    sprintf("[%d]%04d.%02.2s", $issue, $integer, $fraction);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Date appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
