#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.62 2001/11/25 05:15:37 fukachan Exp $
#

package FML::Process::Kernel;

use strict;
use Carp;
use vars qw(@ISA);

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

use FML::Process::Flow;
use FML::Process::Utils;
use FML::Parse;
use FML::Header;
use FML::Config;
use FML::Log qw(Log LogWarn LogError);
use File::SimpleLock;
use FML::Messages;

# for small utilities: fml_version(), myname(), et. al.
push(@ISA, qw(FML::Process::Utils));

# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: none
# Return Value: FML::Process::Kernel object
sub new
{
    my ($self, $args)    = @_;
    my ($curproc) = {}; # alloc memory as the struct current_process.
    my ($cfargs)  = {};

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
    for my $dir_var (qw(lib_dir libexec_dir share_dir)) {
	if (defined $args->{ main_cf }->{ $dir_var }) {
	    $cfargs->{ 'fml_'.$dir_var } = $args->{ main_cf }->{ $dir_var };
	}
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
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub _signal_init
{
    my ($curproc, $args) = @_;

    $SIG{'ALRM'} = $SIG{'INT'}  = $SIG{'QUIT'} = $SIG{'TERM'} = sub {
	my ($signal) = @_;
	Log("SIG$signal trapped");
	sleep 1;
	croak("SIG$signal trapped");
    };
}


# Descriptions: show help and exit here, (ASAP)
#    Arguments: $self $args
# Side Effects: longjmp() to help
# Return Value: none
sub _trap_help
{
    my ($curproc, $args) = @_;
    my $option = $curproc->command_line_options();

    if (defined $option->{ help }) {
	print STDERR "FML::Process::Kernel trapped\n" if defined $ENV{'debug'};
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
#    Arguments: $self $args
# Side Effects: none
# Return Value: same as parse_incoming_message()
sub prepare
{
    my ($curproc, $args) = @_;
    $curproc->parse_incoming_message($args);
}


=head2 C<lock($args)>

locks the current process.
It is a giant lock now.

=head2 C<unlock($args)>

unlocks the current process.
It is a giant lock now.

=cut

# Descriptions:
#    Arguments: $self $args
# Side Effects:
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
#    Arguments: $self $args
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
	croak("Error: cannot lock");
    }
}


=head2 C<verify_sender_credential($args)>

verify the mail sender is valid or not.
If valid, it sets the adddress within $curproc->{ credential } object.

=cut

# Descriptions:
#    Arguments: $self $args
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
    $from = $addr->address;
    $from =~ s/\n$//o;

    # XXX "@addrs must be empty" is valid.
    unless (@addrs) {
	# XXX o.k. From: is proven to be valid now.
	# XXX log it anyway
	Log("sender: $from");
	use FML::Credential;
	$curproc->{'credential'} = new FML::Credential;
	$curproc->{'credential'}->set( 'sender', $from );
    }
    else {
	Log("invalid From:");
    }
}


=head2 C<simple_loop_check($args)>

loop checks following rules of $config->{ header_loop_check_rules }.
The autual check is done by header->C<$rule()> for a C<rule>.
See C<FML::Header> object for more details.

=cut

# Descriptions: top level of loop checks
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub simple_loop_check
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $r_msg  = $curproc->{ incoming_message };
    my $header = $r_msg->{ header };
    my $match = 0;

    for my $rule (split(/\s+/, $config->{ header_loop_check_rules })) {
	if ($header->can($rule)) {
	    $match = $header->$rule($config, $args) ? $rule : 0;
	}
	else {
	    Log("header->${rule}() is undefined");
	}

	last if $match;
    }

    if ($match) {
	Log("mail loop detected for $match");
    }
}


=head2 C<load_config_files($files)>

read several configuration C<@$files>.
The variable evaluation (expansion) is done on demand when
$config->get() of FETCH() method is called.

=cut

# Descriptions: load configuration files and evaluate variables
#    Arguments: $self $args
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
#    Arguments: $self $args
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
    $curproc->{ incoming_message }->{ header  } = $msg->rfc822_message_header;
    $curproc->{ incoming_message }->{ body  }   = $msg->rfc822_message_body;
}


