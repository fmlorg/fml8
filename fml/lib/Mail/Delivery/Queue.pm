#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Queue.pm,v 1.55 2005/12/18 11:39:37 fukachan Exp $
#

package Mail::Delivery::Queue;
use strict;
use Carp;
use vars qw($Counter @class_list @local_class_list $counter);
use File::Spec;
use Mail::Delivery::ErrorStatus qw(error_set error error_clear);


=head1 NAME

Mail::Delivery::Queue - handle queue directory.

=head1 SYNOPSIS

    use Mail::Message;
    $msg = new Mail::Message;

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => "/some/where" };

    # queue in a new message
    # "/some/where/new/$queue_id" is created.
    $queue->in( $msg ) || croak("fail to queue in");

    # ok to deliver this message !
    $queue->setrunnable() || croak("fail to set queue deliverable");

    # get the filename of this $queue object
    my $filename = $queue->filename();

=head1 DESCRIPTION

C<Mail::Delivery::Queue> provides basic manipulation of mail queue.

=head1 DIRECTORY STRUCTURE

C<new()> method assigns a new queue id C<$qid> and filename C<$qf> but
not do actual works.

C<in()> method creates a new queue file C<$qf>. So, C<$qf> follows:

   $qf = "$queue_dir/new/$qid"

When C<$qid> queue is ready to be delivered, you must move the queue
file from new/ to active/ by C<rename(2)>. To make this queue
deliverable, use C<setrunnable()> method.

   $queue_dir/new/$qid  --->  $queue_dir/active/$qid

The actual delivery is done by other modules such as
C<Mail::Delivery>.
C<Mail::Delivery::Queue> manipulates only queue around things.

=head1 METHODS

=head2 new($args)

constructor. You must specify at least C<queue directory> as

    $args->{ dirctory } .

If C<id> is not specified,
C<new()> assigns the queue id, queue files to be used.
C<new()> assigns them but do no actual works.

=cut

my $default_policy = "oldest";

my $dir_mode = 0755;

@class_list = qw(lock
		 new deferred active incoming info sender recipients
		 transport strategy
		 );

# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: initialize object
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type)        = ref($self) || $self;
    my $dir           = $args->{ directory }   || croak("specify directory");
    my $id            = $args->{ id }          || _new_queue_id();
    my $local_class   = $args->{ local_class } || [];
    my $me            = {
	_directory    => $dir,
	_id           => $id,
    };

    # bless !
    bless $me, $type;

    # update queue directory mode
    $dir_mode = $args->{ directory_mode } || $dir_mode;

    # update optional local class list.
    for my $c (@$local_class) { push(@local_class_list, $c);}

    # initialize directories.
    -d $dir || $me->_mkdirhier($dir);
    for my $class (@class_list, @local_class_list) {
	my $fp   = sprintf("%s_dir_path", $class);
	my $_dir = $me->can($fp) ? $me->$fp() : $me->local_dir_path($class);
	-d $_dir || $me->_mkdirhier($_dir);
    }

    # hold information for delivery
    my $qf_new = $me->new_file_path($id);
    my $files  = [];
    push(@$files, $qf_new);
    $me->{ _cleanup_files } = $files;


    return bless $me, $type;
}


# Descriptions: mkdir recursively.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: ARRAY or UNDEF
sub _mkdirhier
{
    my ($self, $dir) = @_;

    eval q{
	use File::Path;
	mkpath( [ $dir ], 0, $dir_mode);
    };
    warn($@) if $@;
}


# Descriptions: return new queue identifier.
#    Arguments: none
# Side Effects: increment counter $Counter
# Return Value: STR
sub _new_queue_id
{
    my ($seconds, $microseconds) = (0, 0);

    $Counter++;
    my $id = sprintf("%d.%d.%d", time, $$, $Counter);

    eval q{
	use Time::HiRes qw(usleep gettimeofday);
	($seconds, $microseconds) = gettimeofday;
    };
    if ($@) {
	my ($second, $microseconds) = (time, 0);
	$id = sprintf("%d.%06d.%d.%d", $seconds, $microseconds, $$, $Counter);
    }
    else {
	$id = sprintf("%d.%06d.%d.%d", $seconds, $microseconds, $$, $Counter);
    }

    return $id;
}


