#-*- perl -*-
#
# Copyright (C) 2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Thread.pm,v 1.3 2003/03/28 10:03:37 fukachan Exp $
#

package FML::Article::Thread;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Article::Thread -- primitive thread tracking system

=head1 SYNOPSIS

See C<Mail::ThreadTrack> module.

=head1 DESCRIPTION

This class drives thread tracking system in the top level.

=head1 METHOD

=head2 new($curproc)

create a C<FML::Process::Kernel> object and return it.

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my $type = ref($self) || $self;
    my $me   = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: return the last modified time.
#    Arguments: OBJ($self) STR($seq_file)
# Side Effects: none
# Return Value: NUM
sub _last_modified_time
{
    my ($self, $seq_file) = @_;
    my $sf_last_modified  = 0;

    if (-f $seq_file) {
	use File::stat;
	my $st = stat($seq_file);
	$sf_last_modified =
	    ($sf_last_modified > $st->mtime ? $sf_last_modified : $st->mtime);
    }

    return $sf_last_modified;
}


# Descriptions: speculate the last id our thread system processed.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($thread)
# Side Effects: none
# Return Value: NUM
sub speculate_last_id
{
    my ($self, $curproc, $thread) = @_;
    my $config           = $curproc->config();
    my $seq_file         = $config->{ sequence_file };
    my $db_last_modified = $thread->db_last_modified();
    my $sf_last_modified = $self->_last_modified_time($seq_file);

    # The condition "$sf_last_modified < $db_last_modified" is always
    # true since FML::Process::Distribute updates the thread db after
    # updating $seq_file.
    # XXX 3600 is the magic number. How long time is appropriate ?
    if (-f $seq_file &&
	($sf_last_modified + 3600 > $db_last_modified)) {
	return $curproc->article_max_id();
    }
    else {
	my $last_id = 0;

	$thread->db_open();

	my $rh = $thread->db_hash( 'date' );
	if (defined $rh) {
	    use File::Sequence;
	    my $obj = new File::Sequence;
	    $last_id = $obj->search_max_id( { hash => $rh } );
	}

	$thread->db_close();

	return $last_id;
    }
}


# Descriptions: speculate the maximum sequence number for ML articles.
#    Arguments: OBJ($self) OBJ($curproc) STR($spool_dir)
# Side Effects: none
# Return Value: NUM
sub speculate_max_id
{
    my ($self, $curproc, $spool_dir) = @_;

    eval q{
	use FML::Article;
	push(@ISA, 'FML::Article');
    };
    my $max_id = $curproc->speculate_max_id();

    # XXX check whether $max_id > 1 or not since
    # XXX speculate_max_id() returns 1 by default
    if ($max_id > 1) {
	return $max_id;
    }
    else {
	eval q{
	    use FML::Article;
	    push(@ISA, 'FML::Article');
	    $max_id = $curproc->speculate_max_id($spool_dir);
	};
	warn($@) if $@;
    }

    if ($max_id > 0) {
	return $max_id;
    }

    warn("cannot determine max_id");
    return undef;
}


# Descriptions: read filter list
#    Arguments: OBJ($self) OBJ($thread) STR($file)
# Side Effects: none
# Return Value: none
sub _read_filter_list
{
    my ($self, $thread, $file) = @_;

    if (-f $file) {
	use FileHandle;
	my $fh = new FileHandle $file;
	if (defined $fh) {
	    my ($key, $value, $buf);
	    while ($buf = <$fh>) {
		chomp $buf;
		($key, $value) = split(/\s+/, $buf, 2);
		if ($key) {
		    $thread->add_filter( { $key => $value });
		}
	    }
	    $fh->close();
	}
    }
}


