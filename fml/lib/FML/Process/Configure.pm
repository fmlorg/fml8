#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Configure.pm,v 1.39 2002/04/20 05:40:02 fukachan Exp $
#

package FML::Process::Configure;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Configure -- makefml main functions

=head1 SYNOPSIS

    use FML::Process::Configure;
    $curproc = new FML::Process::Configure;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Configure provides the main function for C<makefml>.

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

    my $eval = $config->get_hook( 'makefml_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'makefml_prepare_end_hook' );
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

    my $eval = $config->get_hook( 'makefml_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    if ($len <= 1) {
	$curproc->help();
	exit(0);
    }

    $eval = $config->get_hook( 'makefml_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

the top level dispatcher for C<fmlconf> and C<makefml>.

It kicks off internal function
C<_fmlconf($args)> for C<fmlconf>
    and
C<_makefml($args)> for makefml.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _makefml().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    $curproc->_makefml($args);
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'makefml_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $eval = $config->get_hook( 'makefml_finish_end_hook' );
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

$name subscribe    \$ml_name ADDRESS
$name unsubscribe  \$ml_name ADDRESS

_EOF_
}


=head2 C<_makefml($args)> (INTERNAL USE)

switch of C<makefml> command.
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


# Descriptions: makefml top level dispacher
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _makefml
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();

    my ($method, $ml_name, @options) =  @$argv;

    # arguments to pass off to each method
    my $command_args = {
	command_mode => 'admin',
	comname      => $method,
	command      => "$method @options",
	ml_name      => $ml_name,
	options      => \@options,
	argv         => $argv,
	args         => $args,
    };

    # update $config to rewrite $ml_* variable for the virtual domain.
    # XXX irrespctive of virtual domains or not, we call this method
    # XXX to update $config->{ ml_name } et. al.
    # XXX since $config->{ ml_name } is not set here.
    $curproc->rewrite_config_if_needed($args, $command_args);
    $command_args->{ ml_name } = $config->{ ml_name };

    my $eval = $config->get_hook( 'makefml_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # here we go
    require FML::Command;
    my $obj = new FML::Command;

    if (defined $obj) {
	# execute command ($comname method) under eval().
	eval q{
	    $obj->$method($curproc, $command_args);
	};
	unless ($@) {
	    ; # not show anything
	}
	else {
	    my $r = $@;
	    LogError("command $method fail");
	    LogError($r);
	    if ($r =~ /^(.*)\s+at\s+/) {
		my $reason = $1;
		Log($reason); # pick up reason
		croak($reason);
	    }
	}
    }

    $eval = $config->get_hook( 'makefml_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