=head2 id()

return the queue id assigned to this object C<$self>.

=cut


# Descriptions: return object identifier (queue id).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub id
{
    my ($self) = @_;
    $self->{ _id };
}


=head2 list( [ $class ] )

return queue list as ARRAY REFERENCE.
by default, return a list of queue filenames in C<active/> directory.

    $ra = $queue->list();
    for $qid (@$ra) {
	something for $qid ...
     }

where C<$qid> is like this: 990157187.20792.1

=head2 list_all()

return all queue list in all classes.

=cut


# Descriptions: return queue file list as ARRAY_REF.
#    Arguments: OBJ($self) STR($class) STR($policy)
# Side Effects: none
# Return Value: ARRAY_REF
sub list
{
    my ($self, $class, $policy) = @_;
    my $fp  = $class ? "${class}_dir_path" : "active_dir_path";
    my $dir = $self->can($fp) ? $self->$fp() : $self->local_dir_path($class);

    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my @r = ();
	my $file;

      ENTRY:
	while (defined ($file = $dh->read)) {
	    next ENTRY unless $file =~ /^\d+/o;
	    push(@r, $file);
	}

	return $self->_list_ordered_by_policy(\@r, $policy);
    }

    return [];
}


# Descriptions: return list of all queue irrespective of validity.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub list_all
{
    my ($self) = @_;
    my (@r)    = ();
    my (%r)    = ();

    for my $class (@class_list) {
	my $ra = $self->list($class, "default");
	push(@r, @$ra);
    }

    for my $q (sort @r) {
	$r{ $q } = 1;
    }

    @r = keys %r;
    return \@r;
}


=head2 set_policy($policy)

set queue management policy.

=head2 get_policy()

return queue management policy.

=cut


# Descriptions: set queue management policy.
#    Arguments: OBJ($self) STR($policy)
# Side Effects: update $self.
# Return Value: none
sub set_policy
{
    my ($self, $policy) = @_;

    if (defined $policy) {
	$self->{ _policy } = $policy;
    }
}


# Descriptions: get queue management policy.
#    Arguments: OBJ($self) STR($policy)
# Side Effects: update $self.
# Return Value: none
sub get_policy
{
    my ($self, $policy) = @_;

    return( $self->{ _policy } || $default_policy );
}


# Descriptions: return re-ordering queue list.
#    Arguments: OBJ($self) ARRAY_REF($list) STR($_policy)
# Side Effects: none
# Return Value: ARRAY_REF
sub _list_ordered_by_policy
{
    my ($self, $list, $_policy) = @_;
    my $policy = $_policy || $self->get_policy() || $default_policy;

    if ($policy eq 'oldest') {
	my (@r) = sort _queue_streategy_oldest @$list;
	return \@r;
    }
    elsif ($policy eq 'newest') {
	my (@r) = sort _queue_streategy_newest @$list;
	return \@r;
    }
    elsif ($policy eq 'fair_queue' || $policy eq 'fair-queue') {
	my ($queue_hash, $qlist, @qlist);

	# create hash { TIME_SLICE => [ qid1,  qid2,  ... ] }
	$queue_hash = {};
	for my $q (@$list) {
	    if ($q =~ /^(\d+)/o) {
		my $t = int( $1 / 87400 );
		$qlist = $queue_hash->{ $t } || [];
		push(@$qlist, $q);
		$queue_hash->{ $t } = $qlist;
	    }
	}

	# randomized queue.
	my @p = ();
	srand(time | $$);
	$counter = rand( time );
	for my $i (sort _rand keys %$queue_hash) {
	    my $qlist = $queue_hash->{ $i } || [];
	    push(@p, sort _rand @$qlist);
	}
	return \@p;
    }
    else {
	for my $q (@$list) { ;}
    }

    return $list;
}


