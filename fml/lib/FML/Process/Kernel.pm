#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.97 2002/05/21 11:21:47 fukachan Exp $
#

package FML::Process::Kernel;

use strict;
use Carp;
use vars qw(@ISA @Tmpfiles);
use File::Spec;

use FML::Process::Flow;
use FML::Process::Utils;
use FML::Parse;
use FML::Header;
use FML::Config;
use FML::Log qw(Log LogWarn LogError);
use File::SimpleLock;

# for small utilities: fml_version(), myname(), et. al.
push(@ISA, qw(FML::Process::Utils));

my $debug = 0;


=head1 NAME

FML::Process::Kernel - provide fml core functions

=head1 SYNOPSIS

    use FML::Process::Kernel;
    $curproc = new FML::Process::Kernel;
    $curproc->prepare($args);

       ... snip ...

=head1 DESCRIPTION

This modules is the base class of fml processes.
It provides basic core functions.
See L<FML::Process::Flow> on where and how each function is used
in the process flow.

=head1 METHODS

=head2 C<new($args)>

1. import variables such as C<$ml_home_dir> via C<libexec/loader>

2. determine C<$fml_version> for further library loading

3. initialize current process struct C<$curproc> such as

    $curproc->{ main_cf }
    $curproc->{ config }
    $curproc->{ pcb }

For example, this C<main_cf> provides the pointer to /etc/fml/main.cf
parameters.

4. load and evaluate configuration files
   e.g. C</var/spool/ml/elena/config.cf> for C<elena> mailing list.

5. initialize signal handlders

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: FML::Process::Kernel object
sub new
{
    my ($self, $args) = @_;
    my ($curproc)     = {}; # alloc memory as the struct current_process.
    my ($cfargs)      = {};

    # import variables
    my (@import_vars) = qw(ml_home_prefix ml_home_dir program_name);
    my $var;

  IMPORT_CHECK:
    for $var (@import_vars) {
	if (defined $args->{ $var }) {
	    $cfargs->{ $var } = $args->{ $var };
	}
	else {
	    if ($var eq 'ml_home_dir') {
		next IMPORT_CHECK unless $args->{ need_ml_name };
	    }

	    # critical error
	    croak("Error: variable=$var is not defined");
	}
    }

    # error if we need $ml_home_dir but is not specified.
    if ($args->{ need_ml_name }) {
	unless ($cfargs->{ ml_home_dir }) {
	    croak("specify ml_home_dir or ml_name");
	}
    }

    # import XXX_dir variables from /etc/fml/main.cf
    for my $dir_var (qw(
			config_dir
			default_config_dir
			lib_dir
			libexec_dir
			share_dir
			local_lib_dir
			)) {
	if (defined $args->{ main_cf }->{ $dir_var }) {
	    $cfargs->{ 'fml_'.$dir_var } = $args->{ main_cf }->{ $dir_var };
	}
    }

    # speculate $fml_owner_home_dir by the current process uid
    {
	my $dir = (getpwuid($<))[7];
	$cfargs->{ 'fml_owner_home_dir' } = $dir if defined $dir;
    }

    # import $fml_version
    if (defined $args->{ fml_version }) {
	$cfargs->{ fml_version } = "fml-devel ". $args->{ fml_version };
    }

    # for more convenience, save the parent configuration
    $curproc->{ main_cf } = $args->{ main_cf };
    $curproc->{ __parent_args } = $args;

    # bind FML::Config object to $curproc
    use FML::Config;
    $curproc->{ config } = new FML::Config $cfargs;

    # initialize PCB
    use FML::PCB;
    $curproc->{ pcb } = new FML::PCB;

    # object-ify. bless! bless! bless!
    bless $curproc, $self;

    # load config.cf files, which is passed from loader.
    $curproc->load_config_files( $args->{ cf_list } );

    # initialize signal
    $curproc->_signal_init;

    # debug
    if ($0 =~ /loader/) {
	eval q{
	    require Data::Dumper; Data::Dumper->import();
	    print "// FML::Process::Kernel::new()\n";
	    $Data::Dumper::Varname = 'curproc';
	    print Dumper( $curproc );
	    sleep 2;
	    $Data::Dumper::Varname = 'args';
	    print Dumper( $args );
	    sleep 2;
	};
    }

    return $curproc;
}