=head1 CREDENTIAL

=head2 C<premit_post($args)>

permit posting.
The restriction rules follows the order of C<post_restrictions>.

=head2 C<premit_command($args)>

permit fml command use.
The restriction rules follows the order of C<command_restrictions>.

=cut


sub permit_post
{
    my ($curproc, $args) = @_;
    $curproc->_check_resitrictions($args, 'post');
}

sub permit_command
{
    my ($curproc, $args) = @_;
    $curproc->_check_resitrictions($args, 'command');
}

sub _check_resitrictions
{
    my ($curproc, $args, $type) = @_;
    my $config = $curproc->{ config };
    my $cred   = $curproc->{ credential }; # user credential

    for my $rule (split(/\s+/, $config->{ "${type}_restrictions" })) {
	if ($rule eq 'reject_system_accounts') {
	    my $match = $cred->match_system_accounts($curproc, $args);
	    if ($match) {
		Log("${rule}: $match matches sender address");
		return 0;
	    }
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
		$curproc->reply_message_nl('kern.not_member',
					   "you are not a ML member." );
		$curproc->reply_message( "   your address: $sender" );
	    }
	}
	elsif ($rule eq 'reject') {
	    return 0;
	}
	else {
	    LogWarn("unknown rule=$rule");
	}
    }
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

