#-*- perl -*-
#
# Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Calendar.pm,v 1.19 2006/10/11 14:54:49 fukachan Exp $
#

package FML::Process::Calendar;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

=head1 NAME

FML::Process::Calendar -- show calendear (as a demonstration).

=head1 SYNOPSIS

    use FML::Process::Calendar;
    $curproc = new FML::Process::Calendar;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Calendar is a demonstration module to show fml module
usage.  This module provides calendar presentation as a simple
scheduler based on FML::Demo::Calendar class.

=head1 METHODS

=head2 new($args)

constructor.

=head2 prepare($args)

load default configuration file to use $path_* variables.

=head2 verify_request($args)

dummy.

=head2 run($args)

main routine.

parse files under ~$user/.schedule/ directory and summarize it.

Lastly, use w3m to show schedule as html table.

=head2 finish($args)

dummy.

=cut


# Descriptions: constructor.
#               avoid the default fml new() since we do not need it.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ main_cf }       = $args->{ main_cf };
    $me->{ __parent_args } = $args;

    return bless $me, $type;
}


# Descriptions: load default configurations to use $path_* info.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;

    # load only "default" configurations.
    use FML::Config;
    $curproc->{ config } = new FML::Config;
    $curproc->config_cf_files_load();
}


# Descriptions: dummy.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request { 1; }


# Descriptions: dummy.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish         { 1; }


# Descriptions: prepare parameters and call FML::Demo::Calendar module.
#               we use w3m to show calendar (HTML table).
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: create temporary file and remove it in the last
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $argv   = $curproc->command_line_raw_argv();
    my $option = $curproc->command_line_options();
    my $mode   = 'text';

    # -h or --help
    if (defined $option->{ h } || defined $option->{ help }) {
	return $curproc->help();
    }

    use FileHandle;
    use FML::Demo::Calendar;

    # prepare new() argument
    $mode             = $option->{ m } if defined $option->{ m };
    my $schedule_dir  = $option->{ D } if defined $option->{ D };
    my $schedule_file = $option->{ F } if defined $option->{ F };
    my $schargs       = {
	schedule_dir  => $schedule_dir,
	schedule_file => undef,
    };

    # create a scheduler object.
    my $schedule      = new FML::Demo::Calendar $schargs;

    # prepare output channel
    my $tmpf     = $schedule->tmpfilepath;
    my $wh       = new FileHandle $tmpf, "w";

    unless (defined $wh) {
	my $s = "cannot open temporary file";
	$curproc->logerror($s);
	croak($s);
    }

    # set output mode
    $schedule->set_mode( $mode );

    # -a option: show three monthly calendars for this, next and last month.
    if (defined($option->{ a })) {
	for my $month ('this', 'next', 'last') {
	    $schedule->print_specific_month($wh, $month);
	}
    }
    # if "month" option is specified as an argument,
    # show the corresponding calendar.
    elsif (defined(@$argv) && @$argv) {
	# ($month, $yeer) = @$argv;
	$schedule->print_specific_month($wh, @$argv);
    }
    # show this month calendar by default.
    else {
	$schedule->print_specific_month($wh, 'this');
    }

    $wh->close;

    if ($mode eq 'text') {
	my $w3m = $config->{ path_w3m } || 'w3m';
	if (-x $w3m) {
	    system "$w3m -dump $tmpf";
	}
	else {
	    $curproc->logerror("w3m not found");
	}
    }
    else {
	$curproc->cat( [ $tmpf ] );
    }

    unlink $tmpf if -f $tmpf;
}



# Descriptions: show help.
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
-a         show calendar at this, next and last month
-m mode    mode is 'text' or 'html'
-D DIR     alternative of ~/.schedule/
-F FILE    specify schedule file to read

--debug    debug mode on

_EOF_
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Calendar first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<FML::Process::Scheduler> is renamed to C<FML::Process::Calendar>.

=cut


1;