# Descriptions: randomize (for sort routine).
#    Arguments: none
# Side Effects: none
# Return Value: NUM
sub _rand
{
    my $x = rand(time + $counter++);
    my $y = rand(time + $counter++);
    $x <=> $y;
}


# Descriptions: sort by normal date order.
#    Arguments: IMPLICIT
# Side Effects: none
# Return Value: NUM
sub _queue_streategy_oldest
{
    my $xa = $a;
    my $xb = $b;

    $xa =~ s/\.\d+.*$//;
    $xb =~ s/\.\d+.*$//;

    $xa <=> $xb;
}


# Descriptions: sort by reverse date order.
#    Arguments: IMPLICIT
# Side Effects: none
# Return Value: NUM
sub _queue_streategy_newest
{
    my $xa = $a;
    my $xb = $b;

    $xa =~ s/\.\d+.*$//;
    $xb =~ s/\.\d+.*$//;

    $xb <=> $xa;
}


# Descriptions: update queue info for queue management policy.
#    Arguments: OBJ($self) HASH_REF($policy_args)
# Side Effects: update $self.
# Return Value: none
sub update_schedule
{
    my ($self, $policy_args) = @_;
    my $id          = $policy_args->{ queue_id } || $self->id();
    my $qf_deferred = $self->deferred_file_path($id);

    # get hints.
    my $hints = $self->_update_schedule_info($id);
    my $sleep = $hints->{ sleep } || 300;
    my $time  = time + $sleep;

    # set expired time.
    utime $time, $time, $qf_deferred;
}


# Descriptions: get hints for this queue id.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: none
sub _update_schedule_info
{
    my ($self, $id) = @_;
    my $info = {};
    my $file = $self->strategy_file_path($id);

    use IO::Adapter;
    my $hint = new IO::Adapter $file;
    $hint->touch();
    $hint->open();

    # sleep time
    my $cur_sleep = $hint->find("SLEEP") || 300;
    $cur_sleep =~ s/^.*SLEEP\s+//;
    $cur_sleep =~ s/\s*$//;
    my $new_sleep = int( ($cur_sleep || 300 ) * (1 + rand(1)) );
    $new_sleep = $new_sleep < 4000 ? $new_sleep : 4000;
    $hint->delete("SLEEP");
    $hint->add("SLEEP", [ $new_sleep ]);
    $info->{ sleep } = $new_sleep;

    $hint->close();

    return $info;
}


# Descriptions: move deferred queue to active one.
#    Arguments: OBJ($self) STR($id)
# Side Effects: update queue.
# Return Value: none
sub wakeup_queue
{
    my ($self, $id) = @_;
    $self->_change_queue_mode($id, "active");
}


# Descriptions: move active queue to deferred one.
#    Arguments: OBJ($self) STR($id)
# Side Effects: update queue.
# Return Value: none
sub sleep_queue
{
    my ($self, $id) = @_;
    $self->_change_queue_mode($id, "deferred");
}


# Descriptions: change mode.
#               move active queue to deferred one, vice versa.
#    Arguments: OBJ($self) STR($id) STR($to_mode)
# Side Effects: update queue.
# Return Value: none
sub _change_queue_mode
{
    my ($self, $id, $to_mode) = @_;

    $id ||= $self->id();

    if ($self->lock()) {
	my $qf_deferred = $self->deferred_file_path($id);
	my $qf_active   = $self->active_file_path($id);
	my $qstr_args   = {
	    queue_id    => $id,
	};

	if ($to_mode eq 'active') {
	    if (-f $qf_deferred) {
		rename($qf_deferred, $qf_active);
		$self->touch($qf_active);
		if (-f $qf_active) {
		    $self->log("qid=$id activated.");
		}
		else {
		    $self->log("error: qid=$id operation failed.");
		}
	    }
	    else {
		$self->log("no such deferred queue qid=$id");
	    }
	}
	elsif ($to_mode eq 'deferred' || $to_mode eq 'defer') {
	    if (-f $qf_active) {
		rename($qf_active, $qf_deferred);
		$self->touch($qf_deferred);
		$self->update_schedule($qstr_args);

		if (-f $qf_deferred) {
		    $self->log("qid=$id deferred");
		}
		else {
		    $self->log("error: qid=$id operation failed.");
		}
	    }
	    else {
		$self->log("no such active queue qid=$id");
	    }
	}
	else {
	    $self->log("invalid mode");
	}

	$self->unlock();
    }
    else {
	$self->log("qid=$id lock failed.");
    }
}


