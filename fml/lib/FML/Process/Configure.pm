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

require Exporter;
@ISA = qw(FML::Process::Kernel Exporter);


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# dummy
sub prepare
{
    ;
}


sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $args->{ myname };
    my $argv    = $args->{ ARGV };
    my $command = $argv->[ 0 ] || croak("command not specified\n");

    # XXX debug
    # use Data::Dumper; print Dumper( $args ); sleep 3;

    if ($myname eq 'fmlconf') {
	$curproc->_show_conf($args);
    }
    elsif ($myname eq 'fmldoc') {
	exec 'perldoc', '-v', @$argv;
    }
    else {
	$curproc->lock();
	{
	    ;
	}
	$curproc->unlock();
    }
}


sub _show_conf
{
    my ($curproc, $args) = @_;    
    my $config = $curproc->{ config };
    my $mode   = $args->{ options }->{ n } ? 'difference_only' : 'all';

    $config->dump_variables({ mode => $mode });
}


sub AUTOLOAD
{
    my ($curproc, $args) = @_;
    ;
}


=head1 NAME

Configure -- fmlconf and makefml

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

1;
