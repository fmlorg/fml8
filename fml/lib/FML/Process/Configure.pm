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
use FML::Log qw(Log);
use FML::Config;


=head1 NAME

FML::Process::Configure -- fmlconf and makefml

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

@ISA = qw(FML::Process::Kernel Exporter);

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
	$curproc->_show_conf($args);
    }
    elsif ($myname eq 'fmldoc') {
	exec 'perldoc', @$argv;
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
sub _show_conf
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

    my ($command, $ml_name, @options) =  @$argv;

    if ($command eq 'newml' ||
	$command eq 'add' || $command eq 'subscribe' ||
	$command eq 'bye' || $command eq 'unsubscribe') {
	my $method = $curproc->_which_makefml_method($command);
	my $pkg    = "FML::Command::${method}";

	# local scope
	local(@ISA) = ($pkg, @ISA);

	# arguments to pass off to each method
	my $args = {
	    command => $command,
	    ml_name => $ml_name,
	    options => \@options,
	    argv    => $argv,
	};

	eval qq{ require $pkg; $pkg->import();};
	if ($@) { Log($@); croak("command=$command is not supported.");}

	# here we go
	$curproc->lock();
	my $obj  = $pkg->new;
	$obj->$method($curproc, $args);
	$curproc->unlock();
    }
    else {
	croak("unknown makefml method");
    }
}


# Descriptions: 
#    Arguments: $self $command
# Side Effects: none
# Return Value: method name
sub _which_makefml_method
{
    my ($self, $command) = @_;
    my $method = {
	'add'          => 'subscribe',
	'subscribe'    => 'subscribe',

	'bye'          => 'unsubscribe',
	'unsubscribe'  => 'unsubscribe',

	'newml'        => 'newml',
    };

    $method->{ $command };
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