# Descriptions: set up default signal handling
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _signal_init
{
    my ($curproc, $args) = @_;

    $SIG{'ALRM'} = $SIG{'INT'} = $SIG{'QUIT'} = $SIG{'TERM'} = sub {
	my ($signal) = @_;
	Log("SIG$signal trapped");
	sleep 1;
	croak("SIG$signal trapped");
    };
}


# Descriptions: show help and exit here, (ASAP)
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: longjmp() to help
# Return Value: none
sub _trap_help
{
    my ($curproc, $args) = @_;
    my $option = $curproc->command_line_options();

    if (defined $option->{ help }) {
	print STDERR "FML::Process::Kernel trapped\n" if $debug;
	if ($curproc->can('help')) {
	    $curproc->help();
	}
	exit 0;
    }
}


=head2 C<prepare($args)>

preparation before the main part starts.

It parses the message injected from STDIN to set up
a set of the header and the body object.

=cut

# Descriptions: preliminary works before the main part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: same as parse_incoming_message()
sub prepare
{
    my ($curproc, $args) = @_;
    $curproc->parse_incoming_message($args);
}


=head2 C<lock($args)>

lock the current process.
It is a giant lock now.

=head2 C<unlock($args)>

unlocks the current process.
It is a giant lock now.

=cut


# Descriptions: do a giant lock
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub lock
{
    my ($curproc, $args) = @_;

    # lock information
    my $config    = $curproc->{ config };
    my $lock_dir  = $config->{ lock_dir };
    my $lock_file = $config->{ lock_file };
    my $lock_type = $config->{ lock_type };

    unless (-d $lock_dir) {
	use File::Path;
	mkpath($lock_dir, 0, 0755);
    }

    unless (-f $lock_file) {
	use FileHandle;
	my $fh = new FileHandle $lock_file, "a";
	if (defined $fh) {
	    print $fh "\n";
	    $fh->close if $fh;
	}
    }

    require File::SimpleLock;
    my $lockobj = new File::SimpleLock;

    return 0 unless $lock_file ;
    my $r = $lockobj->lock( { file => $lock_file } );
    if ($r) {
	my $pcb = $curproc->{ pcb };
	$pcb->set('lock', 'object', $lockobj);
	$pcb->set('lock', 'file',   $lock_file);
	Log( "locked $lock_file" );
    }
    else {
	croak("Error: cannot lock");
    }
}


# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects:
# Return Value: none
sub unlock
{
    my ($curproc, $args) = @_;

    my $pcb       = $curproc->{ pcb };
    my $lockobj   = $pcb->get('lock', 'object');
    my $lock_file = $pcb->get('lock', 'file');

    my $r = $lockobj->unlock( { file => $lock_file } );
    if ($r) {
	Log( "unlocked $lock_file");
    }
    else {
	croak("Error: cannot unlock");
    }
}


=head2 C<verify_sender_credential($args)>

verify the mail sender is valid or not.
If valid, it sets the adddress within $curproc->{ credential } object.

=cut

# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects:
# Return Value: none
sub verify_sender_credential
{
    my ($curproc, $args) = @_;
    my $msg  = $curproc->{'incoming_message'};
    my $from = $msg->{'header'}->get('from');

    use Mail::Address;
    my ($addr, @addrs) = Mail::Address->parse($from);

    # extract the first address as a sender.
    if (defined $addr) {
	$from = $addr->address;
	$from =~ s/\n$//o;
    }
    else {
	$curproc->refuse_further_processing("cannot extract From:");
	LogError("cannot extract From:");
    }

    # XXX "@addrs must be empty" is valid since From: is unique.
    unless (@addrs) {
	# XXX o.k. From: is proven to be valid now.
	# XXX log it anyway
	Log("sender: $from");
	use FML::Credential;
	$curproc->{'credential'} = new FML::Credential;
	$curproc->{'credential'}->set( 'sender', $from );
    }
    else {
	LogError("invalid From:");
    }
}


