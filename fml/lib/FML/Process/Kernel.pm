#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.206 2004/01/14 13:39:58 fukachan Exp $
#

package FML::Process::Kernel;

use strict;
use Carp;
use vars qw(@ISA @Tmpfiles $TmpFileCounter %LockInfo);
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

=head2 new($args)

1. import variables such as C<$ml_home_dir> via C<libexec/loader>

2. determine C<$fml_version> for further library loading

3. initialize current process struct C<$curproc> such as

    $curproc->{ main_cf }
    $curproc->config()
    $curproc->pcb()

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

    # 1.2 import XXX_dir variables as fml_XXX_dir from /etc/fml/main.cf.
    #     ( *_dir *_maps *_cf ).
    for my $main_cf_var (qw(
			    config_dir
			    default_config_dir
			    lib_dir
			    libexec_dir
			    share_dir
			    local_lib_dir

			    default_ml_home_prefix

			    primary_ml_home_prefix_map
			    ml_home_prefix_maps
			    default_config_cf
			    site_default_config_cf

			)) {
	if (defined $args->{ main_cf }->{ $main_cf_var }) {
	    my $key = sprintf("fml_%s", $main_cf_var);
	    $cfargs->{ $key } = $args->{ main_cf }->{ $main_cf_var };
	}
    }

    # 1.3 import $fml_version
    if (defined $args->{ fml_version }) {
	$cfargs->{ fml_version } =
	    sprintf("fml-devel %s", $args->{ fml_version });
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

    # 3.7 set up message queue for logging. (moved to each program)
    # $curproc->_log_message_init();

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
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _signal_init
{
    my ($curproc) = @_;

    $SIG{'ALRM'} = $SIG{'INT'} = $SIG{'QUIT'} = $SIG{'TERM'} = sub {
	my ($signal) = @_;
	$curproc->log("SIG$signal trapped");
	sleep 1;
	croak("SIG$signal trapped");
    };
}


# Descriptions: set up default printing style handling
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _print_init
{
    my ($curproc) = @_;
    $curproc->set_print_style( 'text' );
}


# Descriptions: activate scheduler
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub scheduler_init
{
    my ($curproc) = @_;

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


=head2 prepare($args)

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
    my $pcb       = $curproc->pcb();
    my $lock_file = '';
    my $time_in   = time;

    if (defined $LockInfo{ $channel } && $LockInfo{ $channel }) {
	my @c = caller;
	$curproc->logwarn( "channel=$channel already locked ($c[0] $c[1])" );
	return;
    }

    # initialize
    ($channel, $lock_file) = $curproc->_lock_init($channel);

    require File::SimpleLock;
    my $lockobj = $pcb->get('lock', $channel) || new File::SimpleLock;

    my $r = $lockobj->lock( { file => $lock_file } );
    if ($r) {
	my $t = time - $time_in;
	if ($t > 1) {
	    $curproc->log("lock requires $t sec.");
	}

	$pcb->set('lock', $channel, $lockobj);
	$LockInfo{ $channel } = 1;
	$curproc->log("lock channel=$channel");
    }
    else {
	$curproc->logerror("cannot lock");
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
    my $time_in   = time;

    # initialize
    ($channel, $lock_file) = $curproc->_lock_init($channel);

    my $pcb     = $curproc->pcb();
    my $lockobj = $pcb->get('lock', $channel);

    if (defined $lockobj) {
	my $r = $lockobj->unlock( { file => $lock_file } );
	if ($r) {
	    my $t = time - $time_in;
	    if ($t > 1) {
		$curproc->log("unlock requires $t sec.");
	    }

	    delete $LockInfo{ $channel };
	    $curproc->log("unlock channel=$channel");
	}
	else {
	    $curproc->logerror("cannot unlock");
	    croak("Error: cannot unlock");
	}
    }
    else {
	$curproc->logerror("object undefined, cannot unlock");
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
    my $config    = $curproc->config();
    my $home_dir  = $config->{ ml_home_dir };
    my $lock_dir  = $config->{ lock_dir };
    my $lock_type = $config->{ lock_type };

    # our lock channel
    $channel ||= 'giantlock';

    unless (-d $home_dir) {
	croak("cannot lock: \$ml_home_dir not exists");
    }

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
	    $fh->close;
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
	$curproc->logwarn("visit timeout channel=$channel at the first time");
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
	my $t  = $fh->getline();
	$t =~ s/\s*//g;

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
	if (defined $wh) {
	    print $wh "\n";
	    $wh->close;
	}
    }

    return $qf;
}


=head2 verify_sender_credential($args)

validate the mail sender (From: in the header not SMTP SENEDER).  If
valid, it sets the adddress within $curproc->{ credential } object as
a side effect.

=cut

# Descriptions: validate the sender address and do a few things
#               as a side effect
#    Arguments: OBJ($curproc)
# Side Effects: set the return value of $curproc->sender().
#               stop the current process if needed.
# Return Value: none
sub verify_sender_credential
{
    my ($curproc) = @_;
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
	$curproc->logerror("cannot extract From:");
    }

    # XXX "@addrs must be empty" is valid since From: is unique.
    if (@addrs) {
	$curproc->logwarn("invalid From: duplicated addresses");
	$curproc->logwarn("use $from as the sender");
	my $i = 0;
	for my $a ($addr, @addrs) {
	    my $s = $a->address;
	    ++$i;
	    $curproc->logwarn("From[$i] $s");
	}
    }

    if ($from) {
	$curproc->log("sender: $from");

	# check $from should match safe address regexp.
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	if ($safe->regexp_match('address', $from)) {
	    # o.k. From: is proven to be valid now.
	    use FML::Credential;
	    my $cred = new FML::Credential $curproc;
	    $curproc->{'credential'} = $cred;
	    $curproc->{'credential'}->set( 'sender', $from );
	}
	else {
	    $curproc->stop_this_process();
	    $curproc->logerror("unsafe From: $from");
	}
    }
    else {
	$curproc->stop_this_process();
	$curproc->logerror("no valid From:");
    }
}


=head2 simple_loop_check($args)

loop checks following rules of $config->{ incoming_mail_header_loop_check_rules }.
The autual check is done by header->C<$rule()> for a C<rule>.
See C<FML::Header> object for more details.

=cut


# Descriptions: top level dispatcher for simple loop checks
#    Arguments: OBJ($curproc)
# Side Effects: stop the current process if needed.
# Return Value: none
sub simple_loop_check
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $header    = $curproc->incoming_message_header();
    my $rules     = $config->get_as_array_ref( 'incoming_mail_header_loop_check_rules' );
    my $match     = 0;

  RULE:
    for my $rule (@$rules) {
	if ($header->can($rule)) {
	    $match = $header->$rule($config) ? $rule : 0;
	}
	else {
	    $curproc->log("header->${rule}() is undefined");
	}

	last RULE if $match;
    }

    # This $match contains the first matched rule name (== reason).
    if ($match) {
	# we should stop this process ASAP.
	$curproc->stop_this_process();
	$curproc->logerror("mail loop detected for $match");
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


# Descriptions: determine ml_* variables with considering virtual domains.
#    Arguments: OBJ($curproc)
# Side Effects: update $config->{ ml_* } variables.
# Return Value: none
sub resolve_ml_specific_variables
{
    my ($curproc) = @_;
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
    my ($command, @options, $config_cf_path);
    my $config  = $curproc->config();
    my $myname  = $curproc->myname();
    my $ml_addr = '';

    # XXX-TODO: $config should determine makefml like argument or not ?
    # XXX-TODO: for example, if ($config->is_makefml_argv_style( $myname ) {;}
    # 1. virtual domain or not ?
    # 1.1 search ml@domain syntax arg in @ARGV
    if ($myname eq 'makefml'   ||
	$myname eq 'fml'       ||
	$myname eq 'fmlspool'  ||
	$myname eq 'fmlsummary'||
	$myname eq 'fmlthread') {
	my $default_domain = $curproc->default_domain();

	if ($myname eq 'fml') {
	    ($ml_name, $command, @options) = @ARGV;
	}
	else {
	    ($command, $ml_name, @options) = @ARGV;
	}

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
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;

	# XXX searching of ml_addr by the first match. ok?
	# "fmlconf -n elena@fml.org" works ? yes
	# "fmlconf -n elena" works ?         yes
      ARGV:
	for my $arg (@ARGV) {
	    if ($safe->regexp_match('address', $arg)) {
		$ml_addr = $arg;
		last ARGV;
	    }
	}

	# not found. Hmm, "fmlconf -n elena" case ?
	unless ($ml_addr) {
	    my $default_domain = $curproc->default_domain();

	  ARGS:
	    for my $arg (@ARGV) {
		last ARGS if $ml_addr;
		next ARGS if $arg =~ /^\-/o; # options

		if ($safe->regexp_match('ml_name', $arg)) {
		    $ml_addr = $arg. '@' . $default_domain;
		}
	    }
	}
    }

    # 1.2 set up ml_* in config space.
    # 1.2(a) ml@domain found. It may be specified in command line args.
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
    # 1.2(b) argv must have dirname (ml_home_dir).
    # Example: "| /usr/local/libexec/fml/fml.pl /var/spool/ml/elena"
    #    XXX the following code is true if config.cf has $ml_name definition.
    else {
	my $r = $curproc->_find_ml_home_dir_in_argv();

	# [1.2.b.1]
	# determine default $ml_home_dir and $hom_home_prefix by main.cf.
	if (defined $r->{ ml_home_dir }) {
	    use File::Basename;
	    my $home_dir = $r->{ ml_home_dir };
	    my $prefix   = dirname( $home_dir );
	    $config->set( 'ml_home_prefix', $prefix);
	    $config->set( 'ml_home_dir',    $home_dir);

	    use File::Spec;
	    $config_cf_path = File::Spec->catfile($home_dir, "config.cf");
	}

	# [1.2.b.2]
	# lastly, we need to determine $ml_name and $ml_domain.
	# parse the argument such as "fml.pl /var/spool/ml/elena ..."
	unless ($ml_name) {
	    $curproc->log("(debug) parse @ARGV");

	  ARGS:
	    for my $arg (@ARGV) {
		last ARGS if $ml_name;
		next ARGS if $arg =~ /^\-/o; # options

		# the first directory name e.g. /var/spool/ml/elena
		if (-d $arg) {
		    my $default_domain = $curproc->default_domain();

		    use File::Spec;
		    my $_cf_path = File::Spec->catfile($arg, "config.cf");

		    if (-f $config_cf_path) {
			$config_cf_path = $_cf_path;

			use File::Basename;
			$ml_name     = basename( $arg );
			$ml_home_dir = dirname( $arg );

			$config->set( 'ml_name',     $ml_name );
			$config->set( 'ml_domain',   $default_domain );
			$config->set( 'ml_home_dir', $arg );

			my $s = "ml_name=$ml_name ml_home_dir=$ml_home_dir";
			$curproc->log("(debug) $s");
		    }
		}
	    }
	}
    }

    if ($config_cf_path) {
	# debug
	$curproc->__debug_ml_xxx('resolv:');

	# add this ml's config.cf to the .cf list.
	$curproc->append_to_config_files_list($config_cf_path);
    }
    else {
	$curproc->logerror("cannot determine which ml_name");
    }
}


# XXX remove this in the future
my @delayed_buffer = ();

# Descriptions: debug log. removed in the future
#    Arguments: OBJ($curproc) STR($str)
# Side Effects: none
# Return Value: none
sub __debug_ml_xxx
{
    my ($curproc, $str) = @_;
    my $config = $curproc->config();

    if (defined $config->{ log_file } && (-w $config->{ log_file })) {
	for my $buf (@delayed_buffer) { $curproc->log( $buf ); }
	@delayed_buffer = ();

	for my $var (qw(ml_name ml_domain ml_home_prefix ml_home_dir)) {
	    $curproc->log(sprintf("%-25s = %s", '(debug)'.$str. $var,
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


# Descriptions: analyze argument vector and return ml_home_dir and .cf list.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub _find_ml_home_dir_in_argv
{
    my ($curproc) = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix();
    my $ml_home_dir    = '';
    my $found_cf       = 0;
    my @cf             = ();

    # Example: "elena" is translated to "/var/spool/ml/elena"
  ARGV:
    for my $argv (@ARGV) {
	# 1. for the first time
	#  a) speculate "/var/spool/ml/$_" looks a $ml_home_dir
	#     (== default $ml_home_dir)?
	unless ($found_cf) {
	    my $x  = File::Spec->catfile($ml_home_prefix, $argv);
	    my $cf = File::Spec->catfile($x, "config.cf");
	    if (-d $x && -f $cf) {
		$found_cf    = 1;
		$ml_home_dir = $x;
		push(@cf, $cf);
	    }
	}

	last ARGV if $found_cf;

	# 2. /var/spool/ml/elena looks a $ml_home_dir ?
	if (-d $argv) {
	    $ml_home_dir = $argv;
	    my $cf = File::Spec->catfile($argv, "config.cf");
	    if (-f $cf) {
		push(@cf, $cf);
		$found_cf = 1;
	    }
	}
	# 3. looks a file, so /var/spool/ml/elena/config.cf ?
	elsif (-f $argv) {
	    push(@cf, $argv);
	}
    }

    return {
	ml_home_dir => $ml_home_dir,
	cf_list     => \@cf,
    };
}


=head2 load_config_files($files)

read several configuration C<@$files>.
The variable evaluation (expansion) is done on demand when
$config->get() of FETCH() method is called.

=cut

# Descriptions: load configuration files and evaluate variables
#    Arguments: OBJ($curproc) ARRAY_REF($files)
# Side Effects: none
# Return Value: none
sub load_config_files
{
    my ($curproc, $files) = @_;
    my $config = $curproc->config();
    my $_files = $files || $curproc->get_config_files_list();

    # load configuration variables from given files e.g. /some/where.cf
    # XXX overload variables from each $cf
    for my $cf (@$_files) {
      $config->overload( $cf );
    }

    # XXX We need to expand variables after we load all *cf files.
    # XXX 2001/05/05 changed to dynamic expansion for hook
    # $curproc->config()->expand_variables();

    if ($curproc->is_cgi_process() || $curproc->is_under_mta_process()) {
	# XXX simple sanity check
	#     MAIL_LIST != MAINTAINER
	my $maintainer = $config->{ maintainer }       || '';
	my $ml_address = $config->{ address_for_post } || '';

	unless ($maintainer) {
	    my $s = "configuration error: \$maintainer undefined";
	    $curproc->logerror($s);
	    $curproc->stop_this_process("configuration error");
	}

	use FML::Credential;
	my $cred = new FML::Credential $curproc;
	if ($cred->is_same_address($maintainer, $ml_address)) {
	    my $s = "configuration error: \$maintainer == \$address_for_post";
	    $curproc->logerror($s);
	    $curproc->stop_this_process("configuration error");
	}
    }
}


# Descriptions: add ml local library path into @INC
#    Arguments: OBJ($curproc)
# Side Effects: update @INC
# Return Value: none
sub fix_perl_include_path
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # XXX update @INC here since we should do after loading configurations.
    # update @INC for ml local libraries
    if (defined $config->{ ml_home_dir } &&
	$config->{ ml_home_dir } &&
	defined $config->{ ml_local_lib_dir }) {
	unshift(@INC, $config->{ ml_local_lib_dir });
    }
}


=head2 parse_incoming_message($args)

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
#    Arguments: OBJ($curproc)
# Side Effects: $curproc->{'incoming_message'} is set up
# Return Value: none
sub parse_incoming_message
{
    my ($curproc) = @_;

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
    my $config = $curproc->config();
    if ($config->yes('use_incoming_mail_cache')) {
	my $dir     = $config->{ incoming_mail_cache_dir };
	my $modulus = $config->{ incoming_mail_cache_size };
	use File::CacheDir;
        my $obj     = new File::CacheDir {
            directory => $dir,
	    modulus   => $modulus,
        };

	if (defined $obj) {
	    my $wh = $obj->open();
	    if (defined $wh) {
		$msg->print($wh);
		$wh->close();
		$obj->close();
	    }

	    # save the cache file path.
	    my $path = $obj->cache_file_path();
	    $curproc->set_incoming_message_cache_file_path($path);
	}
    }

    # Accept-Language: handling
    if (defined $msg) {
	my $list = $msg->accept_language_list();
	$curproc->set_accept_language_list($list);
    }
}


=head1 CREDENTIAL

=head2 premit_post($args)

permit posting.
The restriction rules follows the order of C<post_restrictions>.

=head2 premit_command($args)

permit fml command use.
The restriction rules follows the order of C<command_restrictions>.

=cut


# Descriptions: permit this post process
#    Arguments: OBJ($curproc)
# Side Effects: set the error reason at "check_restriction" in pcb.
# Return Value: NUM(1 or 0)
sub permit_post
{
    my ($curproc) = @_;
    $curproc->_check_restrictions('post');
}


# Descriptions: permit this command process
#    Arguments: OBJ($curproc)
# Side Effects: set the error reason at "check_restriction" in pcb.
# Return Value: NUM(1 or 0)
sub permit_command
{
    my ($curproc) = @_;
    $curproc->_check_restrictions('command');
}


# Descriptions: permit this $type process based on the rules defined
#               in ${type}_restrictions.
#    Arguments: OBJ($curproc) STR($type)
# Side Effects: set the error reason at "check_restriction" n pcb.
# Return Value: NUM(1 or 0)
sub _check_restrictions
{
    my ($curproc, $type) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->{ credential }; # user credential
    my $pcb    = $curproc->pcb();
    my $sender = $cred->sender();
    my $rules  = $config->get_as_array_ref( "${type}_restrictions" );

    use FML::Restriction::Post;
    my $acl = new FML::Restriction::Post $curproc;

    my ($match, $result) = (0, 0);
    for my $rule (@$rules) {
	if ($acl->can($rule)) {
	    # match  = matched. return as soon as possible from here.
	    #          ASAP or RETRY the next rule, depends on the rule.
	    # result = action determined by matched rule.
	    ($match, $result) = $acl->$rule($rule, $sender);
	}
	else {
	    ($match, $result) = (0, undef);
	    $curproc->logwarn("unknown rule=$rule");
	}

	if ($match) {
	    $curproc->log("match rule=$rule sender=$sender");
	    return($result eq "permit" ? 1 : 0);
	}
    }

    return 0; # deny by default
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


=head1 LOG MESSAGE HANDLING

=head2 log_message_init()

initialize log message queue.

=cut


# Descriptions: log message queue
#    Arguments: OBJ($curproc)
# Side Effects: set up $curproc->{ log_message_queue }.
# Return Value: none
sub log_message_init
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $module    = $config->{ log_computer_output_engine };
    my $obj       = undef;

    eval qq{
	use $module;
	\$obj = new $module;
    };
    $curproc->logerror($@) if $@;

    if (defined $obj) {
	$curproc->{ log_message_queue } = $obj;
    }
    else {
	$curproc->logerror("fail to create log_computer_output_engine object");
    }
}


# Descriptions: append message into the message queue.
#    Arguments: OBJ($curproc) HASH_REF($msg)
# Side Effects: update message queue.
# Return Value: none
sub _log_message_queue_append
{
    my ($curproc, $msg) = @_;
    my $msg_queue = $curproc->{ log_message_queue };

    if (defined $msg_queue) {
	$msg->{ time } = time;
	$msg_queue->add($msg);
    }
    else {
	my $debug = $curproc->get_debug_level();
	if ($debug > 1) {
	    print STDERR "msg: ", $msg->{ buf }, "\n";
	}
    }
}


# Descriptions: log message queue
#    Arguments: OBJ($curproc)
# Side Effects: set up $curproc->{ log_message_queue }.
# Return Value: none
sub _log_message_print
{
    my ($curproc) = @_;
    my $msg_queue = $curproc->{ log_message_queue };

    if (defined $msg_queue) {
	$msg_queue->print();
    }
}


=head2 log_message($msg, $msg_args)

?
    log(STR)       log_message(STR, { level => "ok"      })
    logwarn(STR)   log_message(STR, { level => "warning" })
    logerror(STR)  log_message(STR, { level => "error"   })

=head2 log($msg, $msg_args)

=head2 logwarn($msg, $msg_args)

=head2 logerror($msg, $msg_args)

=cut


# Descriptions: log message
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub log_message
{
    my ($curproc, $msg, $msg_args) = @_;
    my $_msg_args   = $msg_args->{ msg_args };
    my $level       = $msg_args->{ level };
    my $at_package  = $msg_args->{ caller }->[ 0 ];
    my $at_function = $msg_args->{ caller }->[ 1 ];
    my $at_line     = $msg_args->{ caller }->[ 2 ];

    if ($level eq 'info') {
	Log($msg);
    }
    elsif ($level eq 'warn') {
	LogWarn($msg);
    }
    elsif ($level eq 'error') {
	LogError($msg);
    }

    # update message queue
    $curproc->_log_message_queue_append({
	buf   => $msg,
	level => $level,
	hints => {
	    at_package  => $at_package,
	    at_function => $at_function,
	    at_line     => $at_line,
	},
    });
}


# Descriptions: log message
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub log
{
    my ($curproc, $msg, $msg_args) = @_;
    my (@c) = caller;

    $curproc->log_message($msg, {
	msg_args => $msg_args,
	level    => 'info',
	caller   => \@c,
    });
}


# Descriptions: log message as warning.
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logwarn
{
    my ($curproc, $msg, $msg_args) = @_;
    my (@c) = caller;

    $curproc->log_message($msg, {
	msg_args => $msg_args,
	level    => 'warn',
	caller   => \@c,
    });
}


# Descriptions: log message as error.
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($curproc, $msg, $msg_args) = @_;
    my (@c) = caller;

    $curproc->log_message($msg, {
	msg_args => $msg_args,
	level    => 'error',
	caller   => \@c,
    });
}


# Descriptions: informational message CUI shows logged 
#               and forwarded into STDERR.
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub ui_message
{
    my ($curproc, $msg, $msg_args) = @_;
    my (@c) = caller;

    print STDERR $msg, "\n";

    $curproc->log_message($msg, {
	msg_args => $msg_args,
	level    => $msg_args->{ level } || 'info',
	caller   => \@c,
    });
}


=head2 reply_message($msg)

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


# Descriptions: set reply message
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args)
# Side Effects: none
# Return Value: none
sub reply_message
{
    my ($curproc, $msg, $rm_args) = @_;
    my $myname = $curproc->myname();

    $curproc->caller_info($msg, caller) if $debug;

    # XXX-TODO: hard-coded. move condition statements to configuration file.
    # XXX makefml not support message handling not yet.
    if ($myname eq 'makefml' ||
	$myname eq 'fml'     ||
	$myname =~ /\.cgi$/) {
	$curproc->logwarn("(debug) $myname disables reply_message()");
	return;
    }

    # get recipients list
    my ($recipient, $recipient_maps) = $curproc->_analyze_recipients($rm_args);
    my $hdr                          = $curproc->_analyze_header($rm_args);

    # check text messages and fix if needed.
    unless (ref($msg)) {
	# \n in the last always.
	$msg .= "\n" unless $msg =~ /\n$/;
    }

    $curproc->_append_message_into_queue2($msg, $rm_args,
					 $recipient, $recipient_maps,
					 $hdr);

    if (defined $rm_args->{ always_cc }) {
	# only if $recipient above != always_cc, duplicate $msg message.
	my $sent = $recipient;
	my $cc   = $rm_args->{ always_cc };

	my $recipient = [];
	if (ref($cc) eq 'ARRAY') {
	    $recipient = $cc;
	}
	else {
	    $recipient = [ $cc ];
	}

	if (_array_is_different($sent, $recipient)) {
	    $curproc->log("cc: [ @$recipient ]");
	    $curproc->_append_message_into_queue($msg, $rm_args,
						 $recipient, $recipient_maps,
						 $hdr);
	}
    }
}


# Descriptions: return recipient info.
#    Arguments: OBJ($curproc) HASH_REF($rm_args)
# Side Effects: none
# Return Value: ARRAY( ARRAY_REF, ARRAY_REF)
sub _analyze_recipients
{
    my ($curproc, $rm_args) = @_;
    my $recipient      = [];
    my $recipient_maps = [];
    my $rcpt = $rm_args->{ recipient }      if defined $rm_args->{ recipient };
    my $map  = $rm_args->{ recipient_map }  if defined $rm_args->{ recipient_map };
    my $maps = $rm_args->{ recipient_maps } if defined $rm_args->{ recipient_maps };

    if (defined($rcpt)) {
	if (ref($rcpt) eq 'ARRAY') {
	    $recipient = $rcpt if @$rcpt;
	}
	elsif (ref($rcpt) eq '') {
	    $recipient = [ $rcpt ] if $rcpt;
	}
	else {
	    $curproc->logerror("reply_message: wrong type recipient");
	}
    }

    if (defined($map)) {
	if (ref($map) eq '') {
	    $recipient_maps = [ $map ] if $map;
	}
	else {
	    $curproc->logerror("reply_message: wrong type recipient_map");
	}
    }

    if (defined($maps)) {
	if (ref($maps) eq 'ARRAY') {
	    $recipient_maps = $maps if @$maps;
	}
	else {
	    $curproc->logerror("reply_message: wrong type recipient_maps");
	}
    }

    # if both specified, use default sender.
    unless (@$recipient || @$recipient_maps) {
	$recipient = [ $curproc->{ credential }->sender() ];
    }

    # aggregation of recepients: [ A, A, B ] -> [ A, B ]
    $recipient      = $curproc->unique( $recipient );
    $recipient_maps = $curproc->unique( $recipient_maps );

    return ($recipient, $recipient_maps);
}


# Descriptions: return header parameters
#    Arguments: OBJ($curproc) HASH_REF($rm_args)
# Side Effects: none
# Return Value: HASH_REF
sub _analyze_header
{
    my ($curproc, $rm_args) = @_;
    return $rm_args->{ header };
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
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args)
#               ARRAY_REF($recipient) ARRAY_REF($recipient_maps) OBJ($hdr)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue
{
    my ($curproc, $msg, $rm_args, $recipient, $recipient_maps, $hdr) = @_;
    my $pcb      = $curproc->pcb();
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


# Descriptions: add the specified $msg into on memory queue
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args)
#               ARRAY_REF($recipient) ARRAY_REF($recipient_maps) OBJ($hdr)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue2
{
    my ($curproc, $msg, $rm_args, $recipient, $recipient_maps, $hdr) = @_;
    my $pcb      = $curproc->pcb();
    my $category = 'reply_message';
    my $class    = 'queue';
    my $rarray   = $pcb->get($category, $class) || [];

    for my $rcpt (@$recipient) {
	$rarray->[ $#$rarray + 1 ] = {
	    message        => $msg,
	    type           => ref($msg) ? ref($msg) : 'text',
	    recipient      => [ $rcpt ],
	    recipient_maps => [],
	    header         => $hdr,
	};
    }

    for my $map (@$recipient_maps) {
	$rarray->[ $#$rarray + 1 ] = {
	    message        => $msg,
	    type           => ref($msg) ? ref($msg) : 'text',
	    recipient      => [],
	    recipient_maps => [ $map ],
	    header         => $hdr,
	};
    }

    $pcb->set($category, $class, $rarray);
}


# Descriptions: built and return recipient type and list in
#               on memory queue.
#    Arguments: OBJ($curproc) OBJ($msg)
# Side Effects: none
# Return Value: ARRAY( HASH_REF, HASH_REF )
sub _reply_message_recipient_keys
{
    my ($curproc, $msg) = @_;
    my $pcb      = $curproc->pcb();
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
	    $key      = $curproc->_gen_recipient_key( $rcptlist, $rcptmaps );
	    $rcptattr{ $key }->{ $type }++;
	    $rcptlist{ $key } = $rcptlist;
	    $rcptmaps{ $key } = $rcptmaps;
	    $hdr{ $key }      = $m->{ header };
	}
    }

    return ( \%rcptattr, \%rcptlist, \%rcptmaps, \%hdr );
}


# Descriptions: make a key
#    Arguments: OBJ($curproc) ARRAY_REF($rarray) ARRAY_REF($rmaps)
# Side Effects: none
# Return Value: STR
sub _gen_recipient_key
{
    my ($curproc, $rarray, $rmaps) = @_;
    my (@c) = caller;
    my $key = '';

    if (defined $rarray) {
	if (ref($rarray) eq 'ARRAY') {
	    if (@$rarray) {
		$key = join(" ", @$rarray);
	    }
	}
	else {
	    $curproc->logerror("wrong \$rarray");
	}
    }

    if (defined $rmaps) {
	if (ref($rmaps) eq 'ARRAY') {
	    if (@$rmaps) {
		$key .= " ".join(" ", @$rmaps);
	    }
	}
	else {
	    $curproc->logerror("wrong \$rmaps");
	}
    }

    return $key;
}


=head2 reply_message_nl($class, $default_msg, $args)

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
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($rm_args)
# Side Effects: none
# Return Value: none
sub reply_message_nl
{
    my ($curproc, $class, $default_msg, $rm_args) = @_;
    my $config = $curproc->config();
    my $buf    = $curproc->message_nl($class, $default_msg, $rm_args);

    $curproc->caller_info($class, caller) if $debug;

    if (defined $buf) {
	if ($buf =~ /\$/) {
	    $config->expand_variable_in_buffer(\$buf, $rm_args);
	}

	# XXX-TODO: jis-jp is hard-coded.
	eval q{
	    use Mail::Message::Encode;
	    my $obj = new Mail::Message::Encode;
	    $curproc->reply_message( $obj->convert( $buf, 'jis-jp' ), $rm_args);
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->reply_message($default_msg, $rm_args);
    }
}


# Descriptions: add header info.
#    Arguments: OBJ($curproc) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub reply_message_add_header_info
{
    my ($curproc, $msg_args) = @_;
    my $tag     = '   ';
    my $hdr     = $curproc->incoming_message_header();
    my $hdr_str = sprintf("\n%s\n", $hdr->as_string());
    $hdr_str    =~ s/\n/\n$tag/g;

    $curproc->reply_message($hdr_str, $msg_args);
}


# Descriptions: get template message in natual language
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($m_args)
# Side Effects: none
# Return Value: STR
sub message_nl
{
    my ($curproc, $class, $default_msg, $m_args) = @_;
    my $config    = $curproc->config();
    my $dir       = $config->{ message_template_dir };
    my $local_dir = $config->{ ml_local_message_template_dir };
    my $charset   = $curproc->get_charset("template_file");
    my $buf       = '';

    use File::Spec;
    $class =~ s@\.@/@g; # XXX . -> /

    my $local_file = File::Spec->catfile($local_dir, $charset, $class);
    my $file       = File::Spec->catfile($dir,       $charset, $class);

    # override message: replace default one with ml local message template
    if (-f $local_file) { $file = $local_file;}

    # import message template
    if (-f $file) {
	use FileHandle;
	my $fh = new FileHandle $file;
	if (defined $fh) {
	    my $xbuf;
	    while ($xbuf = <$fh>) { $buf .= $xbuf;}
	    $fh->close();
	}
    }
    else {
	$curproc->logwarn("no such file: $file");
    }

    if (defined $buf) {
	my $config = $curproc->config();
        if ($buf =~ /\$/o) {
            $config->expand_variable_in_buffer(\$buf, $m_args);
        }
    }

    return( $buf || $default_msg || '' );
}


# Descriptions: log message with info returned by caller().
#    Arguments: OBJ($curproc) STR($msg) STR($pkg) STR($fn) NUM($line)
# Side Effects: none
# Return Value: none
sub caller_info
{
    my ($curproc, $msg, $pkg, $fn, $line) = @_;
    $curproc->log("msg='$msg' $fn $line");
}


=head2 inform_reply_messages($args)

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
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub inform_reply_messages
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

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


=head2 queue_in($category, $optargs)

=cut


# Descriptions: queue in. queueing only not delivered.
#    Arguments: OBJ($curproc) STR($category) HASH_REF($optargs)
# Side Effects: add message into queue
# Return Value: OBJ(queue object)
sub queue_in
{
    my ($curproc, $category, $optargs) = @_;
    my $pcb          = $curproc->pcb();
    my $config       = $curproc->config();
    my $sender       = $config->{ maintainer };
    my $charset      = $curproc->get_charset($category);
    my $subject      = $config->{ "${category}_subject" };
    my $reply_to     = $config->{ address_for_command };
    my $is_multipart = 0;
    my $rcptkey      = '';
    my $rcptlist     = [];
    my $rcptmaps     = [];
    my $msg          = '';
    my $hdr_to       = '';

    use Mail::Message::Date;
    my $_nowdate     = new Mail::Message::Date time;
    my $our_date     = $_nowdate->{ mail_header_style };

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


    $curproc->log("debug: queue_in: sender=$sender");
    $curproc->log("debug: queue_in: recipient=$rcptkey");
    $curproc->log("debug: queue_in: rcptlist=[ @$rcptlist ]");
    $curproc->log("debug: queue_in: is_multipart=$is_multipart");


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
		From      => $sender,
		To        => $_to,
		Subject   => $subject,
		Type      => "multipart/mixed",
	        Datestamp => undef,
	};
	$msg->add('Reply-To' => $reply_to);
	$msg->add('Date' => $our_date);
	_add_info_on_header($config, $msg);

	my $mesg_queue = $pcb->get($category, 'queue');
	my $s = '';

      QUEUE:
	for my $m ( @$mesg_queue ) {
	    my $q = $m->{ message };
	    my $t = $m->{ type };
	    my $r = $curproc->_gen_recipient_key($m->{ recipient },
						 $m->{ recipient_maps } );

	    # pick up only messages returned to specified $rcptkey
	    next QUEUE unless $r eq $rcptkey;

	    if ($t eq 'text') {
		$s .= $q;
	    }
	}

	# 1. eat up text messages and put it into the first part.
	# XXX-TODO: wrong handling of $charset ???
	# XXX-TODO: reply message should be determined by context and
	# XXX-TODO: accept-language: information.
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
	    my $r = $curproc->_gen_recipient_key($m->{ recipient },
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
		    # $curproc->log("queue_in: type=<$t> aggregated") if $t eq 'text';
		    $curproc->log("queue_in: unknown type=<$t>") unless $t eq 'text';
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
	    my $r = $curproc->_gen_recipient_key($m->{ recipient },
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
		    $curproc->log("queue_in: unknown typ $t");
		}
	    }
	}

	my $_to = $hdr_to || $rcptkey;
	eval q{
	    $msg = new Mail::Message::Compose
		From      => $sender,
		To        => $_to,
		Subject   => $subject,
		Data      => $s,
	        Datestamp => undef,
	};
	$msg->attr('content-type.charset' => $charset);
	$msg->add('Reply-To' => $reply_to);
	$msg->add('Date' => $our_date);
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

	$queue->in( $msg ) && $curproc->log("queue=$qid in");
	if ($queue->setrunnable()) {
	    $curproc->log("queue=$qid runnable");
	}
	else {
	    $curproc->log("queue=$qid broken");
	}

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
	$curproc->logerror("_append_rfc822_message: cannot create \$tmpfile");
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
	    $curproc->logerror("_append_rfc822_message: cannot open \$tmpfile");
	}

	$curproc->add_into_clean_up_queue( $tmpfile );
    }
    else {
	$curproc->logerror("_append_rfc822_message: \$tmpfile not found");
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
	    $curproc->log("unlink $q") if $debug;
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
    my $config  = $curproc->config();
    my $tmp_dir = $config->{ tmp_dir };

    $TmpFileCounter++; # ensure uniqueness
    my $f = sprintf("tmp.%s.%s.%s", $$, time, $TmpFileCounter);

    if (-d $tmp_dir && -w $tmp_dir) {
	use File::Spec;
	return File::Spec->catfile($tmp_dir, $f);
    }
    else {
	my $tmp_dir = $curproc->global_tmp_dir_path();
	use File::Spec;
	return File::Spec->catfile($tmp_dir, $f);
    }
}