# Descriptions: reschedule queues. wake up queue if needed.
#    Arguments: OBJ($self)
# Side Effects: wake up queue if needed.
# Return Value: none
sub reschedule
{
    my ($self) = @_;
    my $q_list = $self->list("deferred");
    my $count  = 0;
    my $early  = 0;
    my $total  = 0;

    use File::stat;
    for my $qid (@$q_list) {
	my $qf = $self->deferred_file_path($qid);
	my $st = stat($qf);

	$total++;
	if ($st->mtime < time) {
	    $self->wakeup_queue($qid);
	    $count++;
	}
	else {
	    $early++;
	}
    }

    if ($count) {
	$self->log("activate $count queue(s)");
	$self->log("$early queue(s) sleeping") if $early;
    }
    else {
	$self->log("$early queue(s) sleeping");
    }
}


=head1 METHODS TO MANIPULATE INFORMATION

=head2 getidinfo($id)

return information related with the queue id C<$id>.
The returned information is

	id         => $id,
	path       => "$dir/active/$id",
	sender     => $sender,
	recipients => \@recipients,

=cut


# Descriptions: get information of queue for this object.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: HASH_REF
sub getidinfo
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory };
    my ($fh, $sender, @recipients);

    # validate if the queue id is given
    $id ||= $self->id();

    # sender
    use FileHandle;
    $fh = new FileHandle $self->sender_file_path($id);
    if (defined $fh) {
	$sender = $fh->getline;
	$sender =~ s/[\n\s]*$//o;
	$fh->close;
    }

    # recipient array
    $fh = new FileHandle $self->recipients_file_path($id);
    if (defined $fh) {
	my $buf;

      ENTRY:
	while (defined($buf = $fh->getline)) {
	    $buf =~ s/[\n\s]*$//o;
	    push(@recipients, $buf);
	}
	$fh->close;
    }

    return {
	id         => $id,
	path       => $self->active_file_path($id),
	sender     => $sender      || '',
	recipients => \@recipients || [],
    };
}


# Descriptions: when last modified.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: NUM(oldest unix time)
sub last_modified_time
{
    my ($self, $id) = @_;
    my $min_mtime = time;

    # queue id.
    $id ||= $self->id();

    use File::stat;
    for my $class (@class_list, @local_class_list) {
        my $fp    = sprintf("%s_file_path", $class);
        my $file  = $self->can($fp) ? $self->$fp($id) :
	    $self->local_file_path($class, $id);

	if (-f $file) {
	    my $st    = stat($file);
	    my $mtime = $st->mtime();

	    # find oldest file info.
	    $min_mtime = $min_mtime < $mtime ? $min_mtime : $mtime;
	}
    }

    return $min_mtime;
}


=head1 LOCK

=head2 lock()

=head2 unlock()

=cut


use FileHandle;
use Fcntl qw(:DEFAULT :flock);


# Descriptions: lock queue.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: flock queue
# Return Value: NUM(1 or 0)
sub lock
{
    my ($self, $args) = @_;
    my $wait    = defined $args->{ wait } ? $args->{ wait } : 10;
    my $is_prep = defined $args->{ lock_before_runnable } ? 1 : 0;
    my $id      = $self->id();
    my $qf_new  = $self->new_file_path($id);
    my $qf_lock = $self->lock_file_path($id);
    my $qf_act  = $self->active_file_path($id);
    my $lckfile = $is_prep ? $qf_new : (-f $qf_lock ? $qf_lock : $qf_act);
    my $fh      = new FileHandle $lckfile;

    eval {
	local($SIG{ALRM}) = sub { croak("lock timeout");};
        alarm( $wait );
	flock($fh, &LOCK_EX);
	$self->{ _lock }->{ _fh } = $fh;
    };
    alarm(0);

    ($@ =~ /lock timeout/o) ? 0 : 1;
}


