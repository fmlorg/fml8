#-*- perl -*-
#
# Copyright (C) 2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Calender.pm,v 1.4 2002/04/07 05:04:38 fukachan Exp $
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

FML::Process::Calender is a demonstration module to show fml module
usage.  This module provides calender presentation for a simple
scheduler, Calender::Lite class.

=head1 METHODS

=head2 C<new($args)>

standard constructor.

=head2 C<prepare($args)>

dummy.

=cut


# Descriptions: dummy constructor.
#               avoid the default fml new() since we do not need it.
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
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare        { 1; }

# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request { 1; }

# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish         { 1; }


# Descriptions: prepare parameters and call Calender::Lite module.
#               we use w3m to show calender (HTML table).
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: create temporary file and remove it in the last
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $argv   = $args->{ argv };
    my $option = $args->{ options };
    my $mode   = 'text';

    # -h or --help
    if (defined $option->{ h } || defined $option->{ help }) {
	return $curproc->help();
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
    my $tmpf     = $schedule->tmpfilepath;
    my $wh       = new FileHandle $tmpf, "w";

    # set output mode
    $schedule->set_mode( $mode );

    # -a option: show three calender for this, next and last month.
    if (defined($option->{ a })) {
	for my $month ('this', 'next', 'last') {
	    $schedule->print_specific_month($wh, $month);
	}
    }
    # if "month" to show is specified as arguments,
    # show the corresponding calender.
    elsif (defined(@$argv) && @$argv) {
	# ($month, $yeer) = @$argv;
	$schedule->print_specific_month($wh, @$argv);
    }
    # show this month calender by default.
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
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub help
{
    my ($curproc) = @_;

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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Calender appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<FML::Process::Scheduler> is renamed to C<FML::Process::Calender>.

=cut


1;