# Descriptions: generate string $ml_home_prefix/@tmp@.
#               Also, create it if not exists.
#    Arguments: OBJ($curproc) STR($ml_domain)
# Side Effects: create $ml_home_prefix/@tmp@ if not exists.
# Return Value: STR
sub global_tmp_dir_path
{
    my ($curproc, $ml_domain) = @_;
    my $config = $curproc->config();
    my $domain = $ml_domain || $config->{ ml_domain } || '';

    use File::Spec;
    my $ml_home_prefix = $curproc->ml_home_prefix($domain);
    my $global_tmp_dir = File::Spec->catfile($ml_home_prefix, '@tmp@');

    unless (-d $global_tmp_dir) {
	$curproc->mkdir($global_tmp_dir, "mode=private");
    }

    return $global_tmp_dir;
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
    my $hrw_args = {
	type    => 'MIME::Lite',
	message => $msg,
    };
  FML::Header->add_message_id($config, $hrw_args);
  FML::Header->add_software_info($config, $hrw_args);
  FML::Header->add_rfc2369($config, $hrw_args);
}


=head2 queue_flush($queue)

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
    my $config    = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };

    eval q{
	use FML::Process::QueueManager;
	my $obj = new FML::Process::QueueManager { directory => $queue_dir };
	$obj->send($curproc);
    };
    croak($@) if $@;
}