# Descriptions: unlock queue.
#    Arguments: OBJ($self)
# Side Effects: unlock queue by flock(2)
# Return Value: NUM(1 or 0)
sub unlock
{
    my ($self) = @_;
    my $fh = $self->{ _lock }->{ _fh } || undef;

    if (defined $fh) {
	flock($fh, &LOCK_UN);
    }
}


=head2 in($msg)

C<in()> creates a queue file in C<new/> directory
(C<queue_directory/new/>.

C<$msg> is C<Mail::Message> object by default.
If C<$msg> object has print() method,
arbitrary C<$msg> is acceptable.

REMEMBER YOU MUST DO C<setrunnable()> for the queue to be delivered.
If you not C<setrunnable()> it, the queue file is removed by
C<DESTRUCTOR>.

=cut


# Descriptions: create a new queue file.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: 1 or 0
sub in
{
    my ($self, $msg) = @_;
    my $id           = $self->id();
    my $qf_qstr      = $self->strategy_file_path($id);
    my $qf_lock      = $self->lock_file_path($id);
    my $qf_new       = $self->new_file_path($id);

    $self->touch($qf_lock) unless -f $qf_lock;
    $self->touch($qf_qstr) unless -f $qf_qstr;
    $self->touch($qf_new)  unless -f $qf_new;

    use FileHandle;
    my $fh = new FileHandle "> $qf_new";
    if (defined $fh) {
	$fh->autoflush(1);
	$fh->clearerr();
	$msg->print($fh);
	if ($fh->error()) {
	    $self->error_set("write error");
	}
	$fh->close;

	if ($msg->can('write_count')) {
	    my $write_count = $self->{ _write_count } = $msg->write_count();

	    use File::stat;
	    my $try_count = 3;
	    my $ok = 0;
	  TRY:
	    while ($try_count-- > 0) {
		my $st = stat($qf_new);
		if ($st->size == $write_count) {
		    $ok = 1;
		    last TRY;
		}
		sleep 1;
	    }

	    unless ($ok) {
		$self->error_set("write error: size mismatch");
	    }
	}
    }

    # check the existence and the size > 0.
    return( (-e $qf_new && -s $qf_new) ? 1 : 0 );
}


# Descriptions: return num of bytes written successfully.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub write_count
{
    my ($self) = @_;

    return( $self->{ _write_count } || 0 );
}


=head2 set($key, $args)

   $queue->set('sender', $sender);
   $queue->set('recipients', [ $recipient0, $recipient1 ] );

It sets up delivery information in C<info/sender/> and
C<info/recipients/> directories.

=cut


# Descriptions: set value for key.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: same as close()
sub set
{
    my ($self, $key, $value) = @_;
    my $id            = $self->id();
    my $qf_sender     = $self->sender_file_path($id);
    my $qf_recipients = $self->recipients_file_path($id);
    my $qf_transport  = $self->transport_file_path($id);

    use FileHandle;

    if ($key eq 'sender') {
	my $fh = new FileHandle "> $qf_sender";
	if (defined $fh) {
	    $fh->clearerr();
	    print $fh $value, "\n";
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'recipients') {
	my $fh = new FileHandle ">> $qf_recipients";
	if (defined $fh) {
	    $fh->clearerr();
	    if (ref($value) eq 'ARRAY') {
		for my $rcpt (@$value) { print $fh $rcpt, "\n";}
	    }
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'recipient_maps') {
	my $fh = new FileHandle ">> $qf_recipients";
	if (defined $fh) {
	    $fh->clearerr();

	    if (ref($value) eq 'ARRAY') {
		for my $map (@$value) {
		    use IO::Adapter;
		    my $obj = new IO::Adapter $map;
		    if (defined $obj) {
			$obj->open();

			my $buf;
			while ($buf = $obj->get_next_key()) {
			    print $fh $buf, "\n";
			}
			$obj->close();
		    }
		}
	    }

	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'transport') {
	my $fh = new FileHandle "> $qf_transport";
	if (defined $fh) {
	    $fh->clearerr();
	    print $fh $value, "\n";
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
}


=head2 setrunnable()

set the status of the queue assigned to this object C<$self>
deliverable.
This file is scheduled to be delivered.

In fact, setrunnable() C<rename>s the queue id file from C<new/>
directory to C<active/> directory like C<postfix> queue strategy.

=cut


# Descriptions: enable this object queue to be deliverable.
#    Arguments: OBJ($self)
# Side Effects: move $queue_id file from new/ to active/
# Return Value: NUM( 1 (success) or 0 (fail) )
sub setrunnable
{
    my ($self)        = @_;
    my $id            = $self->id();
    my $qf_new        = $self->new_file_path($id);
    my $qf_active     = $self->active_file_path($id);
    my $qf_sender     = $self->sender_file_path($id);
    my $qf_recipients = $self->recipients_file_path($id);

    # something error.
    if ($self->error()) {
	warn( $self->error() );
	return 0;
    }

    # There must be a set of these three files.
    # 1. exisntence
    unless (-f $qf_new && -f $qf_sender && -f $qf_recipients) {
	return 0;
    }
    # 2. non-zero size.
    unless (-s $qf_new && -s $qf_sender && -s $qf_recipients) {
	return 0;
    }

    # move new/$id to active/$id
    if (rename($qf_new, $qf_active)) {
	return 1;
    }

    return 0;
}


=head2 touch($file)

=cut


# Descriptions: touch file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: create $file.
# Return Value: none
sub touch
{
    my ($self, $file) = @_;

    use FileHandle;
    my $fh = new FileHandle;
    if (defined $fh) {
        $fh->open($file, "a");
        $fh->close();

	my $now = time;
	utime $now, $now, $file;
    }
}


=head2 remove()

remove all queue assigned to this object C<$self>.

=head2 valid()

check if the queue file is broken or not.
return 1 (valid) or 0 (broken).

=cut


# Descriptions: remove queue files for this object (queue).
#    Arguments: OBJ($self)
# Side Effects: remove queue file(s)
# Return Value: none
sub remove
{
    my ($self) = @_;
    my $id     = $self->id();

    my $count   = 0;
    my $removed = 0;
    for my $class (@class_list, @local_class_list) {
        my $fp = sprintf("%s_file_path", $class);
        my $f  = $self->can($fp) ? $self->$fp($id) :
	    $self->local_file_path($class, $id);

	if (-f $f) {
	    $count++;
	    unlink $f;
	    $removed++ unless -f $f;
	}
    }

    if ($count > 0) {
	if ($count == $removed) {
	    $self->log("qid=$id removed");
	}
	else {
	    $self->log("qid=$id remove failed");
	}
    }
}


# Descriptions: this object (queue) is sane as active queue?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub is_valid_active_queue
{
    my ($self) = @_;
    my $ok     = 0;
    my $id     = $self->id();

    # files to check.
    my $qf_active     = $self->active_file_path($id);
    my $qf_sender     = $self->sender_file_path($id);
    my $qf_recipients = $self->recipients_file_path($id);

    for my $f ($qf_active, $qf_sender, $qf_recipients) {
	$ok++ if -f $f && -s $f;
    }

    ($ok == 3) ? 1 : 0;
}


# Descriptions: this object (queue) is sane as active queue?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub is_valid_queue
{
    my ($self) = @_;
    my $ok     = 0;
    my $id     = $self->id();

    # files to check.
    my $qf_active     = $self->active_file_path($id);
    my $qf_deferred   = $self->deferred_file_path($id);
    my $qf_sender     = $self->sender_file_path($id);
    my $qf_recipients = $self->recipients_file_path($id);

    for my $f ($qf_sender, $qf_recipients) {
	$ok++ if -f $f && -s $f;
    }

    # XXX You need lock() before calling is_valid_*_queue() method.
    #
    # if "-s $qf_active ; rename() in some other process; -s $qf_deferred"
    # operation is done, this check fails.
    # make this check more robust, check again.
    # this logic is stupid and not perfect but effective ?
    if (-s $qf_active || -s $qf_deferred) { $ok++;}
    if (-s $qf_active || -s $qf_deferred) { $ok++;}

    ($ok == 4) ? 1 : 0;
}


# Descriptions: clear this queue file.
#    Arguments: OBJ($self)
# Side Effects: unlink this queue
# Return Value: NUM
sub DESTROY
{
    my ($self) = @_;
    my $files  = $self->{ _cleanup_files } || [];

    for my $file (@$files) {
	unlink $file if -f $file;
    }
}


=head1 UTILITIES

=head2 dup_content($class)

duplicate content at a class $class other than incoming.

=cut


# Descriptions: duplicate content at a class $class other than incoming.
#               return new queue id generated in dupilication.
#    Arguments: OBJ($self) STR($old_class) STR($new_class)
# Side Effects: none
# Return Value: STR
sub dup_content
{
    my ($self, $old_class, $new_class) = @_;
    my $id         = $self->id();
    my $new_id     = _new_queue_id();
    my $queue_file = $self->local_file_path($old_class, $id);
    my $new_qf     = $self->local_file_path($new_class, $new_id);

    return( link($queue_file, $new_qf) ? $new_id : undef );
}


=head1 IO Interface

=head2 open($class, $args)

open incoming queue of this queue id with mode $mode and return the
file handle.

=head2 close($class)

close.

=cut


# Descriptions: open incoming queue of this object with mode $mode
#               and return the file handle.
#    Arguments: OBJ($self) STR($class) HASH_REF($op_args)
# Side Effects: file handle opened.
# Return Value: HANDLE
sub open
{
    my ($self, $class, $op_args) = @_;
    my $id = $self->id();
    my $fp = sprintf("%s_file_path", $class);
    my $qf = $self->can($fp) ? $self->$fp($id) :
	$self->local_file_path($class, $id);

    if (defined $op_args->{ in_channel }) {
	my $channel = $op_args->{ in_channel };
	open($channel, $qf);
    }
    else {
	use FileHandle;
	my $mode = $op_args->{ mode } || "r";
	my $fh   = new FileHandle $qf, $mode;
	if (defined $fh) {
	    $self->{ "_${class}_channel" } = $fh;
	    return $fh;
	}
	else {
	    return undef;
	}
    }
}


# Descriptions: close the incoming channel of this object.
#    Arguments: OBJ($self) STR($class)
# Side Effects: file handle closed.
# Return Value: none
sub close
{
    my ($self, $class) = @_;
    my $channel = $self->{ "_${class}_channel" } || undef;

    if (defined $channel) {
	close($channel);
    }
}


=head1 DIR/FILE UTILITIES

=cut


# Descriptions: return "lock" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub lock_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "lock");
}


# Descriptions: return "lock" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub lock_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "lock", $id);
}


# Descriptions: return "incoming" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub incoming_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "incoming");
}


# Descriptions: return "incoming" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub incoming_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "incoming", $id);
}


# Descriptions: return "new" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub new_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "new");
}


# Descriptions: return "new" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub new_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "new", $id);
}


