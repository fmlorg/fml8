#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Configure.pm,v 1.30 2001/11/25 03:55:38 fukachan Exp $
#

package FML::Process::ConfViewer;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::ConfViewer -- fmlconf and makefml main functions

=head1 SYNOPSIS

    use FML::Process::ConfViewer;
    $curproc = new FML::Process::ConfViewer;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::ConfViewer provides the main function for 
C<fmlconf>
 and 
C<makefml>.

These programs, 
C<fmlconf> and C<makefml>,
bootstrap by using these modules in this order.

   libexec/loader -> FML::Process::Switch -> FML::Process::ConfViewer

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
# Return Value: FML::Process::ConfViewer object
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

    if (length(@$argv) == 1) {
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

    $curproc->_fmlconf($args);
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

Usage: $name [-n] \$ml_name

          show all configuration variables
 
-n        show only difference from default

_EOF_
}


=head2 C<_fmlconf($args)> (INTERNAL USE)

run dump_variables of C<FML::Config>.

=cut


# Descriptions: show configurations variables in the sytle "key = value"
#    Arguments: $self $args
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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::ConfViewer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
