#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: ThreadTrack.pm,v 1.3 2001/11/04 06:50:41 fukachan Exp $
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

=cut

sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $argv    = $curproc->command_line_argv();
    my $command = $argv->[ 0 ] || '';

    #  argumente for thread track module
    my $ml_name       = $config->{ ml_name };
    my $thread_db_dir = $config->{ thread_db_dir };
    my $spool_dir     = $config->{ spool_dir };
    my $max_id        = $curproc->article_id_max();
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

    $curproc->lock();

    if ($command eq 'list' || $command eq 'summary') {
	$thread->show_summary();
    }
    elsif ($command eq 'db_mkdb') {
	$thread->db_mkdb(1, $max_id);
    }
    elsif ($command eq 'db_clear') {
	$thread->db_open();
	$thread->db_clear();
	$thread->db_close();
    }
    elsif ($command eq 'close') {
	my $thread_id = $argv->[ 2 ];
	if (defined $thread_id) {
	    _close($thread, $thread_id, 1, $max_id);
	}
	else {
	    croak("specify \$thread_id");
	}
    }
    else {
	help();
    }

    $curproc->unlock();
}


# $thread_id accepts MH style format.
# MH style is expanded by C<Mail::Messsage::MH>.
sub _close
{
    my ($thread, $thread_id, $min, $max) = @_;

    # expand MH style variable: e.g. last:100 -> [ 100 .. 200 ]
    use Mail::Message::MH;
    my $ra = Mail::Message::MH->expand($thread_id, $min, $max);
    $ra = [ $thread_id ] unless defined $ra;

    for my $id (@$ra) {
	# e.g. 100 -> elena/100
	if ($id =~ /^\d+$/) { $id = $thread->_create_thread_id_strings($id);}

	# check "elena/100" exists ?
	if ($thread->exist($id)) {
	    Log("close thread_id=$id");
	    $thread->close($id);
	}
	else {
	    Log("thread_id=$id not exists") if $ENV{'debug'};
	}
    }
}


sub help
{
    use File::Basename;
    my $name = basename($0);

print <<"_EOF_";

Usage: $name \$command \$ml_name [options]

$name list     \$ml_name          list up summary
$name summary  \$ml_name          list up summary
$name close    \$ml_name id       close ticket specified by id (MH style)
$name db_mkdb  \$ml_name          recreate \$ml_name thread database
$name db_clear \$ml_name          clear \$ml_name thread database

_EOF_
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