=head2 C<simple_loop_check($args)>

loop checks following rules of $config->{ header_loop_check_rules }.
The autual check is done by header->C<$rule()> for a C<rule>.
See C<FML::Header> object for more details.

=cut


# Descriptions: top level of loop checks
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub simple_loop_check
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $r_msg  = $curproc->{ incoming_message };
    my $header = $r_msg->{ header };
    my $match = 0;

  RULES:
    for my $rule (split(/\s+/, $config->{ header_loop_check_rules })) {
	if ($header->can($rule)) {
	    $match = $header->$rule($config, $args) ? $rule : 0;
	}
	else {
	    Log("header->${rule}() is undefined");
	}

	last RULES if $match;
    }

    if ($match) {
	# we should stop this process ASAP.
	$curproc->refuse_further_processing();
	Log("mail loop detected for $match");
    }
}


=head2 C<load_config_files($files)>

read several configuration C<@$files>.
The variable evaluation (expansion) is done on demand when
$config->get() of FETCH() method is called.

=cut

# Descriptions: load configuration files and evaluate variables
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub load_config_files
{
    my ($curproc, $files) = @_;

    # load configuration variables from given files e.g. /some/where.cf
    # XXX overload variables from each $cf
    for my $cf (@$files) {
      $curproc->{ config }->overload( $cf );
    }

    # XXX We need to expand variables after we load all *cf files.
    # XXX 2001/05/05 changed to dynamic expansion for hook
    # $curproc->{ config }->expand_variables();
}


=head2 C<parse_incoming_message($args)>

C<preapre()> method calls this to
parse the message to a set of header and body.
$curproc->{'incoming_message'} holds the parsed message
which consists of a set of

   $curproc->{'incoming_message'}->{ header }

and

   $curproc->{'incoming_message'}->{ body }.

The C<header> is C<FML::Header> object.
The C<body> is C<Mail::Message> object.

=cut


# Descriptions: parse the message to a set of header and body
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: $curproc->{'incoming_message'} is set up
# Return Value: none
sub parse_incoming_message
{
    my ($curproc, $args) = @_;

    # parse incoming mail to cut off it to the header and the body.
    use FML::Parse;

    # malloc the incoming message on memory.
    # $r_msg is the reference to the memory area.
    my $msg = new FML::Parse $curproc, \*STDIN;

    # store the message to $curproc
    $curproc->{ incoming_message }->{ message } = $msg;
    $curproc->{ incoming_message }->{ header  } = $msg->whole_message_header;
    $curproc->{ incoming_message }->{ body  }   = $msg->whole_message_body;

    # save input message for further investigation
    my $config  = $curproc->{ config };
    if ($config->yes('use_incoming_message_cache')) { 
	my $dir     = $config->{ mail_incoming_dir };
	my $modulus = $config->{ incoming_message_cache_size };
        my $obj     = new File::CacheDir {
            directory  => $dir,
	    modulus    => $modulus,
        };

	my $wh = $obj->open();
	$msg->print($wh);
	$obj->close();
    }
}


=head1 CREDENTIAL

=head2 C<premit_post($args)>

permit posting.
The restriction rules follows the order of C<post_restrictions>.

=head2 C<premit_command($args)>

permit fml command use.
The restriction rules follows the order of C<command_restrictions>.

=cut


# Descriptions: permit this post process
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub permit_post
{
    my ($curproc, $args) = @_;
    $curproc->_check_restrictions($args, 'post');
}


# Descriptions: permit this command process
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub permit_command
{
    my ($curproc, $args) = @_;
    $curproc->_check_restrictions($args, 'command');
}