# Descriptions: return "active" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub active_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "active");
}


# Descriptions: return "active" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub active_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "active", $id);
}


# Descriptions: return "deferred" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub deferred_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "deferred");
}


# Descriptions: return "deferred" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub deferred_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "deferred", $id);
}


# Descriptions: return "info" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub info_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info");
}


# Descriptions: return "info" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub info_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", $id);
}



# Descriptions: return "sender" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub sender_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "sender");
}


# Descriptions: return "sender" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub sender_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "sender", $id);
}


# Descriptions: return "recipients" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub recipients_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "recipients");
}


# Descriptions: return "recipients" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub recipients_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "recipients", $id);
}


# Descriptions: return "transport" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub transport_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "transport");
}


# Descriptions: return "transport" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub transport_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "transport", $id);
}


# Descriptions: return "strategy" directory path.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub strategy_dir_path
{
    my ($self) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "strategy");
}


# Descriptions: return "strategy" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub strategy_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "strategy", $id);
}


# Descriptions: return local class directory path.
#    Arguments: OBJ($self) STR($class)
# Side Effects: none
# Return Value: STR
sub local_dir_path
{
    my ($self, $class) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    if (defined $dir && defined $class) {
	return File::Spec->catfile($dir, $class);
    }
    else {
	return undef;
    }
}


