#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: ThreadTrack.pm,v 1.1 2001/11/03 11:49:21 fukachan Exp $
#

package FML::Process::ThreadTrack;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::ThreadTrack -- primitive thread tracking system

=head1 SYNOPSIS

See C<Mail::ThreadTrack> module.

=head1 DESCRIPTION

This class drives thread tracking system in the top level.

=head1 METHOD

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare()>

dummy.

=cut


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy to avoid to take data from STDIN 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub prepare
{
    ;
}


=head2 C<run($args)>

call the actual thread tracking system.
It supports only 'list' and 'close' commands.

=cut

sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $argv    = $curproc->command_line_argv();
    my $command = $argv->[ 0 ] || 'list';

    #  argumente for thread track module
    my $ml_name       = $config->{ ml_name };
    my $thread_db_dir = $config->{ thread_db_dir };
    my $spool_dir     = $config->{ spool_dir };
    my $ttargs        = {
	logfp       => \&Log,
	fd          => \*STDOUT,
	db_base_dir => $thread_db_dir,
	ml_name     => $ml_name,
	spool_dir   => $spool_dir,
    };

    use Mail::ThreadTrack;
    my $thread = new Mail::ThreadTrack $ttargs;
    $thread->set_mode('text');

    if ($command eq 'list') {
	$thread->show_summary();
    }
    elsif ($command eq 'mkdb') {
	my $max_id = $curproc->article_id_max();
	for my $id ( 1 .. $max_id ) {
	    print STDERR "process $id\n";
	}
    }
    elsif ($command eq 'db_clear') {
	$thread->db_open();
	$thread->db_clear();
	$thread->db_close();
    }
    elsif ($command eq 'close') {
	$curproc->lock();

	my $thread_id = $argv->[ 2 ];
	my $args = {
	    thread_id => $thread_id, 
	    status    => 'close',
	};
	if ($thread_id) {
	    $thread->set_status($args);
	}
	else {
	    croak("specify \$thread_id");
	}

	$curproc->unlock();
    }
    else {
	croak("unknown command=$command\n");
    }
}


sub DESTROY {}

# Descriptions: dummy routine to avoid errors
#               since we need all methods defined in FML::Process::Flow.
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub AUTOLOAD
{
    my ($curproc, $args) = @_;
    1;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