# Descriptions: permit this $type process based on the rules defined
#               in ${type}_restrictions.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _check_restrictions
{
    my ($curproc, $args, $type) = @_;
    my $config = $curproc->{ config };
    my $cred   = $curproc->{ credential }; # user credential
    my $pcb    = $curproc->{ pcb };

    for my $rule (split(/\s+/, $config->{ "${type}_restrictions" })) {
	if ($rule eq 'reject_system_accounts') {
	    my $match = $cred->match_system_accounts($curproc, $args);
	    if ($match) {
		Log("${rule}: $match matches sender address");
		$pcb->set("check_restrictions", "deny_reason", $rule);
		return 0;
	    }
	}
	elsif ($rule eq 'permit_anyone') {
		return 1;
	}
	elsif ($rule eq 'permit_members_only') {
	    # Q: the mail sender is a ML member?
	    if ($cred->is_member($curproc, $args)) {
		# A: Yes, we permit to distribute this article.
		return 1;
	    }
	    else {
		# A: No, deny distribution
		my $sender = $cred->sender;
		Log("$sender is not a ML member");
		Log( $cred->error() );
		$curproc->reply_message_nl('error.not_member',
					   "you are not a ML member." );
		$curproc->reply_message( "   your address: $sender" );

		$pcb->set("check_restrictions", "deny_reason", $rule);
		return 0;
	    }
	}
	elsif ($rule eq 'permit_commands_for_stranger') {
	    use FML::Command::DataCheck;
	    my $check = new FML::Command::DataCheck;
	    if ($check->find_commands_for_stranger($curproc)) {
		Log("$rule matched. accepted.");
		return 1;
	    }
	}
	elsif ($rule eq 'reject') {
	    $pcb->set("check_restrictions", "deny_reason", $rule);
	    return 0;
	}
	else {
	    LogWarn("unknown rule=$rule");
	}
    }

    # deny by default
    return 0;
}


=head2 refuse_further_processing($reason)

Set "we should refuse this processing now" flag.
We should stop this process as soon as possible.

=head2 is_refused()

We should stop this process as soon as possible due to something
invalid conditions by such as filtering.

=cut


# Descriptions: stop further processing since
#               this process looks invalid in some sence.
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub refuse_further_processing
{
    my ($curproc, $reason) = @_;
    $curproc->{ __this_process_is_invalid } = 1;
}


# Descriptions: inform whether we should stop further processing?
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_refused
{
    my ($curproc, $reason) = @_;

    if (defined $curproc->{ __this_process_is_invalid }) {
	return $curproc->{ __this_process_is_invalid };
    }

    return 0;
}


=head1 MESSAGE HANDLING

=head2 C<reply_message($msg)>

C<reply_message($msg)> holds message C<$msg> sent back to the mail
sender.

To send a plain text,

    reply_message( "message" );

but to attach an image file, please use in the following way:

    reply_message( {
	type        => "image/gif",
	path        => "aaa00123.gif",
	filename    => "logo.gif",
	disposition => "attachment",
    });

If you attach a plain text with the charset = iso-2022-jp,

    reply_message( {
	type        => "text/plain; charset=iso-2022-jp",
	path        => "/etc/fml/main.cf",
	filename    => "main.cf",
	disposition => "main.cf example",
    });

=cut


# Descriptions: set reply message
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub reply_message
{
    my ($curproc, $msg, $args) = @_;
    my $recipient = [ $curproc->{ credential }->sender() ];

    if (defined($args->{recipient})) {
	if (ref($args->{recipient}) eq 'ARRAY') {
	    $recipient = $args->{ recipient };
	}
	elsif (ref($args->{recipient}) eq '') {
	    $recipient = [ $args->{ recipient } ];
	}
    }

    # check text messages and fix if needed.
    unless (ref($msg)) {
	# \n in the last always.
	$msg .= "\n" unless $msg =~ /\n$/;
    }

    $curproc->_append_message_into_queue($msg, $args, $recipient);
}


# Descriptions: add the specified $msg into on memory queue
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($args) ARRAY_REF($recipient)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue
{
    my ($curproc, $msg, $args, $recipient) = @_;
    my $pcb       = $curproc->{ pcb };
    my $category  = 'reply_message';
    my $class     = 'queue';
    my $rarray    = $pcb->get($category, $class) || [];

    $rarray->[ $#$rarray + 1 ] = {
	message   => $msg,
	type      => ref($msg) ? ref($msg) : 'text',
	recipient => $recipient,
    };

    $pcb->set($category, $class, $rarray);
}


