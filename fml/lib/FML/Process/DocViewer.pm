#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: DocViewer.pm,v 1.2 2001/04/03 09:45:43 fukachan Exp $
#

package FML::Process::DocViewer;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel Exporter);


=head1 NAME

FML::Process::DocViewer -- fmldoc wrapper

=head1 SYNOPSIS

    use FML::Process::DocViewer;
    $curproc = new FML::Process::DocViewer;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::DocViewer is the main routine of C<fmldoc> program.
It wrapps C<perldoc>. 

See C<FML::Process::Flow> for program flow.

=head2 MODULES

C<fmlconf> bootstraps itself in this order.

   libexec/loader -> FML::Process::Switch -> FML::Process::DocViewer

=head1 METHODS

=head2 C<new($args)>

usual constructor.

=head2 C<prepare($args)>

dummy.

=cut

# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: none
# Return Value: FML::Process::DocViewer object
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

the main top level dispatcher.
It kicks off internal function C<_fmlconf($args)> for
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

    if ($myname eq 'fmldoc') {
        $curproc->_fmldoc($args);
    }
    else {
	my $command = $argv->[ 0 ] || croak("command not specified\n");
    }
}


# Descriptions: fmldoc wrapper / top level dispacher
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub _fmldoc
{
    my ($curproc, $args) = @_;    
    my $config  = $curproc->{ config };
    my $myname  = $args->{ myname };
    my $argv    = $args->{ ARGV };

    my (@opts);
    push(@opts, '-v') if $args->{ options }->{ v };
    push(@opts, '-t') if $args->{ options }->{ t };
    push(@opts, '-u') if $args->{ options }->{ u };
    push(@opts, '-m') if $args->{ options }->{ m };
    push(@opts, '-l') if $args->{ options }->{ l };

    exec 'perldoc', @opts, @$argv;
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

FML::Process::DocViewer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
