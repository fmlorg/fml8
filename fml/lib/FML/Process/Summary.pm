#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Summary.pm,v 1.5 2002/09/22 14:56:51 fukachan Exp $
#

package FML::Process::Summary;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Summary -- maintenance article summary

=head1 SYNOPSIS

    use FML::Process::Summary;
    $curproc = new FML::Process::Summary;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Summary provides the main function for C<fmlsummary>.

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

    my $eval = $config->get_hook( 'fmlsummary_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    $eval = $config->get_hook( 'fmlsummary_prepare_end_hook' );
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

    my $eval = $config->get_hook( 'fmlsummary_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if (0) {
	print STDERR "Error: missing argument(s)\n";
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'fmlsummary_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

the top level dispatcher for C<fmlconf> and C<fmlsummary>.

It kicks off internal function
C<_fmlconf($args)> for C<fmlconf>
    and
C<_fmlsummary($args)> for fmlsummary.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _fmlsummary().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;

    $curproc->_fmlsummary($args);
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'fmlsummary_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'fmlsummary_finish_end_hook' );
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


=head2 C<_fmlsummary($args)> (INTERNAL USE)

switch of C<fmlsummary> command.
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


# Descriptions: fmlsummary top level dispacher
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _fmlsummary
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    my $eval = $config->get_hook( 'fmlsummary_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    use FML::Article::Summary;
    my $summary = new FML::Article::Summary $curproc;

    my ($method, $argv_ml_name, @options) =  @$argv;

    if ($method eq 'update') {
	$curproc->_update($summary);
    }
    elsif ($method eq 'rebuild') {
	$curproc->_update($summary);
    }
    else {
	LogError("unknown method=$method");
	print STDERR "Error: unknown method=$method\n";
    }

    $eval = $config->get_hook( 'fmlsummary_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Summary first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