# Descriptions: built and return recipient type and list in
#               on memory queue.
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY( HASH_REF, HASH_REF )
sub _reply_message_recipient_keys
{
    my ($curproc, $msg, $args) = @_;
    my $pcb      = $curproc->{ pcb };
    my $category = 'reply_message';
    my $class    = 'queue';
    my $rarray   = $pcb->get($category, $class) || [];
    my %rcptattr = ();
    my %rcptlist = ();
    my ($rcptlist, $key, $type) = ();

    for my $m (@$rarray) {
	if (defined $m->{ recipient } ) {
	    $rcptlist = $m->{ recipient };
	    $type     = ref($m->{ message });
	    $key      = _gen_recipient_key( $rcptlist );
	    $rcptattr{ $key }->{ $type }++;
	    $rcptlist{ $key } = $rcptlist;
	}
    }

    return ( \%rcptattr, \%rcptlist );
}


# Descriptions: make a key
#    Arguments: ARRAY_REF($rarray)
# Side Effects: none
# Return Value: STR
sub _gen_recipient_key
{
    my ($rarray) = @_;

    return join(" ", @$rarray);
}


=head2 C<reply_message_nl($class, $default_msg, $args)>

This is a wrapper for C<reply_message()> with natural language support.
The message in natural language corresponding with C<$class> is sent.
If translation fails, $default_msg, English by default, is used.

We need parameters in some cases.
They are stored in $args if needed.

	$curproc->reply_message_nl('error.not_member',
				   "you are not a ML member.",
				   $args);

This $args is passed through to reply_message().

=cut


sub reply_message_nl
{
    my ($curproc, $class, $default_msg, $args) = @_;
    my $config = $curproc->{ config };
    my $buf = $curproc->message_nl($class, $default_msg, $args);

    if (defined $buf) {
	eval q{
	    use FML::Language::ISO2022JP qw(STR2JIS);
	};
	if ($buf =~ /\$/) {
	    $config->expand_variable_in_buffer(\$buf, $args);
	}
	$curproc->reply_message(STR2JIS( $buf ), $args);
    }
    else {
	$curproc->reply_message($default_msg, $args);
    }
}


sub message_nl
{
    my ($curproc, $class, $default_msg, $args) = @_;
    my $config = $curproc->{ config };
    my $dir    = $config->{ message_template_dir };
    my $buf    = '';

    use File::Spec;
    $class =~ s@\.@/@g; # XXX replace the first "." only
    my $file = File::Spec->catfile($dir, $class);

    if (-f $file) {
	use FileHandle;
	my $fh = new FileHandle $file;
	if (defined $fh) {
	    while (<$fh>) { $buf .= $_;}
	    close($fh);
	}
    }
    else {
	LogWarn("no such file: $file");
    }

    return $buf;
}


=head2 C<inform_reply_messages($args)>

inform the error messages to the sender or maintainer.
C<inform_reply_messages($args)> checks existence of message(s) of the
following category.

   category          description
   ----------------------------------
   reply_message     message sent back to the mail sender
   system_message    message sent to this list maintainer

Prepare the message and queue it in by C<Mail::Delivery::Queue>.

=cut


# Descriptions: msg (message to return to the sender) is either of
#               text/plain if only "text" is defined.
#               msg = header + get(message, text)
#                      OR
#               multipart/mixed if both "text" and "queue" is defined.
#               $r  = get(message, queue)
#               msg = header + "text" + $r->[0] + $r->[1] + ...
#
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects:
# Return Value: none
sub inform_reply_messages
{
    my ($curproc, $args) = @_;
    my $pcb = $curproc->{ pcb };

    # We should classify reply messages by
    # a set of ( category,  recipient(s) , + more ? what ??? );
    # Hmm, it is better to sort message by
    #    1. recipients
    #    2. pick up messages for it/them.
    #       merge messages by types if needed.
    #
    my ($attr, $list)  = $curproc->_reply_message_recipient_keys();
    my $need_multipart = 0;

    for my $key (keys %$list) {
	for my $category ('reply_message', 'system_message') {
	    if (defined($pcb->get($category, 'queue'))) {
		# inject messages into message queue
		$curproc->queue_in($category, {
		    recipient_key  => $key,
		    recipient_list => $list->{ $key },
		    recipient_attr => $attr,
		});
	    }
	}
    }
}


