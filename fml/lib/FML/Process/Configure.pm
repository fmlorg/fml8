#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

package FML::Process::Configure;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel Exporter);


=head1 NAME

FML::Process::Configure -- fmlconf and makefml wrapper

=head1 SYNOPSIS

    use FML::Process::Configure;
    $curproc = new FML::Process::Configure;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Configure is the wrapper for fmlconf and makefml.
See C<FML::Process::Flow> for each method definition.

=head2 MODULES

These programs, 
C<fmlconf> and C<makefml>,
bootstrap by using these modules in this order.

   libexec/loader -> FML::Process::Switch -> FML::Process::Configure

=head1 METHODS

=head2 C<new($args)>

usual constructor.

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


=head2 C<run($args)>

the main top level dispatcher for C<fmlconf> and C<makefml>. 
For example, it kicks off internal function C<_fmlconf($args)> for
C<fmlconf($args)>.

=cut

# Descriptions: just a switch
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $args->{ myname };
    my $argv    = $args->{ ARGV };

    if ($myname eq 'fmlconf') {
	$curproc->_fmlconf($args);
    }
    elsif ($myname eq 'makefml') {
	$curproc->_makefml($args);
    }
    else {
	my $command = $argv->[ 0 ] || croak("command not specified\n");
    }
}


# Descriptions: show configurations variables in the sytle "key = value"
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub _fmlconf
{
    my ($curproc, $args) = @_;    
    my $config = $curproc->{ config };
    my $mode   = $args->{ options }->{ n } ? 'difference_only' : 'all';
    my $argv   = $args->{ ARGV };

    $config->dump_variables({ mode => $mode });
}


# Descriptions: makefml top level dispacher
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _makefml
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $args->{ myname };
    my $argv    = $args->{ ARGV };

    my ($method, $ml_name, @options) =  @$argv;

    # arguments to pass off to each method
    my $optargs = {
	command => $method,
	ml_name => $ml_name,
	options => \@options,
	argv    => $argv,
	args    => $args,
    };

    # here we go
    require FML::Command;
    my $obj = new FML::Command;
    $obj->$method($curproc, $optargs);
}


# dummy to avoid the error ( undefined function )
sub AUTOLOAD
{
    ;
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
