#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Calender.pm,v 1.12 2001/12/23 11:39:45 fukachan Exp $
#

package FML::Process::Calender;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

=head1 NAME

FML::Process::Calender -- demonstration of FML module usage

=head1 SYNOPSIS

    use FML::Process::Calender;
    $curproc = new FML::Process::Calender;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Calender is demonstration module to show fml module
usage.
This module provides calender presentation for simple scheduler,
Calender::Lite calss.

=head1 METHODS

=head2 C<new($args)>

standard constructor.

=head2 C<prepare($args)>

dummy.

=cut


# Descriptions: dummy
#               avoid default fml new() since we do not need it.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare        { 1; }
sub verify_request { 1; }
sub finish         { 1; }


# Descriptions: prepare parameters and call Calender::Lite module.
#               we use w3m to show calender (HTML table).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create temporary file and remove it in the last
# Return Value: none
sub run
{
    my ($self, $args) = @_;
    my $argv   = $args->{ argv };
    my $option = $args->{ options };
    my $mode   = 'text';

    # -h or --help
    if (defined $option->{ h } || defined $option->{ help }) {
	return $self->help();
    }

    use FileHandle;
    use Calender::Lite;

    # prepare new() argument
    $mode             = $option->{ m } if defined $option->{ m };
    my $schedule_dir  = $option->{ D } if defined $option->{ D };
    my $schedule_file = $option->{ F } if defined $option->{ F };
    my $schargs  = {
	schedule_dir  => $schedule_dir,
	schedule_file => undef,
    };
    my $schedule = new Calender::Lite $schargs;

    # prepare output channel
    my $tmpf     = $schedule->tmpfile;
    my $wh       = new FileHandle $tmpf, "w";

    # set output mode
    $schedule->set_mode( $mode );

    # -a option: show three calender for this, next and last month.
    if (defined($option->{ a })) {
	for my $month ('this', 'next', 'last') {
	    $schedule->print_specific_month($wh, $month);
	}
    }
    elsif (defined(@$argv) && @$argv) {
	# ($month, $yeer) = @$argv;
	$schedule->print_specific_month($wh, @$argv);
    }
    else {
	$schedule->print_specific_month($wh, 'this');
    }

    $wh->close;

    if ($mode eq 'text') {
	system "w3m -dump $tmpf";
    }
    else {
	system "cat $tmpf";
    }

    unlink $tmpf if -f $tmpf;
}



# Descriptions: show help
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub help
{
    my ($self) = @_;

    my $name = $0;
    eval q{ use File::Basename;
	    $name = basename($0);
	    if ($name =~ /(\w+)$/) { $name = $1;}
	};

print <<"_EOF_";

Usage: $name [-a] [-m mode] [month] [year]

           show this month if not specified.

-h         show this help
-a         show calender at this, next and last month
-m mode    mode is 'text' or 'html'
-D DIR     alternative of ~/.schedule/
-F FILE    specify schedule file to read

--debug    debug mode on

_EOF_
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Calender appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