=head2 C<queue_in($category, $optargs)>

=cut


# Descriptions: queue in. queueing only not delivered.
#    Arguments: OBJ($curproc) STR($category) HASH_REF($optargs)
# Side Effects: add message into queue
# Return Value: OBJ(queue object)
sub queue_in
{
    my ($curproc, $category, $optargs) = @_;
    my $pcb          = $curproc->{ pcb };
    my $config       = $curproc->{ config };
    my $sender       = $config->{ maintainer };
    my $charset      = $config->{ "${category}_charset" } || 'us-ascii';
    my $subject      = $config->{ "${category}_subject" };
    my $reply_to     = $config->{ address_for_command };
    my $is_multipart = 0;
    my $rcptkey    = '';
    my $rcptlist     = [];
    my $msg          = '';

    # override parameters (may be processed here always)
    if (defined $optargs) {
	my $a = $optargs;

	# override parameters
	$sender    = $a->{'sender'}         if defined $a->{'sender'};
	$charset   = $a->{'charset'}        if defined $a->{'charset'};
	$subject   = $a->{'subject'}        if defined $a->{'subject'};
	$rcptkey   = $a->{'recipient_key'}  if defined $a->{'recipient_key'};
	$rcptlist  = $a->{ recipient_list } if defined $a->{'recipient_list'};

	# we need multipart style or not ?
	if (defined $a->{'recipient_attr'}) {
	    my $attr  = $a->{ recipient_attr }->{ $rcptkey };

	    # count up non text message in the queue
	    for my $attr (keys %$attr) {
		$is_multipart++ if $attr;
	    }
	}
    }

    # default recipient if undefined.
    unless ($rcptkey) {
	if (defined $curproc->{ credential }) {
	    $rcptkey = $curproc->{ credential }->sender();
	}
    }

    # cheap sanity check
    unless ($sender && $rcptkey) {
	my $reason = '';
	$reason = "no sender specified\n"    unless defined $sender;
	$reason = "no recipient specified\n" unless defined $rcptkey;
	croak("panic: queue_in()\n\treason: $reason\n");
    }


    Log("debug: queue_in: sender=$sender");
    Log("debug: queue_in: recipient=$rcptkey");
    Log("debug: queue_in: rcptlist=[ @$rcptlist ]");
    Log("debug: queue_in: is_multipart=$is_multipart");


    ###############################################################
    #
    # start building a message
    #
    eval q{
	use Mail::Message::Compose;
    };
    croak($@) if $@;

    if ($is_multipart) {
	eval q{
	    $msg = new Mail::Message::Compose
		From     => $sender,
		To       => $rcptkey,
		Subject  => $subject,
		Type     => "multipart/mixed";
	};
	$msg->add('Reply-To' => $reply_to);
	_add_info_on_header($config, $msg);

	my $mesg_queue = $pcb->get($category, 'queue');
	my $s = '';

      QUEUE:
	for my $m ( @$mesg_queue ) {
	    my $q = $m->{ message };
	    my $t = $m->{ type };
	    my $r = _gen_recipient_key( $m->{ recipient } );

	    # pick up only messages returned to specified $rcptkey
	    next QUEUE unless $r eq $rcptkey;

	    if ($t eq 'text') {
		$s .= $q;
	    }
	}

	# 1. eat up text messages and put it into the first part.
	if ($s) {
	    $msg->attach(Type => "text/plain; charset=$charset",
			 Data => $s,
			 );
	}

	# 2. pick up non text parts after the second part.
	# pick up only messages returned to specified $rcptkey
      QUEUE:
	for my $m ( @$mesg_queue ) {
	    my $q = $m->{ message };
	    my $t = $m->{ type };
	    my $r = _gen_recipient_key( $m->{ recipient } );

	    next QUEUE unless $r eq $rcptkey;

	    if ($t eq 'Mail::Message') {
		$curproc->_append_rfc822_message($q, $msg);
	    }
	    else {
		unless ($t eq 'text') {
		    $msg->attach(Type        => $q->{ type },
				 Path        => $q->{ path },
				 Filename    => $q->{ filename },
				 Disposition => $q->{ disposition });
		}
		else {
		    # Log("queue_in: type=<$t> aggregated") if $t eq 'text';
		    Log("queue_in: unknown type=<$t>") unless $t eq 'text';
		}
	    }
	}
    }
    # text/plain format message (by default).
    else {
	my $mesg_queue = $pcb->get($category, 'queue');
	my $s = '';

	# pick up only messages returned to specified $rcptkey
      QUEUE:
	for my $m ( @$mesg_queue ) {
	    my $q = $m->{ message };
	    my $t = $m->{ type };
	    my $r = _gen_recipient_key( $m->{ recipient } );

	    next QUEUE unless $r eq $rcptkey;

	    if ($t eq 'Mail::Message') {
		$curproc->_append_rfc822_message($q, $msg);
	    }
	    else {
		if ($t eq 'text') {
		    $s .= $q;
		}
		else {
		    Log("queue_in: unknown typ $t");
		}
	    }
	}

	eval q{
	    $msg = new Mail::Message::Compose
		From     => $sender,
		To       => $rcptkey,
		Subject  => $subject,
		Data     => $s,
	};
	$msg->attr('content-type.charset' => $charset);
	$msg->add('Reply-To' => $reply_to);
	_add_info_on_header($config, $msg);
    }


    ###############################################################
    #
    # queue in (not flush queue here)
    #
    my ($queue_dir, $queue, $qid) = (undef, undef, undef);
    eval q{
	use Mail::Delivery::Queue;
	$queue_dir = $config->{ mail_queue_dir };
	$queue     = new Mail::Delivery::Queue { directory => $queue_dir };
	$qid       = $queue->id();
    };

    if (defined $queue) {
	$queue->set('sender',     $sender);
	$queue->set('recipients', $rcptlist);
	$queue->in( $msg ) && Log("queue=$qid in");
	$queue->setrunnable();

	# return queue object
	return $queue;
    }
    else {
	return undef;
    }
}


