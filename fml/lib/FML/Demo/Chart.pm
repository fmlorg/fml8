#-*- perl -*-
#
#  Copyright (C) 2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Chart.pm,v 1.1 2006/02/01 12:35:45 fukachan Exp $
#

package FML::Demo::Chart;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use lib qw(../fml/lib ../../cpan/lib ../../img/lib);
use Time::DaysInMonth;

=head1 NAME

FML::Demo::Chart - handle chart structure (demonstration module).

=head1 SYNOPSIS

=head1 DESCRIPTION

C<CAUTION:> This module is created just for a demonstration to show
how to write a module not intended for your general use. This module
is not enough mature nor secure.

=head2 CHART

The chart, which is a kind of Gantt chart, is based on matrix as
follows:

            1st column  2nd column 3rd column  ...
   row 1st     todo       who        01/01     01/02 ...
   row 2nd       a        rudo         o
   row 3rd       b        kenken                 o
   ...

The x axis is date by default but in almost cases, the x axis must be
a combination of "todo entry", "person", "end of developement", "date"
array.

=head1 METHODS

=head2 new($args)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {
	_data  => {},
    };

    return bless $me, $type;
}


=head1 BASIC OPERATIONS

=head2 add($x, $y, $value)

add $value at the position ($x, $y) where $y is expected to be a date
e.g. 2006/01/01.

=head2 delete($x, $y)

delete value at the position ($x, $y).

=cut


# Descriptions: add $value at the position ($x, $y).
#    Arguments: OBJ($self) STR($x) STR($y) STR($value)
# Side Effects: update hash.
# Return Value: none
sub add
{
    my ($self, $x, $y, $value) = @_;
    my $data = $self->{ _data };
    $data->{ $x }->{ $y } = $value;
}


# Descriptions: delete $value at ($x, $y).
#    Arguments: OBJ($self) STR($x) STR($y)
# Side Effects: update hash.
# Return Value: none
sub delete
{
    my ($self, $x, $y) = @_;
    my $data = $self->{ _data };
    delete $data->{ $x }->{ $y };
}


=head1 DATE RANGE OPERATIONS

=head2 set_date_range($min_date, $max_date)

set range of the date column.

=cut


# Descriptions: set the minimum value of the date column.
#    Arguments: OBJ($self) STR($min) STR($max)
# Side Effects: update $self->{ _min_date }
# Return Value: none
sub set_date_range
{
    my ($self, $min, $max) = @_;
    $self->{ _min_date } = $min;
    $self->{ _max_date } = $max;
}


# Descriptions: set the minimum value of the date column.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _min_date }
# Return Value: ARRAY(STR, STR)
sub get_date_range
{
    my ($self) = @_;
    my $min = $self->{ _min_date } || '01/01';
    my $max = $self->{ _max_date } || '12/31';
    return( $min, $max );
}


# Descriptions: generate an array of date string e.g. YYYY/MM/DD.
#               The range is bounded by $self->{ _min_date } and
#               $self->{ _max_date }.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub _generate_column_list
{
    my ($self)   = @_;
    my ($format) = $self->get_format()  || [];
    my ($alias)  = $self->get_alias()   || {};

    # 1. parse the range.
    my ($min_date, $max_date) = $self->get_date_range();
    my ($min_year, $min_month, $min_day) = $self->_parse_date($min_date);
    my ($max_year, $max_month, $max_day) = $self->_parse_date($max_date);

    # 2. generate date array.
    my (@datelist) = ();
    for my $year ($min_year .. $max_year) {
	for my $month ( 1 .. 12 ) {
	    my $days = days_in($year, $month);
	    for my $day ( 1 .. $days ) {
		if ($self->_is_in_date_range($year, $month, $day,
					     $min_date, $max_date)) {
		    my $entry = sprintf("%04d/%02d/%02d", $year, $month, $day);
		    push(@datelist, $entry);
		}
	    }
	}
    }

    # 3. expaned format.
    my (@result) = ();
    for my $entry (@$format) {
	if ($entry eq 'date') {
	    push(@result, @datelist);
	}
	else {
	    push(@result, $entry);
	}
    }

    return \@result;
}