sub reply_message
{
    my ($curproc, $msg) = @_;
    my $pcb      = $curproc->{ pcb };
    my $category = 'reply_message';

    if (ref($msg) eq 'HASH') {
	my $rarray = $pcb->get($category, 'queue') || [];
	$rarray->[ $#$rarray + 1 ] = $msg;
	$pcb->set($category, 'queue', $rarray);
    }
    # XXX treat $msg string in separete way.
    # XXX collect all text messages at one special area by default.
    else {
	my $msg0 = $pcb->get($category, 'text') || undef;
	$msg    .= "\n" unless $msg =~ /\n$/;
	$pcb->set($category, 'text', $msg0.$msg);
    }
}


=head2 C<reply_message_nl($class, $default_msg, $args)>

This is a wrapper for C<reply_message()> with natural language support.
The message in natural language corresponding with C<$class> is sent.
If translation fails, $default_msg, English by default, is used.

We need parameters in some cases. 
They are stored in $args if needed.

	$curproc->reply_message_nl('kern.not_member',
				   "you are not a ML member." );
=cut


sub reply_message_nl
{
    my ($curproc, $class, $default_msg, $args) = @_;
    my $config = $curproc->{ config };
    my $dir    = $config->{ message_message_dir };
    my $buf    = '';

    use File::Spec;
    $class =~ s@\.@/@; # XXX replace the first "." only
    my $file = File::Spec->catfile($dir, $class);

    if (-f $file) {
	use FileHandle;
	my $fh = new FileHandle $file;
	if (defined $fh) {
	    while (<$fh>) { $buf .= $_;}
	    close($fh);
	}
    }

    if (defined $buf) {
	use FML::Language::ISO2022JP qw(STR2JIS);
	if ($buf =~ /\$/) { 
	    $config->expand_variable_in_buffer(\$buf, $args);
	}
	$curproc->reply_message( STR2JIS( $buf ) );
    }
    else {
	$curproc->reply_message($default_msg);
    }
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
#    Arguments: $self $args
# Side Effects:
# Return Value: none
sub inform_reply_messages
{
    my ($curproc, $args) = @_;
    my $pcb = $curproc->{ pcb };

    # inject message string to queue in
    for my $category ('reply_message', 'system_message') {
	if (defined($pcb->get($category, 'text')) ||
	    defined($pcb->get($category, 'queue') )) {
	    $curproc->queue_in($category);
	}
    }
}


=head2 C<queue_in($category, $optargs)>

=cut


sub queue_in
{
    my ($curproc, $category, $optargs) = @_;
    my $config       = $curproc->{ config };

    # default values
    my $sender       = $config->{ maintainer };
    my $charset      = $config->{ "${category}_charset" } || 'us-ascii';
    my $subject      = $config->{ "${category}_subject" };
    my $recipient    = undef; # by default. used as sanity check later

    if (defined $curproc->{ credential }) {
	$recipient = $curproc->{ credential }->sender();
    }

    # overwrite
    if (defined $optargs) {
	$sender    = $optargs->{'sender'}    if defined $optargs->{'sender'};
	$charset   = $optargs->{'charset'}   if defined $optargs->{'charset'};
	$subject   = $optargs->{'subject'}   if defined $optargs->{'subject'};
	$recipient = $optargs->{'recipient'} if defined $optargs->{'recipient'};
    }

    # cheap sanity check
    unless (defined($sender) && defined($recipient)) {
	my $reason = '';
	use Carp;
	$reason = "no sender specified\n"    unless defined $sender;
	$reason = "no recipient specified\n" unless defined $recipient;
	croak("panic: queue_in()\n\treason: $reason\n");
    }


    #
    # start building a message
    #
    use Mail::Message::Compose;

    my $pcb          = $curproc->{ pcb };
    my $string       = $pcb->get($category, 'text') || undef;
    my $is_multipart = $pcb->get($category, 'queue') ? 1 : 0;
    my $msg;

    if ($is_multipart) {
	$msg = new Mail::Message::Compose
	    From    => $sender,
	    To      => $recipient,
	    Subject => $subject,
	    Type    => "multipart/mixed";

	_add_info_on_header($config, $msg);

	if (defined $string) {
	    $msg->attach(Type => "text/plain; charset=$charset",
			 Data => $string,
			 );
	}

	my $a = $pcb->get($category, 'queue');
	for my $q ( @$a ) {
	    $msg->attach(Type        => $q->{ type },
			 Path        => $q->{ path },
			 Filename    => $q->{ filename },
			 Disposition => $q->{ disposition });
	}
    }
    # text/plain format message (by default).
    else {
	$msg = new Mail::Message::Compose
	    From    => $sender,
	    To      => $recipient,
	    Subject => $subject,
	    Data    => $string;
	$msg->attr('content-type.charset' => $charset);
	_add_info_on_header($config, $msg);
    }

    use Mail::Delivery::Queue;
    my $queue_dir = $config->{ mqueue_dir };
    my $queue     = new Mail::Delivery::Queue { directory => $queue_dir };
    my $qid       = $queue->id();

    $queue->set('sender',     $sender);
    $queue->set('recipients', [ $recipient ]);
    $queue->in( $msg ) && Log("queue=$qid in");
    $queue->setrunnable();

    # return queue object
    return $queue;
}


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

sub queue_flush
{
    my ($curproc, $queue) = @_;
    my $config    = $curproc->{ config };
    my $queue_dir = $config->{ mqueue_dir };

    use FML::Process::QueueManager;
    my $obj = new FML::Process::QueueManager { directory => $queue_dir };
    $obj->send($curproc);
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
#    Arguments: $self $filename_string $args
# Side Effects: none
# Return Value: a new filepath (string) to be prepared
sub prepare_file_to_return
{
    my ($curproc, $args) = @_;
    my $config      = $curproc->{ config };
    my $tmp_dir     = $config->{ tmp_dir };
    my $tmpf        = "$tmp_dir/$$";
    my $src_file    = $args->{ src };
    my $charset_out = $args->{ charset };

    -d $tmp_dir || mkdir $tmp_dir, 0755;

    use FileHandle;
    my $rh = new FileHandle $src_file;
    my $wh = new FileHandle "> $tmpf"; 

    use FML::Language::ISO2022JP qw(STR2JIS);
    if (defined($rh) && defined($wh)) {
	while (<$rh>) {
	    if (/\$/) { $config->expand_variable_in_buffer(\$_, $args);}
	    $wh->print(STR2JIS($_));
	}
	close($wh);
	close($rh);
    }

    return (-s $tmpf ? $tmpf : undef);
}


=head1 MISCELLANEOUS METHODS

=head2 C<load_module($args, $module)>

load model dependent module.
return the object for C<$module>.

=cut

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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
