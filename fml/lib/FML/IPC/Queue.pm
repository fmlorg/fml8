#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Queue.pm,v 1.8 2004/07/23 15:21:23 fukachan Exp $
#

package FML::IPC::Queue;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $Counter $debug);
use Carp;

$debug = 0;


=head1 NAME

FML::IPC::Queue - basic message queue operation.

=head1 SYNOPSIS

    my $queue = new FML::IPC::Queue;

    my $msg = new UserDefinedMessageObject { .. } # user defined object.
    $queue->append($msg);

    my $qlist = $queue->list();
    for my $m (@$qlist) { $m->print();}

=head1 DESCRIPTION

FML::IPC::Queue provides basic message queue operations such as
appending messages into the queue,
list up queue et.al.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: create an object
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type)   = ref($self) || $self;
    my $queue    = [];
    my $me       = {
	_curproc => $curproc || undef,
	_queue   => $queue,
	_on_disk => 0,
    };
    return bless $me, $type;
}


=head2 append($msg)

append user defined message $msg into the message queue.

=head2 list()

list up queue.

=cut


# Descriptions: append user defined message $msg into the message queue.
#    Arguments: OBJ($self) VAR_ARGS($msg)
# Side Effects: update message queue $self->{ _queue }
# Return Value: none
sub append
{
    my ($self, $msg) = @_;

    if ($self->is_use_queue_dir()) {
	$self->_append_msg_into_queue_dir($msg);
    }
    else {
	my $q = $self->{ _queue };
	push(@$q, $msg);
    }
}


# Descriptions: return the queue as ARRAY_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub list
{
    my ($self) = @_;

    if ($self->is_use_queue_dir()) {
	$self->_list_up_msg_in_queue_dir();
    }
    else {
	return $self->{ _queue };
    }
}


# Descriptions: insert message into $queue_dir.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: create queue file in $queue_dir.
# Return Value: none
sub _append_msg_into_queue_dir
{
    my ($self, $msg) = @_;
    my $queue_dir    = $self->{ _queue_dir };

    use File::Spec;
    $Counter++;
    my $tmptmp  = sprintf(",%d.%d.%d", time, $$, $Counter);
    my $tmpname = sprintf("%d.%d.%d",  time, $$, $Counter);
    my $tmpfile = File::Spec->catfile($queue_dir, $tmptmp);
    my $q_file  = File::Spec->catfile($queue_dir, $tmpname);

    use FileHandle;
    my $wh = new FileHandle "> $tmpfile";
    if (defined $wh) {
	if (ref($msg)) {
	    if ($msg->can('dump')) {
		$msg->dump($wh);
	    }
	    else {
		$self->logerror("IPC: fail to dump message");
	    }
	}
	$wh->close();
    }

    if (-s $tmpfile) {
	# initialized to unlocked state (lock == executable bit).
	chmod 0644, $tmpfile;
	unless (rename($tmpfile, $q_file)) {
	    $self->logerror("IPC: cannot rename $tmpfile $q_file");
	}
	else {
	    print STDERR "$q_file created.\n" if $debug;
	}
    }
    else {
	print STDERR "unlink $tmpfile since it is empty.\n" if $debug;
	unlink $tmpfile;
    }
}


# Descriptions: list up queue.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub _list_up_msg_in_queue_dir
{
    my ($self)    = @_;
    my $queue_dir = $self->{ _queue_dir };
    my $class     = $self->{ _module };
    my $queue     = [];
    my $remove    = [];

    use DirHandle;
    my $dh = new DirHandle $queue_dir;
    if (defined $dh) {
	my $entry;
	my $file;

      ENTRY:
	while ($entry = $dh->read()) {
	    next ENTRY if $entry =~ /^\./o;
	    next ENTRY if $entry =~ /^\,/o; # ignore temporary file.

	    $file = File::Spec->catfile($queue_dir, $entry);
	    if (-f $file) {
		# already locked.
		next ENTRY if -x $file;

		# lock.
		chmod 0755, $file;

		eval qq{
		    use FileHandle;
		    my \$rh = new FileHandle \$file;

		    use $class;
		    my \$msg = new $class;
		    \$msg->restore(\$rh);
		    push(\@\$queue, \$msg) if defined \$msg;
		    push(\@\$remove, \$file);
		};
		if ($@) {
		    $self->logerror($@);
		}
	    }
	}
    }

    # used later in destructor.
    $self->{ _remove_files } = $remove;

    return $queue;
}


# Descriptions: roll back the status of files.
#    Arguments: OBJ($self)
# Side Effects: chmod 0644 files.
# Return Value: none
sub rollback
{
    my ($self) = @_;
    my $remove = $self->{ _remove_files } || [];

    for my $f (@$remove) {
	chmod 0644, $f;
    }

    $self->{ _remove_files } = [];
}


=head1 UTILITY

=cut


# Descriptions: check if this object handles queues on file system or
#               on memory.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub is_use_queue_dir
{
    my ($self) = @_;

    return( $self->{ _on_disk } ? 1 : 0 );
}


# Descriptions: declare this object handles queues on file system.
#               existence of $dir is mandatory.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: update $self.
# Return Value: NUM
sub use_queue_dir
{
    my ($self, $dir) = @_;

    if (-d $dir) {
	$self->{ _on_disk }   = 1;
	$self->{ _queue_dir } = $dir;
    }
}


# Descriptions: set object class to be used in list().
#    Arguments: OBJ($self) STR($class)
# Side Effects: update $self.
# Return Value: none
sub use_object_class
{
    my ($self, $class) = @_;

    $self->{ _module } = $class;
}


# Descriptions: logging wrapper.
#    Arguments: OBJ($self) STR($error)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($self, $error) = @_;
    my $curproc        = $self->{ _curproc } || undef;

    if (defined $curproc) {
	$curproc->logerror($error);
    }
    else {
	warn($error);
    }
}


# Descriptions: destructor.
#    Arguments: OBJ($self)
# Side Effects: remove files to be picked up.
# Return Value: none
sub DESTROY
{
    my ($self) = @_;
    my $remove = $self->{ _remove_files } || [];

    for my $f (@$remove) {
	if (-f $f) {
	    print STDERR "DESTROY: unlink $f\n" if $debug;
	    unlink $f;
	}
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    $debug = 1;

    use FML::IPC::Message;
    my $msg = new FML::IPC::Message;
    $msg->set("to", "pager");

    my $q = new FML::IPC::Queue;
    $q->use_queue_dir("/tmp/queue");
    $q->append($msg);

    # list.
    $q->use_object_class("FML::IPC::Message");
    my $list = $q->list();

    # dump.
    use Data::Dumper;
    print Dumper($list);

    if (defined $ENV{ ROLLBACK } && $ENV{ ROLLBACK }) {
	$q->rollback();
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

FML::IPC::Queue appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
