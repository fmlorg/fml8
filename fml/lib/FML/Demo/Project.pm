#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Project.pm,v 1.1 2006/02/01 12:35:45 fukachan Exp $
#

package FML::Demo::Project;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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
	my ($buf, $line, $level, $date, $comment);

      LINE:
	while ($buf = <$rh>) {
	    next if $buf =~ /^\#/o;

	    $line++;
	    $data->[ $line ] = {};
	    $level   = 0;
	    $date    = '';
	    $comment = '';

	    if ($buf =~ /^\%format/) { $self->_parse_format($buf); next LINE;}
	    if ($buf =~ /^\%alias/)  { $self->_parse_alias($buf);  next LINE;}
	    if ($buf =~ /^\%date_range/) {
		$self->_parse_date_range($buf);
		next LINE;
	    }
	    if ($buf =~ /^\S+/)      { $level = 1;}
	    if ($buf =~ /^\t{1}\S+/) { $level = 2;}
	    if ($buf =~ /^\t{2}\S+/) { $level = 3;}
	    if ($buf =~ /^\t{3}\S+/) { $level = 4;}

	    $buf =~ s/^\s*//;
	    my ($title, @_data) = split(/\s+/, $buf);
	  DATA:
	    for my $s (@_data) {
		if ($s =~ /\d+\/\d+/ || $s =~ /\d+\/\d+\/\d+/) {
		    $date = $self->_canonical_date($s);
		    next DATA;
		}
		else {
		    $comment .= $s;
		}
	    }

	    $data->[ $line ]->{ level   } = $level;
	    $data->[ $line ]->{ title   } = $title;
	    $data->[ $line ]->{ date    } = $date;
	    $data->[ $line ]->{ comment } = $comment;
	}
	$rh->close();
    }

    $self->{ _data } = $data;
    return $data;
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
    for (my $line = 1; $line < $max_line; $line++) {
	my $level   = $data->[ $line ]->{ level }   || 1;
	my $title   = $data->[ $line ]->{ title }   || '';
	my $date    = $data->[ $line ]->{ date }    || '';
	my $comment = $data->[ $line ]->{ comment } || '';

	if ($level == 1) {
	    $chart->add($line, "item1",  $title);
	}
	elsif ($level == 2) {
	    $chart->add($line, "item2",  $title);
	}
	else {
	    $chart->add($line, "item1",  "");
	}

	if ($date) {
	    $chart->add($line, $date, "O");
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
