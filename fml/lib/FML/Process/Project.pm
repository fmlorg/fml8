#-*- perl -*-
#
# Copyright (C) 2006 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Project.pm,v 1.1 2006/02/01 12:35:45 fukachan Exp $
#

package FML::Process::Project;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

=head1 NAME

FML::Process::Project -- demonstration of FML module usage.

=head1 SYNOPSIS

    use FML::Process::Project;
    $curproc = new FML::Process::Project;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Project is a demonstration module to show fml module
usage.  This module provides Project presentation as a simple
scheduler based on FML::Demo::Project class.

=head1 METHODS

=head2 new($args)

constructor.

=head2 prepare($args)

load default configuration file to use $path_* variables.

=head2 verify_request($args)

dummy.

=head2 run($args)

main routine.

parse the specified file and print it out by CSV or HTML TABLE format.
You can specify the format by --csv or --html command line option.
CSV by default.

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

    # load default configurations.
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


# Descriptions: prepare parameters and call FML::Demo::Project module.
#               we use w3m to show Project (HTML table).
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

    use FML::Demo::Chart;
    use FML::Demo::Project;
    my $file = $argv->[0];
    my $proj = new FML::Demo::Project;
    $proj->parse($file);
    $proj->build();

    if (defined $option->{ html }) {
	$proj->print_as_html_table();
    }
    elsif (defined $option->{ csv }) {
	$proj->print_as_csv();
    }
    else {
	$proj->print_as_csv();
    }
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

Usage: $name [--debug] [--html] [--csv]

--debug    debug mode on

_EOF_
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

FML::Process::Project first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

C<FML::Process::Scheduler> is renamed to C<FML::Process::Project>.

=cut


1;