=head2 expand_variables_in_file

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
#    Arguments: OBJ($curproc) HASH_REF($pf_args)
# Side Effects: none
# Return Value: a new filepath (string) to be prepared
sub prepare_file_to_return
{
    my ($curproc, $pf_args) = @_;
    my $config      = $curproc->config();
    my $tmp_dir     = $config->{ tmp_dir };
    my $tmpf        = File::Spec->catfile($tmp_dir, $$);
    my $src_file    = $pf_args->{ src };
    my $charset_out = $pf_args->{ charset };

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
	    my $buf;
	    while ($buf = <$rh>) {
		if ($buf =~ /\$/o) {
		    $config->expand_variable_in_buffer(\$buf, $pf_args);
		}
		$wh->print( $obj->convert( $buf, 'jis-jp' ) );
	    }
	}
	else {
	    $curproc->logerror("Mail::Message::Encode object undef");
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
    my $config = $curproc->config();

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


# Descriptions: close and re-open STDERR channel.
#    Arguments: OBJ($curproc)
# Side Effects: close(STDERR)
# Return Value: none
sub _reopen_stderr_channel
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($curproc->is_cgi_process()       ||
	$curproc->is_under_mta_process() ||
	defined $option->{ quiet }  || defined $option->{ q } ||
	$config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') || $option->{'log-computer-output'}) {
	my $tmpfile = $curproc->temp_file_path();
	my $pcb     = $curproc->pcb();
	$pcb->set("stderr", "logfile", $tmpfile);
	$pcb->set("stderr", "use_log_dup", 1);

	open(STDERR, "> $tmpfile") || croak("fail to open $tmpfile");
	$curproc->add_into_clean_up_queue($tmpfile);
    }
}


