#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: thread.pm,v 1.5 2004/03/28 13:05:55 fukachan Exp $
#

package FML::Command::Admin::thread;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::thread - show article thread or update its status.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show status article thread or manipulate it.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'article_thread';}


# Descriptions: thread manipulation interface.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    # attach thread library.
    use Mail::Message::Thread;
    my $thargs = $curproc->thread_db_args();
    my $thread = new Mail::Message::Thread $thargs;

    $self->_new_switch($curproc, $command_args, $thread);
}


# Descriptions: dispatch thread sub-command.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) OBJ($thread)
# Side Effects: update $recipient_map
# Return Value: none
sub _new_switch
{
    my ($self, $curproc, $command_args, $thread) = @_;
    my $config        = $curproc->config();
    my $options       = $command_args->{ options } || [];
    my $command       = $options->[ 0 ] || 'one_line_summary';
    my $range         = $options->[ 1 ] || '';
    my $default_range = 'last:10';
    my $max_id        = $curproc->article_max_id();
    my $th_args       = {
	last_id => $max_id,
    };

    use FML::Article::Thread;
    my $article_thread = new FML::Article::Thread $curproc;
    if ($command eq 'one_line_summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_summary($th_args);
    }
    elsif ($command eq 'list') {
	$th_args->{ range } = $range || '';
	$article_thread->print_list($th_args);
	$article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'open' || $command eq 'reopen') {
	$th_args->{ range } = $range || '';
	$article_thread->open_thread_status($th_args);
    }
    elsif ($command eq 'close') {
	$th_args->{ range } = $range || '';
	$article_thread->close_thread_status($th_args);
    }
    else {
	my $r = "unknown subcommand: thread $command";
	$curproc->logerror($r);
	$curproc->ui_message("error: $r");
    }
}


=head1 OLD VERSION

=cut


# Descriptions: thread manipulation interface.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub old_process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();
    my $myname = $curproc->myname();

    # prepare argumente for thread track module (Mail::ThreadTrack).
    my $ml_name       = $config->{ ml_name };
    my $thread_db_dir = $config->{ thread_db_dir };
    my $spool_dir     = $config->{ spool_dir };
    my $max_id        = $curproc->article_max_id();
    my $ttargs        = {
	myname        => $myname,
	logfp         => \&Log,
	fd            => \*STDOUT,
	db_base_dir   => $thread_db_dir,
	ml_name       => $ml_name,
	spool_dir     => $spool_dir,
	max_id        => $max_id,
	reverse_order => 1,
    };

    # if (defined $options->{ f }) {
    #    _read_filter_list($thread, $options->{ f });
    # }

    $self->_old_switch($curproc, $command_args, $ttargs);
}


# Descriptions: switch thread library command
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
#               HASH_REF($ttargs)
# Side Effects: thread db may be updated
# Return Value: none
sub _old_switch
{
    my ($self, $curproc, $command_args, $ttargs) = @_;
    my $options = $command_args->{ options };
    my $command = $options->[ 0 ] || 'list';
    my $max_id  = $ttargs->{ max_id };

    # utility functions for spool in fml side.
    use FML::Article::Thread;
    my $a_thread = new FML::Article::Thread $curproc;

    # functions to manipulate thread db.
    use Mail::ThreadTrack;
    my $thread = new Mail::ThreadTrack $ttargs;
    $thread->set_mode('text');

    if ($command eq 'list' || $command eq 'summary') {
	$thread->$command();
    }
    elsif ($command eq 'review') {
	my $str = $options->[ 1 ] || 'last:100';
	$thread->review( $str , 1, $max_id );
    }
    elsif ($command eq 'db_dump') {
	my $type = $options->[ 1 ] || 'status';
	$thread->db_open();
	$thread->db_dump( $type );
	$thread->db_close();
    }
    elsif ($command eq 'db_update') {
	my $last_id = $a_thread->speculate_last_id($curproc, $thread);
	print STDERR "db_update: $last_id -> $max_id\n";
	$thread->db_mkdb($last_id, $max_id);
    }
    elsif ($command eq 'db_rebuild') {
	print STDERR "\$thread->db_mkdb(1, $max_id);\n";
	$thread->db_mkdb(1, $max_id);
    }
    elsif ($command eq 'db_clear') {
	$thread->db_open();
	$thread->db_clear();
	$thread->db_close();
    }
    elsif ($command eq 'close') {
	my $thread_id = $options->[ 1 ];
	if (defined $thread_id) {
	    $a_thread->close($thread, $thread_id, 1, $max_id);
	}
	else {
	    croak("specify \$thread_id");
	}
    }
    elsif ($command eq 'cui') {
	# XXX-TODO: hmm, run interactive session unless @ARGV ?
	# XXX-TODO: showing help is appropriate ?
	if ($options->[ 1 ]) {
	    push(@ISA, 'FML::Article::Thread::CUI');
	    # $ttargs->{ ml_name } = $argv->[ 0 ];
	    $a_thread->interactive($thread, $ttargs);
	}
	else {
	    help();
	}
    }
    else {
	croak("subcommand not specified");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
