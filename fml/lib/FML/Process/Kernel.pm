#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.143 2002/11/26 10:27:20 fukachan Exp $
#

package FML::Process::Kernel;

use strict;
use Carp;
use vars qw(@ISA @Tmpfiles $TmpFileCounter);
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
# Side Effects: allocate the current process table on memory
# Return Value: OBJ(FML::Process::Kernel object)
sub new
{
    my ($self, $args) = @_;
    my ($curproc)     = {}; # alloc memory as the struct current_process.
    my ($cfargs)      = {};

    # XXX [CAUTION]
    # XXX MOVE PARSER FROM Process::Switch to HERE
    # XXX

    # 1.1 import variables
    for my $var (qw(program_name)) {
	if (defined $args->{ $var }) {
	    $cfargs->{ $var } = $args->{ $var };
	}
    }

    # 1.2 import XXX_dir variables from /etc/fml/main.cf
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

    # 1.3 import $fml_version
    if (defined $args->{ fml_version }) {
	$cfargs->{ fml_version } = "fml-devel ". $args->{ fml_version };
    }

    # 2.1 speculate $fml_owner_home_dir by the current process uid
    #     XXX we should compare $fml_owner and $< ?
    {
	my $dir = (getpwuid($<))[7];
	$cfargs->{ 'fml_owner_home_dir' } = $dir if defined $dir;
    }


    #
    # 3. create FML::Process::Kernel object
    #
    # 3.1 for more convenience, save the parent configuration
    $curproc->{ main_cf }       = $args->{ main_cf };
    $curproc->{ __parent_args } = $args;

    # 3.2 bind FML::Config object to $curproc
    use FML::Config;
    $curproc->{ config } = new FML::Config $cfargs;

    # 3.3 initialize PCB (Process Control Block)
    use FML::PCB;
    $curproc->{ pcb } = new FML::PCB;

    # 3.4
    # object-ify. bless! bless! bless!
    bless $curproc, $self;

    # 3.5 initialize signal handlers
    $curproc->_signal_init;

    # 3.6 default printing style
    $curproc->_print_init;

    # 4.1 debug. XXX remove this in the future !
    $curproc->__debug_ml_xxx('loaded:');

    if ($args->{ myname } eq 'loader') {
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


# Descriptions: set up default printing style handling
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _print_init
{
    my ($curproc, $args) = @_;
    $curproc->set_print_style( 'text' );
}


# Descriptions: activate scheduler
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub scheduler_init
{
    my ($curproc, $args) = @_;

    use FML::Process::Scheduler;
    my $scheduler = new FML::Process::Scheduler $curproc;
    $curproc->{ scheduler } = $scheduler;
}


# Descriptions: show help and exit here, (ASAP)
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: longjmp() to help
# Return Value: none
sub _trap_help
{
    my ($curproc, $args) = @_;
    my $option = $curproc->command_line_options();

    if (defined $option->{ help } || defined $option->{ h }) {
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
    croak('not call Kernel::prepare()');
}


=head2 lock( [$channel] )

lock the specified channel.
lock a giant lock if the channel is not specified.

=head2 unlock( [$channel] )

unlock the specified channel.
unlock a giant lock if the channel is not specified.

=cut


# Descriptions: lock the channel
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: none
sub lock
{
    my ($curproc, $channel) = @_;
    my $lock_file = '';

    # initialize
    ($channel, $lock_file) = $curproc->_lock_init($channel);

    require File::SimpleLock;
    my $lockobj = new File::SimpleLock;

    my $r = $lockobj->lock( { file => $lock_file } );
    if ($r) {
	my $pcb = $curproc->{ pcb };
	$pcb->set('lock', $channel, $lockobj);
	Log("lock channel=$channel");
    }
    else {
	LogError("cannot lock");
	croak("Error: cannot lock");
    }
}


# Descriptions: unlock the channel
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: none
sub unlock
{
    my ($curproc, $channel) = @_;
    my $lock_file = '';

    # initialize
    ($channel, $lock_file) = $curproc->_lock_init($channel);

    my $pcb     = $curproc->{ pcb };
    my $lockobj = $pcb->get('lock', $channel);

    if (defined $lockobj) {
	my $r = $lockobj->unlock( { file => $lock_file } );
	if ($r) {
	    Log("unlock channel=$channel");
	}
	else {
	    LogError("cannot unlock");
	    croak("Error: cannot unlock");
	}
    }
    else {
	LogError("object undefined, cannot unlock");
	croak("Error: object undefined, cannot unlock");
    }
}


# Descriptions: initialize lock information et.al.
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: mkdir $lock_dir
# Return Value: ARRAY(STR, STR)
sub _lock_init
{
    my ($curproc, $channel) = @_;
    my $config    = $curproc->{ config };
    my $lock_dir  = $config->{ lock_dir };
    my $lock_type = $config->{ lock_type };

    # our lock channel
    $channel ||= 'giantlock';

    # only user "fml" should read lock files.
    unless (-d $lock_dir) {
	$curproc->mkdir($lock_dir, "mode=private");
    }

    use File::Spec;
    my $lock_file = File::Spec->catfile($lock_dir, $channel);

    unless (-f $lock_file) {
	use FileHandle;
	my $fh = new FileHandle $lock_file, "a";
	if (defined $fh) {
	    print $fh "\n";
	    $fh->close if $fh;
	}
    }

    return($channel, $lock_file);
}


=head2 is_event_timeout( $channel )

=head2 get_event_timeout( $channel )

=head2 set_event_timeout( $channel, $time )

=cut


# Descriptions: event sleeping at $channel should be waked up ?
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_event_timeout
{
    my ($curproc, $channel) = @_;
    my $t = $curproc->get_event_timeout($channel);

    if ($t) {
	return (time > $t) ? 1 : 0;
    }
    else {
	LogWarn("visit timeout channel=$channel at the first time");
	return 1;
    }
}


# Descriptions: return the upper time event sleeps at $channel until
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: NUM
sub get_event_timeout
{
    my ($curproc, $channel) = @_;
    my $qf = $curproc->_init_event_timeout($channel);

    if (-f $qf) {
	use FileHandle;
	my $fh = new FileHandle $qf;
	my $t  = $fh->getline(); $t =~ s/\s*//g;

	return $t;
    }
    else {
	return 0;
    }
}


# Descriptions: set the upper time for event sleeps at $channel until
#    Arguments: OBJ($curproc) STR($channel) NUM($time)
# Side Effects: none
# Return Value: NUM
sub set_event_timeout
{
    my ($curproc, $channel, $time) = @_;
    my $qf = $curproc->_init_event_timeout($channel);

    use FileHandle;
    my $wh = new FileHandle "> $qf";
    if (defined $wh) {
	print $wh $time, "\n";
	$wh->close;
    }
}


# Descriptions: utility function to manipulate event sleeping at $channel
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: STR
sub _init_event_timeout
{
    my ($curproc, $channel) = @_;

    my $config = $curproc->config();
    my $dir    = $config->{ event_queue_dir };

    unless (-d $dir) {
	$curproc->mkdir($dir, "mode=private");
    }

    use File::Spec;
    my $qf = File::Spec->catfile($dir, $channel);

    unless (-f $qf) {
	use FileHandle;
	my $wh = new FileHandle ">> $qf";
	print $wh "\n" if defined $wh;
    }

    return $qf;
}


=head2 C<verify_sender_credential($args)>

validate the mail sender (From: in the header not SMTP SENEDER).  If
valid, it sets the adddress within $curproc->{ credential } object as
a side effect.

=cut

# Descriptions: validate the sender address and do a few things
#               as a side effect
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: set the return value of $curproc->sender().
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
	$curproc->stop_this_process("cannot extract From:");
	LogError("cannot extract From:");
    }

    # XXX "@addrs must be empty" is valid since From: is unique.
    unless (@addrs) {
	# XXX o.k. From: is proven to be valid now.
	# XXX log it anyway
	Log("sender: $from");
	use FML::Credential;
	my $cred = new FML::Credential $curproc;
	$curproc->{'credential'} = $cred;
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
    my $header = $curproc->incoming_message_header();
    my $rules  = $config->get_as_array_ref( 'header_loop_check_rules' );
    my $match  = 0;

  RULES:
    for my $rule (@$rules) {
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
	$curproc->stop_this_process();
	Log("mail loop detected for $match");
    }
}


=head2 resolve_ml_specific_variables( $args )

determine ml specific variables
    $ml_name
    $ml_domain
    $ml_home_prefix
    $ml_home_dir
by command line arguments or CGI environment variables
with considering virtual domains.

    Example: "| /usr/local/libexec/fml/distribute elena@fml.org"
             makefml COMMAND elena@fml.org ...
       or in the old style
             "| /usr/local/libexec/fml/fml.pl /var/spool/ml/elena"

=cut


# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects:
# Return Value: none
sub resolve_ml_specific_variables
{
    my ($curproc, $args) = @_;
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
    my ($command, @options, $config_cf_path);
    my $config  = $curproc->{ config };
    my $myname  = $args->{ myname };
    my $ml_addr = '';

    # 1. virtual domain or not ?
    # 1.1 search ml@domain syntax arg in @ARGV
    if ($myname eq 'makefml' || 
	$myname eq 'fmlthread' || 
	$myname eq 'fmlsummary') {
	my $default_domain = $curproc->default_domain();
	($command, $ml_name, @options) = @ARGV;

	# makefml $ml->$command
	if (defined $command && $command =~ /\-\>/) {
	    ($command, @options) = @ARGV;
	    ($ml_name, $command) = split('->', $command);
	}
	# makefml $ml::$command
	elsif (defined $command && $command =~ /::/) {
	    ($command, @options) = @ARGV;
	    ($ml_name, $command) = split('::', $command);
	}

	if (defined $ml_name) {
	    if ($ml_name =~ /\@/) {
		$ml_addr = $ml_name;
	    }
	    else {
		$ml_addr = $ml_name . '@'. $default_domain;
	    }
	}
    }
    else {
	# XXX "fmlconf -n elena@fml.org" works ?
	# XXX yes, but "fmlconf -n elena" works ? no ;-)
	for my $arg (@ARGV) {
	    if ($arg =~ /\S+\@\S+/) { $ml_addr = $arg;}
	}

	# not found. Hmm, "fmlconf -n elena" case ?
	unless ($ml_addr) {
	    my $default_domain = $curproc->default_domain();

	    use FML::Restriction::Base;
	    my $safe    = new FML::Restriction::Base;
	    my $regexp  = $safe->basic_variable();
	    my $pattern = $regexp->{ ml_name };

	  ARGS:
	    for my $arg (@ARGV) {
		last ARGS if $ml_addr;
		next ARGS if $arg =~ /^-/o;

		if ($arg =~ /^($pattern)$/) {
		    $ml_addr = $arg. '@' . $default_domain;
		}
	    }
	}
    }

    # 1.2 ml@domain may be specified in command line args.
    if ($ml_addr) {
	($ml_name, $ml_domain) = split(/\@/, $ml_addr);
	$config->set( 'ml_name',   $ml_name );
	$config->set( 'ml_domain', $ml_domain );

	my $prefix   = $curproc->ml_home_prefix( $ml_domain );
	my $home_dir = $curproc->ml_home_dir( $ml_name, $ml_domain );
	$config->set( 'ml_home_prefix', $prefix );
	$config->set( 'ml_home_dir',    $home_dir );

	$config_cf_path = $curproc->config_cf_filepath($ml_name, $ml_domain);
    }
    # Example: "| /usr/local/libexec/fml/fml.pl /var/spool/ml/elena"
    #    XXX the following code is true if config.cf has $ml_name definition.
    else {
	my $r = $curproc->_find_ml_home_dir_in_argv($args->{ main_cf });

	# determine default $ml_home_dir and $hom_home_prefix by main.cf
	if (defined $r->{ ml_home_dir }) {
	    use File::Basename;
	    my $dir    = $r->{ ml_home_dir };
	    my $prefix = dirname( $dir );
	    $config->set( 'ml_home_prefix', $prefix);
	    $config->set( 'ml_home_dir',    $dir);

	    use File::Spec;
	    $config_cf_path = File::Spec->catfile($dir, "config.cf");
	}

	# parse the argument such as "fml.pl /var/spool/ml/elena ..."
	unless ($ml_name) {
	    Log("(debug) parse @ARGV");

	  ARGS:
	    for my $arg (@ARGV) {
		last ARGS if $ml_addr;
		next ARGS if $arg =~ /^-/o;

		# the first directory name e.g. /var/spool/ml/elena
		if (-d $arg) {
		    my $default_domain = $curproc->default_domain();

		    use File::Basename;
		    $ml_name     = basename( $arg );
		    $ml_home_dir = dirname( $arg );

		    $config->set( 'ml_name',     $ml_name );
		    $config->set( 'ml_domain',   $default_domain );
		    $config->set( 'ml_home_dir', $arg );

		    Log("(debug) ml_name=$ml_name ml_home_dir=$ml_home_dir");
		}
	    }
	}
    }

    # debug
    $curproc->__debug_ml_xxx('resolv:');

    # add this ml's config.cf to the .cf list.
    my $list = $args->{ cf_list };
    push(@$list, $config_cf_path);
}


# XXX remove this in the future
my @delayed_buffer = ();

# Descriptions: debug log. removed in the future
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub __debug_ml_xxx
{
    my ($curproc, $str) = @_;
    my $config = $curproc->{ config };

    if (defined $config->{ log_file } && (-w $config->{ log_file })) {
	for (@delayed_buffer) { Log( $_ ); }
	@delayed_buffer = ();

	for my $var (qw(ml_name ml_domain ml_home_prefix ml_home_dir)) {
	    Log(sprintf("%-25s = %s", '(debug)'.$str. $var,
			(defined $config->{ $var } ? $config->{ $var } : '')));
	}
    }
    else {
	for my $var (qw(ml_name ml_domain ml_home_prefix ml_home_dir)) {
	    push(@delayed_buffer,
		 sprintf("%-25s = %s",
			 '(debug)'.$str. $var,
			 (defined $config->{$var} ? $config->{$var} : '')));
	}
    }
}


# Descriptions: analyze argument vector
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub _find_ml_home_dir_in_argv
{
    my ($curproc, $main_cf) = @_;
    my $ml_home_prefix = $main_cf->{ default_ml_home_prefix };
    my $ml_home_dir    = '';
    my $found_cf       = 0;
    my @cf             = ();

    # "elena" is translated to "/var/spool/ml/elena"
  ARGV:
    for (@ARGV) {
	# 1. for the first time
	#   a) speculate "/var/spool/ml/$_" looks a $ml_home_dir ?
	unless ($found_cf) {
	    my $x  = File::Spec->catfile($ml_home_prefix, $_);
	    my $cf = File::Spec->catfile($x, "config.cf");
	    if (-d $x && -f $cf) {
		$found_cf    = 1;
		$ml_home_dir = $x;
		push(@cf, $cf);
	    }
	}

	last ARGV if $found_cf;

	# 2. /var/spool/ml/elena looks a $ml_home_dir ?
	if (-d $_) {
	    $ml_home_dir = $_;
	    my $cf = File::Spec->catfile($_, "config.cf");
	    if (-f $cf) {
		push(@cf, $cf);
		$found_cf = 1;
	    }
	}
	# 3. looks a file, so /var/spool/ml/elena/config.cf ?
	elsif (-f $_) {
	    push(@cf, $_);
	}
    }

    return {
	ml_home_dir => $ml_home_dir,
	cf_list     => \@cf,
    };
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

    # XXX simple sanity check
    #     MAIL_LIST != MAINTAINER
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };
    my $ml_address = $config->{ address_for_post };

    use FML::Credential;
    my $cred = new FML::Credential $curproc;
    if ($cred->is_same_address($maintainer, $ml_address)) {
	LogError("invalid configuration: \$maintainer == \$address_for_post");
	$curproc->stop_this_process("configuration error");
    }
}


# Descriptions: add ml local library path into @INC
#    Arguments: OBJ($OBJ)
# Side Effects: update @INC
# Return Value: none
sub fix_perl_include_path
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };

    # XXX update @INC here since we should do after loading configurations.
    # update @INC for ml local libraries
    if (defined $config->{ ml_home_dir } &&
	$config->{ ml_home_dir } &&
	defined $config->{ ml_local_lib_dir }) {
	unshift(@INC, $config->{ ml_local_lib_dir });
    }
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
    if ($config->yes('use_incoming_mail_cache')) {
	my $dir     = $config->{ incoming_mail_cache_dir };
	my $modulus = $config->{ incoming_mail_cache_size };
	use File::CacheDir;
        my $obj     = new File::CacheDir {
            directory  => $dir,
	    modulus    => $modulus,
        };

	if (defined $obj) {
	    my $wh = $obj->open();
	    $msg->print($wh) if defined $wh;
	    $obj->close();
	}
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
    my $sender = $cred->sender();

    for my $rule (split(/\s+/, $config->{ "${type}_restrictions" })) {
	if ($rule eq 'reject_system_accounts') {
	    my $match  = $cred->match_system_accounts($sender);
	    if ($match) {
		Log("${rule}: $match matches sender address");
		$pcb->set("check_restrictions", "deny_reason", $rule);
		return 0;
	    }
	}
	elsif ($rule eq 'permit_anyone') {
		return 1;
	}
	elsif ($rule eq 'permit_member_maps') {
	    # Q: the mail sender is a ML member?
	    if ($cred->is_member($sender)) {
		# A: Yes, we permit to distribute this article.
		return 1;
	    }
	    else {
		# A: No, deny distribution
		LogError("$sender is not an ML member");
		LogError( $cred->error() );
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


=head2 stop_this_process($reason)

Set "we should refuse this processing now" flag.
We should stop this process as soon as possible.

=head2 do_nothing($reason)

same as stop_this_process($reason).
dedicated to fml 4.0's C<$DO_NOTHING> variable.

=head2 is_refused()

We should stop this process as soon as possible due to something
invalid conditions by such as filtering.

=cut


# Descriptions: stop further processing since
#               this process looks invalid in some sence.
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub stop_this_process
{
    my ($curproc, $reason) = @_;
    $curproc->{ __this_process_is_invalid } = 1;
}


# Descriptions: synonym of stop_this_process()
#    Arguments: OBJ($curproc) STR($reason)
#      History: dedicated to $DO_NOTHING variable in fml 4.0
# Side Effects: none
# Return Value: NUM(1 or 0)
sub do_nothing
{
    my ($curproc, $reason) = @_;
    $curproc->stop_this_process($reason);
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

=head3 CAUTION
makefml not support message handling not yet.

=cut


sub _analyze_recipients
{
    my ($curproc, $args) = @_;
    my $recipient      = [];
    my $recipient_maps = [];
    my $rcpt = $args->{ recipient }      if defined $args->{ recipient };
    my $map  = $args->{ recipient_map }  if defined $args->{ recipient_map };
    my $maps = $args->{ recipient_maps } if defined $args->{ recipient_maps };

    if (defined($rcpt)) {
	if (ref($rcpt) eq 'ARRAY') {
	    $recipient = $rcpt if @$rcpt;
	}
	elsif (ref($rcpt) eq '') {
	    $recipient = [ $rcpt ] if $rcpt;
	}
	else {
	    LogError("reply_message: wrong type recipient");
	}
    }

    if (defined($map)) {
	if (ref($map) eq '') {
	    $recipient_maps = [ $map ] if $map;
	}
	else {
	    LogError("reply_message: wrong type recipient_map");
	}
    }

    if (defined($maps)) {
	if (ref($maps) eq 'ARRAY') {
	    $recipient_maps = $maps if @$maps;
	}
	else {
	    LogError("reply_message: wrong type recipient_maps");
	}
    }

    # if both specified, use default sender.
    unless (@$recipient || @$recipient_maps) {
	$recipient = [ $curproc->{ credential }->sender() ];
    }

    return ($recipient, $recipient_maps);
}


sub _analyze_header
{
    my ($curproc, $args) = @_;
    return $args->{ header };
}


# Descriptions: set reply message
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub reply_message
{
    my ($curproc, $msg, $args) = @_;
    my $myname = $curproc->myname();

    # XXX makefml not support message handling not yet.
    if ($myname eq 'makefml' || $myname =~ /\.cgi$/ || $myname eq 'error') {
	LogWarn("(debug) $myname disables reply_message()");
	return;
    }

    # recipients list
    my ($recipient, $recipient_maps) = $curproc->_analyze_recipients($args);
    my $hdr                          = $curproc->_analyze_header($args);

    # check text messages and fix if needed.
    unless (ref($msg)) {
	# \n in the last always.
	$msg .= "\n" unless $msg =~ /\n$/;
    }

    $curproc->_append_message_into_queue($msg, $args, 
					 $recipient, $recipient_maps,
					 $hdr);

    if (defined $args->{ always_cc }) {
	# only if $recipient above != always_cc, duplicate $msg message.
	my $sent = $recipient;
	my $cc   = $args->{ always_cc };

	my $recipient = [];
	if (ref($cc) eq 'ARRAY') {
	    $recipient = $cc;
	}
	else {
	    $recipient = [ $cc ];
	}

	if (_array_is_different($sent, $recipient)) {
	    Log("cc: [ @$recipient ]");
	    $curproc->_append_message_into_queue($msg, $args, 
						 $recipient, $recipient_maps,
						 $hdr);
	}
    }
}


# Descriptions: compare two array references
#    Arguments: ARRAY_REF($a) ARRAY_REF($b)
# Side Effects: none
# Return Value: NUM
sub _array_is_different
{
    my ($a, $b) = @_;
    my $diff = 0;
    my $i    = 0;

    # 1. number of array elements differs.
    return 1 if $#$a != $#$b;

    # 2. some elements in arrays differ.
    for ($i = 0; $i <= $#$a ; $i++)  {
	$diff++ if $a->[ $i ] ne $b->[ $i ];
    }

    return $diff;
}


# Descriptions: add the specified $msg into on memory queue
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($args)
#               ARRAY_REF($recipient) ARRAY_REF($recipient_maps)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue
{
    my ($curproc, $msg, $args, $recipient, $recipient_maps, $hdr) = @_;
    my $pcb      = $curproc->{ pcb };
    my $category = 'reply_message';
    my $class    = 'queue';
    my $rarray   = $pcb->get($category, $class) || [];

    $rarray->[ $#$rarray + 1 ] = {
	message        => $msg,
	type           => ref($msg) ? ref($msg) : 'text',
	recipient      => $recipient,
	recipient_maps => $recipient_maps,
	header         => $hdr,
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
    my %rcptmaps = ();
    my %hdr      = ();
    my ($rcptlist, $rcptmaps, $key, $type) = ();

    for my $m (@$rarray) {
	if (defined $m->{ recipient } ) {
	    $rcptlist = $m->{ recipient };
	    $rcptmaps = $m->{ recipient_maps };
	    $type     = ref($m->{ message });
	    $key      = _gen_recipient_key( $rcptlist, $rcptmaps );
	    $rcptattr{ $key }->{ $type }++;
	    $rcptlist{ $key } = $rcptlist;
	    $rcptmaps{ $key } = $rcptmaps;
	    $hdr{ $key }      = $m->{ header };
	}
    }

    return ( \%rcptattr, \%rcptlist, \%rcptmaps, \%hdr );
}


# Descriptions: make a key
#    Arguments: ARRAY_REF($rarray)
# Side Effects: none
# Return Value: STR
sub _gen_recipient_key
{
    my ($rarray, $rmaps) = @_;
    my (@c) = caller;
    my $key = '';

    if (defined $rarray) {
	if (ref($rarray) eq 'ARRAY') {
	    if (@$rarray) {
		$key = join(" ", @$rarray);
	    }
	}
	else {
	    LogError("wrong \$rarray");
	}
    }

    if (defined $rmaps) {
	if (ref($rmaps) eq 'ARRAY') {
	    if (@$rmaps) {
		$key .= " ".join(" ", @$rmaps);
	    }
	}
	else {
	    LogError("wrong \$rmaps");
	}
    }

    return $key;
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


# Descriptions: set reply message with translation to natual language
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub reply_message_nl
{
    my ($curproc, $class, $default_msg, $args) = @_;
    my $config = $curproc->{ config };
    my $buf    = $curproc->message_nl($class, $default_msg, $args);

    if (defined $buf) {
	if ($buf =~ /\$/) {
	    $config->expand_variable_in_buffer(\$buf, $args);
	}

	eval q{
	    use Mail::Message::Encode;
	    my $obj = new Mail::Message::Encode;
	    $curproc->reply_message( $obj->convert( $buf, 'jis-jp' ), $args);
	};
	LogError($@) if $@;
    }
    else {
	$curproc->reply_message($default_msg, $args);
    }
}


# Descriptions: get template message in natual language
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub message_nl
{
    my ($curproc, $class, $default_msg, $args) = @_;
    my $config    = $curproc->{ config };
    my $dir       = $config->{ message_template_dir };
    my $local_dir = $config->{ ml_local_message_template_dir };
    my $charset   = $config->{ template_file_charset } || 'en';
    my $buf       = '';

    use File::Spec;
    $class =~ s@\.@/@g; # XXX replace the first "." only

    my $local_file = File::Spec->catfile($local_dir, $charset, $class);
    my $file       = File::Spec->catfile($dir,       $charset, $class);

    # override message: replace default one with ml local message template
    if (-f $local_file) { $file = $local_file;}

    # import message template
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
    my ($attr, $list, $maps, $hdr) = $curproc->_reply_message_recipient_keys();
    my $need_multipart = 0;

    for my $key (keys %$list) {
	for my $category ('reply_message', 'system_message') {
	    if (defined($pcb->get($category, 'queue'))) {
		# inject messages into message queue
		$curproc->queue_in($category, {
		    recipient_key  => $key,
		    recipient_list => $list->{ $key },
		    recipient_maps => $maps->{ $key },
		    recipient_attr => $attr,
		    header         => $hdr->{ $key },
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
    my $rcptkey      = '';
    my $rcptlist     = [];
    my $rcptmaps     = [];
    my $msg          = '';
    my $hdr_to       = '';

    # override parameters (may be processed here always)
    if (defined $optargs) {
	my $a = $optargs;
	my $h = $optargs->{ header };
	my $c = $optargs->{ header }->{ 'content-type' };

	# override parameters
	$sender    = $h->{'sender'}         if defined $h->{'sender'};
	$subject   = $h->{'subject'}        if defined $h->{'subject'};
	$hdr_to    = $h->{'to'}             if defined $h->{'to'};
	$reply_to  = $h->{'reply-to'}       if defined $h->{'reply-to'};
	$charset   = $c->{'charset'}        if defined $c->{'charset'};
	$rcptkey   = $a->{'recipient_key'}  if defined $a->{'recipient_key'};
	$rcptlist  = $a->{ recipient_list } if defined $a->{'recipient_list'};
	$rcptmaps  = $a->{ recipient_maps } if defined $a->{'recipient_maps'};

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
	$reason = "no sender undefined\n"    unless defined $sender;
	$reason = "no recipient undefined\n" unless defined $rcptkey;
	$reason = "no sender specified\n"    unless $sender;
	$reason = "no recipient specified\n" unless $rcptkey;
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
	my $_to = $hdr_to || $rcptkey;
	eval q{
	    $msg = new Mail::Message::Compose
		From     => $sender,
		To       => $_to,
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
	    my $r = _gen_recipient_key($m->{ recipient }, 
				       $m->{ recipient_maps } );

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
	    my $r = _gen_recipient_key($m->{ recipient }, 
				       $m->{ recipient_maps } );

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
	    my $r = _gen_recipient_key($m->{ recipient },
				       $m->{ recipient_maps });

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

	my $_to = $hdr_to || $rcptkey;
	eval q{
	    $msg = new Mail::Message::Compose
		From     => $sender,
		To       => $_to,
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
	$queue->set('sender', $sender);

	if ($rcptlist) {
	    $queue->set('recipients', $rcptlist);
	}

	# $rcptlist and $rcptmaps duplication is ok.
	if ($rcptmaps) {
	    $queue->set('recipient_maps', $rcptmaps);
	}

	$queue->in( $msg ) && Log("queue=$qid in");
	$queue->setrunnable();

	# return queue object
	return $queue;
    }
    else {
	return undef;
    }
}


# Descriptions: append message in $msg_in into $msg_out
#    Arguments: OBJ($curproc) OBJ($msg_in) OBJ($msg_out)
# Side Effects: create a new $tmpfile
#               update garbage collection queue (clean_up_queue)
# Return Value: none
sub _append_rfc822_message
{
    my ($curproc, $msg_in, $msg_out) = @_;
    my $tmpfile = $curproc->temp_file_path();

    my $wh = new FileHandle "> $tmpfile";
    if (defined $wh) {
	$msg_in->print($wh);
	$wh->close;
    }
    else {
	LogError("_append_rfc822_message: cannot create \$tmpfile");
    }

    if (-f $tmpfile) {
	my $rh = new FileHandle $tmpfile;
	if (defined $rh) {
	    $msg_out->attach(Type     => 'message/rfc822',
			     Path     => $tmpfile,
			     Filename => "original_message",
			     );
	    $rh->close;
	}
	else {
	    LogError("_append_rfc822_message: cannot open \$tmpfile");
	}

	$curproc->add_into_clean_up_queue( $tmpfile );
    }
    else {
	LogError("_append_rfc822_message: \$tmpfile not found");
    }
}


# Descriptions: insert $file into garbage collection queue (clean_up_queue)
#    Arguments: OBJ($curproc) STR($file)
# Side Effects: update $curproc->{ __clean_up_tmpfiles };
# Return Value: none
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


# Descriptions: remove garbage collection queue (clean_up_queue)
#    Arguments: OBJ($curproc)
# Side Effects: remove files in $curproc->{ __clean_up_tmpfiles }
# Return Value: none
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


# Descriptions: return the temporary file path you can use
#    Arguments: OBJ($curproc)
# Side Effects: update the counter to ensure file name uniqueness
# Return Value: STR
sub temp_file_path
{
    my ($curproc) = @_;
    my $config  = $curproc->{ config };
    my $tmp_dir = $config->{ tmp_dir };

    $TmpFileCounter++; # ensure uniqueness

    use File::Spec;
    return File::Spec->catfile( $tmp_dir, "tmp.$$.". time . $TmpFileCounter);
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

    -d $tmp_dir || $curproc->mkdir($tmp_dir, "mode=private");

    use FileHandle;
    my $rh = new FileHandle $src_file;
    my $wh = new FileHandle "> $tmpf";

    if (defined($rh) && defined($wh)) {
	my $obj = undef;
	eval q{
	    use Mail::Message::Encode;
	    $obj = new Mail::Message::Encode;
	};

	if (defined $obj) {
	    while (<$rh>) {
		if (/\$/) { $config->expand_variable_in_buffer(\$_, $args);}
		$wh->print( $obj->convert( $_, 'jis-jp' ) );
	    }
	}
	else {
	    LogError("Mail::Message::Encode object undef");
	}

	close($wh);
	close($rh);
    }

    return (-s $tmpf ? $tmpf : undef);
}


=head1 ERROR HANDLING

=cut


# Descriptions: open cache data area and return file handle to write into it.
#    Arguments: OBJ($curproc) HASH_REF($optargs)
# Side Effects: open cache
# Return Value: HANDLE
sub open_outgoing_message_channel
{
    my ($curproc, $optargs) = @_;
    my $config = $curproc->{ config };

    # save message for further investigation
    if ($config->yes('use_outgoing_mail_cache')) {
	my $dir     = $config->{ outgoing_mail_cache_dir };
	my $modulus = $config->{ outgoing_mail_cache_size };
	use File::CacheDir;
        my $obj     = new File::CacheDir {
            directory  => $dir,
	    modulus    => $modulus,
        };

	if (defined $obj) {
	    return $obj->open();
	}
	else {
	    return undef;
	}
    }

    return undef;
}


=head1 ERROR HANDLING

=cut


# Descriptions: parse exception error message and return (key, reason)
#    Arguments: OBJ($curproc) STR($exception)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
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


# Descriptions: set umask as 000 for public use
#    Arguments: OBJ($curproc)
# Side Effects: update umask
#               save the current umask in PCB
# Return Value: NUM
sub set_umask_as_public
{
    my ($curproc) = @_;
    my $pcb = $curproc->{ pcb };

    # reset umask since html archives should be public open.
    my $saved_umask = umask;
    $pcb->set('umask', 'saved_umask', $saved_umask);
    umask(000);
}


# Descriptions: back to the saved umask in PCB
#    Arguments: OBJ($curproc)
# Side Effects: umask
# Return Value: NUM
sub reset_umask
{
    my ($curproc) = @_;
    my $pcb = $curproc->{ pcb };
    my $saved_umask = $pcb->get('umask', 'saved_umask');

    # back to the original umask;
    umask($saved_umask);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