sub _append_rfc822_message
{
    my ($curproc, $msg_in, $msg_out) = @_;
    my $tmpfile = $curproc->temp_file_path();

    my $wh = new FileHandle "> $tmpfile";
    $msg_in->print($wh);
    $wh->close;

    my $rh = new FileHandle $tmpfile;
    $msg_out->attach(Type     => 'message/rfc822',
		     Path     => $tmpfile,
		     Filename => "original_message",
		     );
    $rh->close;

    $curproc->add_into_clean_up_queue( $tmpfile );
}


sub add_into_clean_up_queue
{
    my ($curproc, $file) = @_;
    my $queue = $curproc->{ __clean_up_tmpfiles };

    if (defined $queue) {
	push(@$queue, $file);
    }
    else {
	$curproc->{ __clean_up_tmpfiles } = [ $file ];
    }
}


sub clean_up_tmpfiles
{
    my ($curproc) = @_;
    my $queue = $curproc->{ __clean_up_tmpfiles };

    if (defined $queue) {
	for my $q (@$queue) {
	    Log("unlink $q") if $debug;
	    unlink $q;
	}
    }
}


sub temp_file_path
{
    my ($curproc) = @_;
    my $config  = $curproc->{ config };
    my $tmp_dir = $config->{ tmp_dir };

    use File::Spec;
    return File::Spec->catfile( $tmp_dir, "tmp.$$.". time );
}