# Descriptions: check the range by comparing date as number.
#    Arguments: OBJ($self) STR($year) STR($month) STR($day)
#               STR($min_date) STR($max_date)
# Side Effects: none
# Return Value: NUM
sub _is_in_date_range
{
    my ($self, $year, $month, $day, $min_date, $max_date) = @_;
    my ($min_year, $min_month, $min_day) = $self->_parse_date($min_date);
    my ($max_year, $max_month, $max_day) = $self->_parse_date($max_date);
    my $i_min = "$min_year$min_month$min_day";
    my $i_max = "$max_year$max_month$max_day";
    my $i_day = sprintf("%04d%02d%02d", $year, $month, $day);

    if ($i_min <= $i_day && $i_day <= $i_max) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: parse string to (year, month, day) string set.
#    Arguments: OBJ($self) STR($date)
# Side Effects: none
# Return Value: ARRAY(STR, STR, STR)
sub _parse_date
{
    my ($self, $date) = @_;
    my ($year, $month, $day);
    my ($_sec,$_min,$_hour,$_mday,$_mon,$_year,$_wday) = localtime(time);
    $_year += 1900;

    if ($date =~ /^(\d+)\/(\d+)$/) {
	($year, $month, $day) = ($_year, $1, $2);
    }
    elsif ($date =~ /^(\d+)\/(\d+)\/(\d+)$/) {
	($year, $month, $day) = ($1, $2, $3);
    }

    return ($year, $month, $day);
}


# Descriptions: shrink date as could as short to remove
#               duplication along x axis.
#    Arguments: OBJ($self) STR($date)
# Side Effects: update $self->{ _last_date }
# Return Value: STR
sub _shrink_date
{
    my ($self, $date)  = @_;
    my ($last)         = $self->{ _last_date } || '';
    my ($last_slash_p) = 0;
    my ($r) = '';

    for my $p ( 1 .. length($date) ) {
	my $s0 = substr($last, 0, $p);
	my $s1 = substr($date, 0, $p);
	if ($s0 ne $s1) {
	    $r = substr($date, $last_slash_p);
	    last;
	}

	if ($s0 =~ /\/$/) {
	    $last_slash_p = $p;
	}
    }

    $self->{ _last_date } = $date;

    return($r || $date);
}


=head1 PRINTING METHODS

=head2 print_as_html_table()

print as HTML table.

=head2 print_as_Chart()

print as Chart.

=cut


# Descriptions: print as HTML table.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print_as_html_table
{
    my ($self)        = @_;
    my $data          = $self->{ _data };
    my $alias         = $self->get_alias();
    my ($column_list) = $self->_generate_column_list();
    my ($k, $v);

    # label along x-axis.
    print "<TABLE BORDER=4>\n";
    print "<TR>\n";
    print "<TD>\n";
    for my $y (@$column_list) {
	print "<TD>\t";
	if ($alias->{ $y }) {
	    print $alias->{ $y }, "\n";
	}
	else {
	    print $self->_shrink_date($y), "\n";
	}
    }

    # main data.
    for my $x (sort {$a <=> $b} keys %$data) {
	print "<TR>\n";
	print "<TD>\t";
	print $x;
	for my $y (@$column_list) {
	    print "<TD>\t";
	    if (defined $data->{ $x }->{ $y }) {
		print $data->{ $x }->{ $y }, "\n";
	    }
	}
	print "\n";
    }
    print "</TABLE>\n";
}


# Descriptions: print as csv.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print_as_csv
{
    my ($self)        = @_;
    my $data          = $self->{ _data };
    my $alias         = $self->get_alias();
    my ($column_list) = $self->_generate_column_list();
    my ($k, $v);

    # labels at 1st raw.
    my (@r) = ("");
    for my $y (@$column_list) {
	if ($alias->{ $y }) {
	    push(@r, $alias->{ $y });
	}
	else {
	    push(@r, $y);
	}
    }
    print join(",", @r), "\n";

    # main data.
    for my $x (sort keys %$data) {
	for my $y (@$column_list) {
	    if (defined $data->{ $x }->{ $y }) {
		print $data->{ $x }->{ $y };
	    }
	    print ",";
	}
	print "\n";
    }
}


=head1 UTILITY

=head2 set_format($format)

set format where $format is ARRAY_REF.

=head2 get_format

return format ARRAY_REF.

=head2 set_alias($alias)

set alias where $alias is HASH_REF.

=head2 get_alias

return alias HASH_REF.

=cut


# Descriptions: set format.
#    Arguments: OBJ($self) ARRAY_REF($format)
# Side Effects: update $self->{ _format }
# Return Value: none
sub set_format
{
    my ($self, $format) = @_;
    $self->{ _format } = $format;
}


# Descriptions: get format.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_format
{
    my ($self) = @_;
    return( $self->{ _format } || [] );
}


# Descriptions: set alias.
#    Arguments: OBJ($self) HASH_REF($alias)
# Side Effects: update $self->{ _alias }
# Return Value: none
sub set_alias
{
    my ($self, $alias) = @_;
    $self->{ _alias } = $alias;
}


# Descriptions: get alias.
#    Arguments: OBJ($self)
# Side Effects: none.
# Return Value: ARRAY_REF
sub get_alias
{
    my ($self) = @_;
    return( $self->{ _alias } || {} );
}


#
# debug
#
if ($0 eq __FILE__) {
    use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
    my $Chart = new FML::Demo::Chart;
    $Chart->add("rudo",   "2006/01/01", "hatsumoude, runta!");
    $Chart->add("kenken", "2006/01/03", "matoi!");
    $Chart->set_date_range("2005/12/28", "2006/01/05");
    $Chart->set_format(['item1', 'item2',  'date']);
    $Chart->print_as_html_table();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'chi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006 Ken'chi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Demo::Chart first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

Firstly this module name is C<TinyScheduler.pm> and renamed to
Calendar::Lite later. In 2004, it is renamed to FML::Demo::Chart
again since this module must depend FML::* classes.

=cut


1;
