#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Configure.pm,v 1.31 2001/11/25 05:13:22 fukachan Exp $
#

package FML::Process::Configure;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Configure -- fmlconf and makefml main functions

=head1 SYNOPSIS

    use FML::Process::Configure;
    $curproc = new FML::Process::Configure;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Configure provides the main function for 
C<fmlconf>
 and 
C<makefml>.

These programs, 
C<fmlconf> and C<makefml>,
bootstrap by using these modules in this order.

   libexec/loader -> FML::Process::Switch -> FML::Process::Configure

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 C<new($args)>

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 C<prepare($args)>

dummy.

=cut


# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: none
# Return Value: FML::Process::Configure object
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy yet now
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub prepare { ; }


# Descriptions: check @ARGV
#    Arguments: $self $args
# Side Effects: longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $argv = $curproc->command_line_argv();

    if (length(@$argv) <= 1) {
	$curproc->help();
	exit(0);
    }
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

# Descriptions: just a switch
#    Arguments: $self $args
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


=head2 help()

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
#    Arguments: $self $args
# Side Effects: 
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
	    LogError("command $method fail");
	    if ($@ =~ /^(.*)\s+at\s+/) {
		my $reason = $1;
		Log($reason); # pick up reason
		croak($reason);
	    }
	}
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