# Descriptions: add some info into header
#    Arguments: OBJ($config) OBJ($msg)
# Side Effects: none
# Return Value: none
sub _add_info_on_header
{
    my ($config, $msg) = @_;
    my $ml_name = $config->{ "ml_name" };
    my $version = $config->{ "fml_version" };

    $msg->attr('X-ML-Name' => $ml_name);

    use FML::Header;
    my $args = {
	type    => 'MIME::Lite',
	message => $msg,
    };
  FML::Header->add_software_info($config, $args);
  FML::Header->add_rfc2369($config, $args);
}


=head2 C<queue_flush($queue)>

flush all queue.

C<TODO:>
   flush C<$queue>, that is, send mail specified by C<$queue>.

=cut


# Descriptions: flush all queue.
#    Arguments: OBJ($curproc) OBJ($queue)
# Side Effects: none
# Return Value: none
sub queue_flush
{
    my ($curproc, $queue) = @_;
    my $config    = $curproc->{ config };
    my $queue_dir = $config->{ mail_queue_dir };

    eval q{
	use FML::Process::QueueManager;
	my $obj = new FML::Process::QueueManager { directory => $queue_dir };
	$obj->send($curproc);
    };
    croak($@) if $@;
}


=head2 C<expand_variables_in_file>

expand $xxx variables in template (e.g. $help_file).  return file name
string, which is a new template converted by this routine.

For example, it expands

        welcome to $ml_name ML

to
        welcome to elena ML

C<Caution:>
   We need to convert charset of the specified file in some language.
   For example, Japanese message is ISO-2022-JP but programs love euc-jp
   since it is easy to use euc-jp.

=cut


# Descriptions: expand $xxx variables in template (e.g. $help_file).
#               1. in Japanese case, convert kanji code: iso-2022-jp -> euc
#               2. expand variables: $ml_name -> elena
#               3. back kanji code: euc -> iso-2022-jp
#               4. return the new created template
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: a new filepath (string) to be prepared
sub prepare_file_to_return
{
    my ($curproc, $args) = @_;
    my $config      = $curproc->{ config };
    my $tmp_dir     = $config->{ tmp_dir };
    my $tmpf        = File::Spec->catfile($tmp_dir, $$);
    my $src_file    = $args->{ src };
    my $charset_out = $args->{ charset };

    -d $tmp_dir || mkdir $tmp_dir, 0755;

    use FileHandle;
    my $rh = new FileHandle $src_file;
    my $wh = new FileHandle "> $tmpf";

    if (defined($rh) && defined($wh)) {
	eval q{ use FML::Language::ISO2022JP qw(STR2JIS);};
	while (<$rh>) {
	    if (/\$/) { $config->expand_variable_in_buffer(\$_, $args);}
	    $wh->print(STR2JIS($_));
	}
	close($wh);
	close($rh);
    }

    return (-s $tmpf ? $tmpf : undef);
}


=head1 ERROR HANDLING

=cut


sub parse_exception
{
    my ($curproc, $exception) = @_;
    my $key = '';
    my $reason = '';

    if ($exception =~ /__ERROR_(\S+)__:\s+(.*)/) {
	($key, $reason) = ($1, $2);
    }

    return ($key, $reason);
}


=head1 MISCELLANEOUS METHODS

=cut


sub set_umask_as_public
{
    my ($curproc) = @_;
    my $pcb = $curproc->{ pcb };

    # reset umask since html archives should be public open.
    my $saved_umask = umask;
    $pcb->set('umask', 'saved_umask', $saved_umask);
    umask(000);
}


sub reset_umask
{
    my ($curproc) = @_;
    my $pcb = $curproc->{ pcb };
    my $saved_umask = $pcb->get('umask', 'saved_umask');

    # back to the original umask;
    umask($saved_umask);
}


=head2 C<load_module($args, $module)>

load model dependent module.
return the object for C<$module>.

=cut


# Descriptions: load module
#    Arguments: OBJ($curpros) HASH_REF($args) STR($pkg)
# Side Effects: load module
# Return Value: OBJ
sub load_module
{
    my ($curproc, $args, $pkg) = @_;

    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	return $pkg->new($curproc, $args);
    }
    else {
	Log($@);
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
