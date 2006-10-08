#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Project.pm,v 1.3 2006/09/24 10:24:20 fukachan Exp $
#

package FML::Demo::Project;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $global_language = "Japanese";


=head1 NAME

FML::Demo::Project - generate pseudo Gantt chart (demonstration module).

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constuctor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: parse file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: save data at $self->{ _data }.
# Return Value: none
sub parse
{
    my ($self, $file) = @_;
    my ($data) = [];

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my ($buf, $line, $level, $date_list, $status, $comment);

      LINE:
	while ($buf = <$rh>) {
	    next if $buf =~ /^\#/o;

	    $level     = 0;
	    $date_list = [];
	    $status    = '';
	    $comment   = '';

	    if ($buf =~ /^\%format/) {
		$self->_parse_format($buf);
		next LINE;
	    }
	    if ($buf =~ /^\%alias/)  {
		$self->_parse_alias($buf);
		next LINE;
	    }
	    if ($buf =~ /^\%date_range/) {
		$self->_parse_date_range($buf);
		next LINE;
	    }
	    if ($buf =~ /^\S+/)      { $level = 1;}
	    if ($buf =~ /^\t{1}\S+/) { $level = 2;}
	    if ($buf =~ /^\t{2}\S+/) { $level = 3;}
	    if ($buf =~ /^\t{3}\S+/) { $level = 4;}

	    $line++;
	    $data->[ $line ] = {};

	    $buf =~ s/^\s*//;
	    my ($title, @_data) = split(/\s+/, $buf);
	  DATA:
	    for my $s (@_data) {
		if ($s =~ /^[-\d+\/]+$/) {
		    $date_list = $self->_get_canonical_date_list($s);
		    next DATA;
		}
		elsif ($s =~ /^DONE|WAIT$/) {
		    $status = $s;
		    next DATA;
		}
		else {
		    $comment .= $s;
		}
	    }

	    $data->[ $line ]->{ level     } = $level;
	    $data->[ $line ]->{ title     } = $title;
	    $data->[ $line ]->{ date_list } = $date_list;
	    $data->[ $line ]->{ status    } = $status;
	    $data->[ $line ]->{ comment   } = $comment;
	}
	$rh->close();
    }

    $self->{ _data } = $data;
    return $data;
}


# Descriptions: parse the given string and return the date list as ARRAY_REF.
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_canonical_date_list
{
    my ($self, $s) = @_;

    if ($s =~ /^([\/\d]+)-([\/\d]+)$/) {
	my $first = $self->_canonical_date($1);
	my $last  = $self->_canonical_date($2);
	return $self->_expand_date_list( $first, $last );
    }
    else {
	my $d = $self->_canonical_date($s);
	return [ $d ];
    }
}


# Descriptions: return date list from $first to $last.
#    Arguments: OBJ($self) STR($first) STR($last)
# Side Effects: none
# Return Value: ARRAY_REF
sub _expand_date_list
{
    my ($self, $first, $last) = @_;
    my $r = [];

    use Time::ParseDate;
    my $first_sec = parsedate($first);
    my $last_sec  = parsedate($last);

    for (my $sec = $first_sec; $sec <= $last_sec; $sec += 86400) {
	use Mail::Message::Date;
	my $date = new Mail::Message::Date $sec;
	my $yyyy = $date->YYYYxMMxDD($sec);
	push(@$r, $yyyy);
    }

    return $r;
}


# Descriptions: return canonicalized date string.
#    Arguments: OBJ($self) STR($date)
# Side Effects: none
# Return Value: STR
sub _canonical_date
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

    return sprintf("%04d/%02d/%02d", $year, $month, $day);
}


# Descriptions: parse %format line and build in-object data.
#    Arguments: OBJ($self) STR($format)
# Side Effects: update $self->{ _format } field.
# Return Value: none
sub _parse_format
{
    my ($self, $format) = @_;

    $format =~ s/^\%format\s+//;
    my (@format) = split(/\s+/, $format);

    $self->{ _format } = \@format || [];
}


# Descriptions: parse %alias line and build in-object data.
#    Arguments: OBJ($self) STR($alias)
# Side Effects: update $self->{ _alias } field.
# Return Value: none
sub _parse_alias
{
    my ($self, $alias) = @_;

    $alias =~ s/^\%alias\s+//;
    my ($src, $dst) = split(/\s+/, $alias);
    $self->{ _alias }->{ $src } = $dst;
}


# Descriptions: parse %date_range line and build in-object data.
#    Arguments: OBJ($self) STR($date)
# Side Effects: update $self->{ _alias } field.
# Return Value: none
sub _parse_date_range
{
    my ($self, $date) = @_;

    $date =~ s/^\%date_range\s+//;
    my ($d0, $d1) = split(/\s+/, $date);
    $self->{ _date_range } = [ $d0, $d1 ];
}


# Descriptions: build data object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub build
{
    my ($self)   = @_;
    my ($data)   = $self->{ _data };
    my ($format) = $self->{ _format } || [];
    my ($alias)  = $self->{ _alias }  || {};
    my ($line)   = 0;
    my ($_data);

    # $data->[ $line ]->{ level   } = $level;
    # $data->[ $line ]->{ title   } = $title;
    # $data->[ $line ]->{ date    } = $date;
    # $data->[ $line ]->{ comment } = $comment;

    use FML::Demo::Chart;
    my $chart = new FML::Demo::Chart;
    my $max_line = $#$data;
  LINE:
    for (my $line = 1; $line < $max_line; $line++) {
	my $level     = $data->[ $line ]->{ level }     || 1;
	my $title     = $data->[ $line ]->{ title }     || '';
	my $date_list = $data->[ $line ]->{ date_list } || [];
	my $status    = $data->[ $line ]->{ status }    || '';
	my $comment   = $data->[ $line ]->{ comment }   || '';

	if ($level == 1) {
	    $chart->add($line, "item1",  $title);
	}
	elsif ($level == 2) {
	    $chart->add($line, "item2",  $title);
	}
	else {
	    $chart->add($line, "item1",  "");
	}

	if (@$date_list) {
	    my $mark = $self->get_mark_nl();
	    for my $day (@$date_list) {
		$chart->add($line, $day, $mark);
	    }
	}

	if ($status) {
	    $chart->add($line, "status", $status);
	}

	if ($comment) {
	    $chart->add($line, "misc", $comment);
	}
    }

    $chart->set_format($format);
    $chart->set_alias($alias);
    my $range = $self->{ _date_range };
    $chart->set_date_range(@$range);
    $self->{ _chart } = $chart;
}


# Descriptions: print as HTML TABLE format.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print_as_html_table
{
    my ($self) = @_;
    my $chart  = $self->{ _chart };
    $chart->print_as_html_table();
}


# Descriptions: print as CSV format.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print_as_csv
{
    my ($self) = @_;
    my $chart  = $self->{ _chart };
    $chart->print_as_csv();
}


=head1 Japanese Specific Methods

=head2 get_mark_nl()

=cut


# Descriptions: return mark.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_mark_nl
{
    my ($self)     = @_;
    my $base_class = "FML::Demo::Language";
    my $module     = sprintf("%s::%s", $base_class, $global_language);
    my $mark       = 'O';
    eval qq{
	use $module;
	my \$lang = new $module;
	\$mark = \$lang->get_mark();
    };
    croak($@) if $@;

    return( $mark || 'O' );
}


if ($0 eq __FILE__) {
    my $file = shift @ARGV;
    my $proj = new FML::Demo::Project;
    $proj->parse($file);
    $proj->build();
    $proj->print_as_csv();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Demo::Project appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