# Descriptions: change status to "closed".
#               $thread_id accepts MH style format.
#               MH style is expanded by C<Mail::Messsage::MH>.
#    Arguments: OBJ($self) OBJ($thread) STR($thread_id) NUM($min) NUM($max)
# Side Effects: update thread status database
# Return Value: none
sub close
{
    my ($self, $thread, $thread_id, $min, $max) = @_;
    my $curproc = $self->{ _curproc };

    # expand MH style variable: e.g. last:100 -> [ 100 .. 200 ]
    use Mail::Message::MH;
    my $ra = Mail::Message::MH->expand($thread_id, $min, $max);
    $ra = [ $thread_id ] unless defined $ra;

    for my $id (@$ra) {
	# e.g. 100 -> elena/100
	if ($id =~ /^\d+$/) {
	    $id = $thread->_create_thread_id_strings($id);
	}

	# check "elena/100" exists ?
	if ($thread->exist($id)) {
	    $curproc->log("close thread_id=$id");
	    $thread->close($id);
	}
	else {
	    $curproc->log("thread_id=$id not exists") if $debug;
	}
    }
}


package FML::Article::Thread::CUI;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;


# Descriptions: top level interface for CUI.
#               This routine is in loop.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($thread) HASH_REF($ttargs)
# Side Effects: none
# Return Value: none
sub interactive
{
    my ($self, $curproc, $thread, $ttargs) = @_;

    eval q{
	use Term::ReadLine;
	my $term    = new Term::ReadLine "fmlthread";
	my $ml_name = $ttargs->{ ml_name };
	my $prompt  = "$ml_name thread> ";
	my $OUT     = $term->OUT || \*STDOUT;
	my $res     = '';
	my $buf     = '';

	# main loop;
	no strict;
	while ( defined ($buf = $term->readline($prompt)) ) {
	    $self->_exec($curproc, $thread, $ttargs, $buf);
	    warn $@ if $@;
	    $term->addhistory($buf) if $buf =~ /\S/o;
	}
    };
    carp($@) if $@;
}


# Descriptions: CUI command switch
#    Arguments: OBJ($self) OBJ($curproc)
#               OBJ($xthread) HASH_REF($ttargs) STR($buf)
# Side Effects: exit for some type of input.
# Return Value: none
sub _exec
{
    my ($self, $curproc, $xthread, $ttargs, $buf) = @_;
    my ($command, @argv) = ();

    use Mail::ThreadTrack;
    my $thread = new Mail::ThreadTrack $ttargs;
    $thread->set_mode('text');

    # clean up
    if (defined $buf && $buf) {
	$buf =~ s/^\s*//;
	$buf =~ s/\s*$//;
	($command, @argv) = split(/\s+/, $buf);
    }

    if ($command eq '') {
	help();
    }
    elsif ($command eq 'quit' || $command eq 'exit' || $command eq 'end') {
	exit(0);
    }
    elsif ($command eq 'list') {
	$thread->list();
    }
    elsif ($command eq 'show') {
	for my $id (@argv) {
	    if ($id =~ /^\d+$/) {
		my $xid = $thread->_create_thread_id_strings($id);
		use FileHandle;
		my $wh = new FileHandle "| less";
		my $saved_fd = $thread->get_fd( $wh );
		$thread->set_fd( $wh );
		$thread->show($xid);
		$thread->set_fd( $saved_fd );
	    }
	    else {
		print "sorry, cannot show $id\n";
	    }
	}
    }
    elsif ($command eq 'close') {
	my $max_id = $ttargs->{ max_id };
	for my $id (@argv) {
	    print "close $id\n";
	    &FML::Article::Thread::_close($thread, $id, 1, $max_id);
	}
    }
    else {
	help();
    }
}


# Descriptions: show CUI help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    print "Usage: $0\n\n";

    print "list         show thread summary (without article summary)\n";
    print "show  id(s)  show articles in thread_id\n";
    print "close id(s)  close thread specified by thread_id\n";
    print "quit         to end\n";
    print "Ctl-D        to end\n";
    print "\n";
    print "Typical Usage:\n";
    print "  > list\n ... \n";
    print "  > show 100\n";
    print "  > close 100\n";
    print "\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