# Descriptions: close and log messages written into STDERR channel.
#    Arguments: OBJ($curproc)
# Side Effects: close(STDERR)
# Return Value: none
sub _finalize_stderr_channel
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();
    my $pcb       = $curproc->pcb();

    if (defined $pcb) {
	my $tmpfile   = $pcb->get("stderr", "logfile");
	my $is_logdup = $pcb->get("stderr", "use_log_dup") || 0;

	# avoid duplicated calls.
	return unless $is_logdup;

	if ($curproc->is_cgi_process()       ||
	    $curproc->is_under_mta_process() ||
	    defined $option->{ quiet }  || defined $option->{ q } ||
	    $config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	    $config->yes('use_log_computer_output') ||
	    $option->{'log-computer-output'}) {

	    close(STDERR);
	    open(STDERR, ">&STDOUT");

	    if (-s $tmpfile) {
		use FileHandle;
		my $fh = new FileHandle $tmpfile;
		if (defined $fh) {
		    my $buf;
		    while ($buf = <$fh>) {
			chomp $buf;
			$curproc->logwarn($buf);
		    }
		    $fh->close();
		}
	    }
	}

	$pcb->set("stderr", "use_log_dup", 0);
    }
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
    my $pcb = $curproc->pcb();

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
    my $pcb = $curproc->pcb();
    my $saved_umask = $pcb->get('umask', 'saved_umask');

    # back to the original umask;
    umask($saved_umask);
}


# Descriptions: close.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub be_quiet
{
    my ($curproc) = @_;
    my $debug     = $curproc->get_debug_level();
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($curproc->is_cgi_process()       ||
	$curproc->is_under_mta_process() ||
	defined $option->{ quiet }  || defined $option->{ q } ||
	$config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') || $option->{'log-computer-output'}) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: finalize curproc.
#    Arguments: OBJ($curproc)
# Side Effects: non
# Return Value: none
sub finalize
{
    my ($curproc) = @_;
    my $debug     = $curproc->get_debug_level();
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') || $option->{'log-computer-output'}) {
	$curproc->_finalize_stderr_channel();
	$curproc->_log_message_print();
    }

    if ($debug > 100) {
	$curproc->log("debug: dump curproc structure");
	eval q{
	    use FML::Process::Debug;
	    my $obj = new FML::Process::Debug;
	    $obj->dump_curproc($curproc);
	};
	$curproc->logerror($@) if $@;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
