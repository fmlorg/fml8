#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: ConfViewer.pm,v 1.11 2002/04/07 05:08:24 fukachan Exp $
#

package FML::Process::ConfViewer;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Log qw(Log LogWarn LogError);
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::ConfViewer -- show variables

=head1 SYNOPSIS

    use FML::Process::ConfViewer;
    $curproc = new FML::Process::ConfViewer;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::ConfViewer provides the main function for C<fmlconf>.

=head1 METHODS

=head2 C<new($args)>

ordinary constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 C<prepare($args)>

dummy.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: FML::Process::ConfViewer object
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlconf_prepare_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );

    $eval = $config->get_hook( 'fmlconf_prepare_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


# Descriptions: check @ARGV, call help() if needed
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv = $curproc->command_line_argv();
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlconf_verify_request_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    if (length(@$argv) == 0) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlconf_verify_request_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 C<run($args)>

the top level dispatcher for C<fmlconf> and C<makefml>.

It kicks off internal function C<_fmlconf($args)> for C<fmlconf>.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmlconf()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    my $eval = $config->get_hook( 'fmlconf_run_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $curproc->_fmlconf($args);

    $eval = $config->get_hook( 'fmlconf_run_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 help()

show help.

=cut


# Descriptions: show help
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub help
{
    my ($curproc, $args) = @_;
    my $name = $curproc->myname();

print <<"_EOF_";

Usage: $name [-n] \$ml_name

          show all configuration variables

-n        show only difference from default

_EOF_
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlconf_finish_start_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }

    $eval = $config->get_hook( 'fmlconf_finish_end_hook' );
    if ($eval) {
	eval qq{ $eval; };
	print STDERR $@ if $@;
    }
}


=head2 C<_fmlconf($args)> (INTERNAL USE)

run dump_variables of C<FML::Config>.

=cut


# Descriptions: show configurations variables in the sytle "key = value".
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _fmlconf
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $mode   = $args->{ options }->{ n } ? 'difference_only' : 'all';

    $config->dump_variables({ mode => $mode });
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::ConfViewer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