# Descriptions: return local class file path.
#    Arguments: OBJ($self) STR($class) STR($id)
# Side Effects: none
# Return Value: STR
sub local_file_path
{
    my ($self, $class, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    if (defined $dir && defined $class && defined $id) {
	return File::Spec->catfile($dir, $class, $id);
    }
    else {
	return undef;
    }
}


=head1 LOG

=head2 log()

=head2 get_log_function()

=head2 set_log_function($fp)

=cut


# Descriptions: log interface.
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $s) = @_;
    my $fp = $self->get_log_function();

    my $buf = "qmgr: $s";
    if (defined $fp) {
	eval q{ &$fp($buf);};
	if ($@) {
	    carp($@);
	}
    }
}


# Descriptions: return log function pointer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: CODE
sub get_log_function
{
    my ($self) = @_;

    return( $self->{ _log_function } || undef );
}


# Descriptions: return log function pointer.
#    Arguments: OBJ($self) CODE($fp)
# Side Effects: update $self.
# Return Value: CODE
sub set_log_function
{
    my ($self, $fp) = @_;

    $self->{ _log_function } = $fp || undef;
}


=head1 CLEAN UP GARBAGES

=head2 cleanup()

remove too old incoming queue files.

=cut


# Descriptions: remove too old incoming queue files.
#    Arguments: OBJ($self)
# Side Effects: remove too old incoming queue files.
# Return Value: none
sub cleanup
{
    my ($self) = @_;
    my $dir    = $self->{ _directory } || croak("directory undefined");
    my $limit  = 14*24*3600;

    use DirHandle;
    use File::stat;
    my $incoming_queue_dir = File::Spec->catfile($dir, "incoming");
    my $dh = new DirHandle $incoming_queue_dir;
    if (defined $dh) {
	my ($file, $entry, $stat);
	my $day_limit = time - $limit;

      ENTRY:
	while ($entry = $dh->read()) {
	    next ENTRY if $entry =~ /^\./o;

	    $file = File::Spec->catfile($dir, "incoming", $entry);
	    $stat = stat($file);
	    if ($stat->mtime < $day_limit) {
		$self->log("remove too old incoming queue: qid=$entry");
		unlink $file;
	    }
	}
	$dh->close();
    }
}


=head1 DEBUG

=cut


if ($0 eq __FILE__) {
    my $queue_dir = shift @ARGV;
    my $queue     = new Mail::Delivery::Queue { directory => $queue_dir };
    $queue->set_policy("fair-queue");

    my $fp = sub { print STDERR "LOG> ", @_, "\n"; };
    $queue->set_log_function($fp);

    print "\n1. queue_id = ", $queue->id(), "\n";

    my $ra = $queue->list_all() || [];
    for my $qid (@$ra) {
	$queue->log("wakeup_queue($qid)");
	$queue->wakeup_queue($qid);
    }

    print "\n2. list up active queue in $queue_dir\n";
    $ra = $queue->list() || [];
    for my $q (@$ra) {
	print "\t", $q, "\n";
    }

    print "\n3. list up all queue in $queue_dir\n";
    $ra = $queue->list_all() || [];
    for my $q (@$ra) {
	print "\t", $q, "\n";
    }

    print "\n\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Queue first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
