#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Alias.pm,v 1.4 2002/09/11 23:18:13 fukachan Exp $
#

package FML::Process::Alias;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Alias -- fmlalias main functions

=head1 SYNOPSIS

    use FML::Process::Alias;
    $curproc = new FML::Process::Alias;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Alias provides the main function for C<fmlalias>.

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 C<new($args)>

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 C<prepare($args)>

dummy.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlalias_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmlalias_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: check @ARGV, call help() if needed.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv = $curproc->command_line_argv();
    my $len  = $#$argv + 1;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlalias_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if (0) {
	print STDERR "Error: missing argument(s)\n";
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlalias_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

the top level dispatcher for C<fmlconf> and C<fmlalias>.

It kicks off internal function
C<_fmlconf($args)> for C<fmlconf>
    and
C<_fmlalias($args)> for fmlalias.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmlalias().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    $curproc->_fmlalias($args);
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlalias_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlalias_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    my $name = $0;
    eval {
	use File::Basename;
	$name = basename($0);
    };

print <<"_EOF_";

Usage: $name \$command \$ml_name [options]

$name help         \$ml_name                   show this help

$name list

_EOF_
}


=head2 C<_fmlalias($args)> (INTERNAL USE)

switch of C<fmlalias> command.
It kicks off <FML::Command::$command> corrsponding with
C<@$argv> ( $argv = $args->{ ARGV } ).

C<Caution:>
C<$args> is passed from parrent libexec/loader.
We construct a new struct C<$command_args> here to pass parameters
to child objects.
C<FML::Command::$command> object takes them as arguments not pure
C<$args>. It is a little mess. Pay attention.

See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: fmlalias top level dispacher
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _fmlalias
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    my ($method, $ml_name, @options) =  @$argv;

    my $eval = $config->get_hook( 'fmlalias_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # -n
    my $mode = $args->{ options }->{ n } ? 'fmlonly' : 'all';

    use FML::MTAControl;
    my $mta     = new FML::MTAControl;
    my $aliases = $mta->get_aliases_as_hash_ref($curproc, {}, {
        mta_type => 'postfix',
	mode     => $mode,
    });

    for my $k (sort keys %$aliases) {
        printf "%-25s => %s\n", $k, $aliases->{ $k };
    }

    $eval = $config->get_hook( 'fmlalias_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Alias first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
