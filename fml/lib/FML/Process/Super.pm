#-*- perl -*-
#
# Copyright (C) 2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Super.pm,v 1.3 2003/01/25 12:11:20 fukachan Exp $
#

package FML::Process::Super;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

my $debug = 0;


=head1 NAME

FML::Process::Super -- small maintenance jobs on the queue spool

=head1 SYNOPSIS

=head1 DESCRIPTION

This class drives provides utility funtions for the ML queue.

=head1 METHODS

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare($args)>

ajdust ml_* variables, load config files and fix @INC.

=head2 C<verify_request($args)>

show help.

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: inherit FML::Process::Kernel
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: fix ml_*, load config and fix @INC.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: fix @INC
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlsuper_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmlsuper_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv   = $curproc->command_line_argv();
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlsuper_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if (length(@$argv) == 0 || (not $argv->[0])) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlsuper_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

small jobs on the queue maintenance.

=cut

#
# XXX-TODO: clean up run() more.
#


# Descriptions: convert text format article to HTML by Mail::Message::ToHTML
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load modules, create HTML files and directories
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $options = $curproc->command_line_options();

    my $eval = $config->get_hook( 'fmlsuper_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # if -p specified, run _purge();
    # if not, run _check();
    $curproc->_queue($args);

    $eval = $config->get_hook( 'fmlsuper_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: show help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    use File::Basename;
    my $name = basename($0);

print <<"_EOF_";

Usage: $name [-p] ML

options:

-p          purge stale files.

ML          ml_name. Example: elena, rudo\@nuinui.net

_EOF_
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlsuper_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlsuper_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: dummy to avoid to take data from STDIN
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


# Descriptions: open mail queue and list up.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _queue
{
    my ($curproc, $args) = @_;
    my $config    = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    my $ra    = $queue->list();

    for my $qid (@$ra) {
	print $qid, "\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Super first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
