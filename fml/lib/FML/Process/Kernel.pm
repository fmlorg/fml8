#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.277 2006/04/05 03:23:47 fukachan Exp $
#

package FML::Process::Kernel;

use strict;
use Carp;
use vars qw(@ISA @Tmpfiles $TmpFileCounter %LockInfo);
use File::Spec;

use IO::Adapter;
use FML::Process::Flow;
use FML::Parse;
use FML::Header;
use FML::Config;
use FML::Log qw(Log LogWarn LogError);
use FML::Process::Utils;
use FML::Process::State;
@ISA = qw(FML::Process::State FML::Process::Utils);


my $debug      = 0;
my $rm_debug   = 0;
my $first_time = 0;


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


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: allocate the current process table on memory
# Return Value: OBJ(FML::Process::Kernel object)
sub new
{
    my ($self, $args) = @_;
    my ($curproc)     = {}; # alloc memory as the struct current_process.
    my ($cfargs)      = {}; # parameters to export into $config object.

    # XXX [CAUTION]
    # XXX MOVE PARSER FROM Process::Switch to HERE
    # XXX

    # 1.1 import variables
    for my $var (qw(program_name)) {
	if (defined $args->{ $var }) {
	    $cfargs->{ $var } = $args->{ $var };
	}
    }

    # 1.2 import XXX variables as fml_XXX from /etc/fml/main.cf.
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
			    default_cui_menu
			    default_gui_menu

			)) {
	if (defined $args->{ main_cf }->{ $main_cf_var }) {
	    my $key = sprintf("fml_%s", $main_cf_var);
	    $cfargs->{ $key } = $args->{ main_cf }->{ $main_cf_var };
	}
    }

    # 1.3 import $fml_version
    if (defined $args->{ fml_version }) {
	$cfargs->{ fml_version } =
	    sprintf("fml %s", $args->{ fml_version });
    }

    # 1.4 overwrite variables by -o options
    if (defined $args->{ options }->{ o }) {
	my ($k, $v);
	my $opts = $args->{ options }->{ o };
	while (($k, $v) = each %$opts) { $cfargs->{ $k } = $v;}
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

    # 3.2 initialize context for further use of config object name space.
    _context_init($curproc);

    # 3.3 bind FML::Config object to $curproc
    use FML::Config;
    $curproc->{ config } = new FML::Config $cfargs;

    # 3.4 initialize PCB (Process Control Block)
    use FML::PCB;
    $curproc->{ pcb } = new FML::PCB;

    # 3.5
    # object-ify. bless! bless! bless!
    bless $curproc, $self;

    # 4.1 initialize watchdog timer.
    $curproc->_watchdog_init;

    # 4.2 initialize signal handlers
    $curproc->_signal_init;

    # 4.3 default printing style
    $curproc->_print_init;

    # 4.4 set up message queue for logging. (moved to each program)
    # $curproc->_log_message_init();

    # 4.5 prepare credential object
    $curproc->_credential_init();

    # 5.1 debug. XXX remove this in the future !
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


# Descriptions: initialize watchdog timer.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _watchdog_init
{
    my ($curproc) = @_;

    $curproc->{ __start_time } = time;
}


# Descriptions: watchdog timer time out.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_process_time_limit
{
    my ($curproc) = @_;
    my $time  = $curproc->{ __start_time };
    my $limit = int(1000 * 0.95);

    if (time > $time + $limit) {
	return 1;
    }

    return 0;
}


# Descriptions: set up default signal handling.
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


# Descriptions: set up default printing style handling.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _print_init
{
    my ($curproc) = @_;
    $curproc->output_set_print_style( 'text' );
}


# Descriptions: alloc credential area.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _credential_init
{
    my ($curproc) = @_;

    use FML::Credential;
    my $cred = new FML::Credential $curproc;
    $curproc->{ 'credential' } = $cred;
}


# Descriptions: initialize context information for context switch.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _context_init
{
    my ($curproc) = @_;

    use FML::Config;
    my $_config = new FML::Config;
    $_config->set_context("$curproc");

    use FML::PCB;
    my $_pcb = new FML::PCB;
    $_pcb->set_context("$curproc");
}


# Descriptions: activate scheduler.
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


# Descriptions: show help and exit here, (ASAP).
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: longjmp() to help
# Return Value: none
sub sysflow_trap_help
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

# Descriptions: preliminary works before the main part starts.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: same as incoming_message_parse()
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


# Descriptions: lock the specified channel.
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

    # require File::SimpleLock;
    # my $lockobj = $pcb->get('lock', $channel) || new File::SimpleLock;
    my $map = sprintf("file:%s", $lock_file);
    my $io  = $pcb->get('lock', $channel) || new IO::Adapter $map;

    my $r = $io->lock( { file => $lock_file } );
    if ($r) {
	my $t = time - $time_in;
	if ($t > 1) {
	    $curproc->logwarn("lock channel=$channel requires $t sec.");
	}

	$pcb->set('lock', $channel, $io);
	$LockInfo{ $channel } = 1;
	$curproc->logdebug("lock channel=$channel");
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

    my $pcb = $curproc->pcb();
    my $map = sprintf("file:%s", $lock_file);
    my $io  = $pcb->get('lock', $channel) || new IO::Adapter $map;

    if (defined $io) {
	my $r = $io->unlock( { file => $lock_file } );
	if ($r) {
	    my $t = time - $time_in;
	    if ($t > 1) {
		$curproc->logwarn("unlock requires $t sec.");
	    }

	    delete $LockInfo{ $channel };
	    $curproc->logdebug("unlock channel=$channel");
	}
	else {
	    $curproc->logerror("cannot unlock");
	    croak("Error: cannot unlock");
	}
    }
    else {
	$curproc->logerror("object undefined, cannot unlock channel=$channel");
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

    # default lock channel to ensure the existence of channel.
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

=head2 event_get_timeout( $channel )

=head2 event_set_timeout( $channel, $time )

=cut


# Descriptions: event sleeping at $channel should be waked up ?
#    Arguments: OBJ($curproc) STR($channel)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_event_timeout
{
    my ($curproc, $channel) = @_;
    my $t = $curproc->event_get_timeout($channel);

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
sub event_get_timeout
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
sub event_set_timeout
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


=head2 credential_verify_sender($args)

validate the mail sender (From: in the header not SMTP SENEDER).  If
valid, it sets the adddress within $curproc->credential() object as
a side effect.

=cut

# Descriptions: validate the sender address and do a few things
#               as a side effect.
#    Arguments: OBJ($curproc)
# Side Effects: set the return value of $curproc->sender().
#               stop the current process if needed.
# Return Value: none
sub credential_verify_sender
{
    my ($curproc) = @_;
    my $header    = $curproc->incoming_message_header();
    my $from      = $header->get('from');

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

	# check if $from should match safe address regexp.
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	if ($safe->regexp_match('address', $from)) {
	    # o.k. From: is proven to be valid now.
	    my $cred = $curproc->credential();
	    $cred->set( 'sender', $from );
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

loop checks the following rules of
$config->{ incoming_mail_header_loop_check_rules }.
The autual check is done by header->C<$rule()> for a C<rule>.
See C<FML::Header> object for more details.

=cut


# Descriptions: top level dispatcher for simple loop checks.
#    Arguments: OBJ($curproc)
# Side Effects: stop the current process if needed.
# Return Value: none
sub simple_loop_check
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $header    = $curproc->incoming_message_header();
    my $rules     =
	$config->get_as_array_ref( 'incoming_mail_header_loop_check_rules' );
    my $match     = 0;

    if ($config->yes('use_incoming_mail_header_loop_check')) {
      RULE:
	for my $rule (@$rules) {
	    if ($header->can($rule)) {
		$match = $header->$rule($config) ? $rule : 0;
	    }
	    else {
		$curproc->logwarn("header->${rule}() is undefined");
	    }

	    last RULE if $match;
	}
    }

    # This $match contains the first matched rule name (== reason).
    if ($match) {
	# we should stop this process ASAP.
	$curproc->stop_this_process();
	$curproc->logerror("mail loop detected for $match");
    }
}


# Descriptions: commit message-id cache update transaction.
#    Arguments: OBJ($curproc)
# Side Effects: update cache.
# Return Value: none
sub _commit_message_id_cache_update_transaction
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $header    = $curproc->incoming_message_header();

    # XXX-TODO: more granulated
    if (defined $header) {
	if ($header->can('update_message_id_cache')) {
	    $header->update_message_id_cache($config);
	}
    }
}


=head2 ml_variables_resolve( $args )

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
#    Arguments: OBJ($curproc) HASH_REF($resolver_args)
# Side Effects: update $config->{ ml_* } variables.
# Return Value: none
sub ml_variables_resolve
{
    my ($curproc, $resolver_args) = @_;
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
    my ($command, @options, $config_cf_path);
    my $config  = $curproc->config();
    my $myname  = $curproc->myname();
    my $ml_addr = '';

    # XXX-TODO: HARD-CODED.
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
		$ml_addr = sprintf("%s%s%s", $ml_name, '@', $default_domain);
	    }
	}
    }
    else {
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;

	# XXX the first match entry of ml_addr, o.k. ?
	# "fmlconf -n elena@fml.org" works ? yes
	# "fmlconf -n elena" works ?         yes
	# what is a wrong case ???
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
		    $ml_addr = sprintf("%s%s%s", $arg, '@', $default_domain);
		}
	    }
	}
    } # if myname eq 'fml', ...

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

	# we try to fallback something when config.cf not exists.
	# Example: when fml.pl firstly runs without config.cf (fml8) file,
	#          fml.pl should generate config.cf and continue to run.
	my $config_ph_path = $config_cf_path;
	$config_ph_path    =~ s/config.cf/config.ph/;
	use File::stat;
	my $stat_ph = -f $config_ph_path ? stat($config_ph_path) : undef;
	my $stat_cf = -f $config_cf_path ? stat($config_cf_path) : undef;
	if ((! -f $config_cf_path) ||
	    (defined $stat_ph && defined $stat_cf &&
	     $stat_ph->mtime > $stat_cf->mtime)) {
	    my $fallback       = $resolver_args->{ fallback } || undef;
	    my $fallback_args  = {
		config_cf_path => $config_cf_path,
	    };
	    if (defined $fallback) {
		eval q{ $curproc->$fallback($fallback_args); };
		$curproc->logerror($@) if $@;
	    }

	    unless (-f $config_cf_path) {
		$curproc->logerror("config.cf not exist");
		croak("config.cf not exist");
		return undef;
	    }
	}

	# [1.2.b.2]
	# lastly, we need to determine $ml_name and $ml_domain.
	# parse the argument such as "fml.pl /var/spool/ml/elena ..."
	unless ($ml_name) {
	    $curproc->logdebug("parse ARGV = ( @ARGV )");

	  ARGS:
	    for my $arg (@ARGV) {
		last ARGS if $ml_name;
		next ARGS if $arg =~ /^\-/o; # options

		# the first directory name e.g. /var/spool/ml/elena
		if (-d $arg) {
		    my $default_domain = $curproc->default_domain();

		    use File::Spec;
		    my $_cf_path = File::Spec->catfile($arg, "config.cf");

		    if (-f $_cf_path) {
			$config_cf_path = $_cf_path;

			use File::Basename;
			$ml_name     = basename( $arg );
			$ml_home_dir = dirname( $arg );

			$config->set( 'ml_name',     $ml_name );
			$config->set( 'ml_domain',   $default_domain );
			$config->set( 'ml_home_dir', $arg );

			my $s = "ml_name=$ml_name ml_home_dir=$ml_home_dir";
			$curproc->logdebug("(debug) $s");
		    }
		}
	    }
	}
    }

    if ($config_cf_path) {
	# debug
	$curproc->__debug_ml_xxx('resolv:');

	# add this ml's config.cf to the .cf list.
	$curproc->config_cf_files_append($config_cf_path);
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
	for my $buf (@delayed_buffer) { $curproc->logdebug( $buf ); }
	@delayed_buffer = ();

	for my $var (qw(ml_name ml_domain ml_home_prefix ml_home_dir)) {
	    $curproc->logdebug(sprintf("%-25s = %s",
				       "(debug)$str $var",
				       (defined $config->{ $var } ?
					$config->{ $var } :
					'')));
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
    my ($curproc)      = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix();
    my $ml_home_dir    = '';
    my $found_cf       = 0;
    my @cf             = ();

    # Example: "elena" is translated to "/var/spool/ml/elena"
  ARGV:
    for my $argv (@ARGV) {
	# 1. for the first time
	#  a) speculate "/var/spool/ml/$argv" looks a $ml_home_dir
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
	    my $cf = File::Spec->catfile($argv, "config.cf");
	    if (-f $cf) {
		$found_cf    = 1;
		$ml_home_dir = $argv;
		push(@cf, $cf);
	    }
	}
	# 3. looks a file, so /var/spool/ml/elena/config.cf ?
	elsif (-f $argv && $argv =~ /\.cf$/o) {
	    $curproc->logwarn("argv ($argv) is a config.cf ?");
	    use File::Basename;
	    $ml_home_dir = dirname($argv);
	    push(@cf, $argv);
	}
	# 4. unknown case.
	else {
	    $curproc->logdebug("unknown argv: $argv");
	}
    }

    return {
	ml_home_dir => $ml_home_dir,
	cf_list     => \@cf,
    };
}


=head2 config_cf_files_load($files)

read several configuration C<@$files>.
The variable evaluation (expansion) is done on demand when
$config->get() of FETCH() method is called.

=cut

# Descriptions: load configuration files and evaluate variables.
#    Arguments: OBJ($curproc) ARRAY_REF($files)
# Side Effects: none
# Return Value: none
sub config_cf_files_load
{
    my ($curproc, $files) = @_;
    my $config = $curproc->config();
    my $_files = $files || $curproc->config_cf_files_get_list();

    # load configuration variables from given files e.g. /some/where.cf
    # XXX overload variables from each $cf
    for my $cf (@$_files) {
	$config->overload( $cf );
    }

    #  overwrite variables by -o options (2)
    my $options = $curproc->command_line_options();
    if (defined $options->{ o }) {
	my ($k, $v);
	my $opts = $options->{ o } || {};
	while (($k, $v) = each %$opts) { $config->set($k, $v);}
    }

    # XXX We need to expand variables after we load all *cf files.
    # XXX 2001/05/05 changed to dynamic expansion for hook
    # $curproc->config()->expand_variables();
    if ($curproc->is_under_mta_process()) {
	# XXX simple sanity check
	#     MAIL_LIST != MAINTAINER
	my $maintainer = $config->{ maintainer }           || '';
	my $ml_address = $config->{ article_post_address } || '';

	unless ($maintainer) {
	    my $s = "configuration error: \$maintainer undefined";
	    $curproc->logerror($s);
	    $curproc->stop_this_process("configuration error");
	}

	use FML::Credential;
	my $cred = $curproc->credential();
	my $s = "configuration error: \$maintainer == \$article_post_address";
	if ($maintainer && $ml_address) {
	    if ($cred->is_same_address($maintainer, $ml_address)) {
		$curproc->logerror($s);
		$curproc->stop_this_process("configuration error");
	    }
	}
    }
}


# Descriptions: add ml local library path into @INC
#    Arguments: OBJ($curproc)
# Side Effects: update @INC
# Return Value: none
sub env_fix_perl_include_path
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


=head2 incoming_message_parse()

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
sub incoming_message_parse
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # XXX firstly, mail queue in.
    my $use_mail_queue = 1;
    my $queue          = undef;
    my $queue_id       = undef;
    my $queue_file     = undef;
    if ($use_mail_queue) {
	$queue      = $curproc->_store_message_into_incoming_queue();
	$queue_id   = $queue->id();
	$queue_file = $queue->incoming_file_path($queue_id);
    }

    # open input stream.
    my $incoming_channel = undef;
    if ($use_mail_queue && (defined $queue)) {
	$incoming_channel = $queue->open("incoming", { mode => "r" });
    }
    else {
	$incoming_channel = *STDIN{IO};
    }

    unless (defined $incoming_channel) {
	$curproc->logerror("cannot open incoming stream");
	$curproc->exit_as_tempfail();
    }

    # parse incoming mail to cut off it to the header and the body.
    # malloc the incoming message on memory.
    use FML::Parse;
    my $msg = new FML::Parse $curproc, $incoming_channel;

    # store the message to $curproc
    $curproc->{ incoming_message }->{ message } = $msg;
    $curproc->{ incoming_message }->{ header  } = $msg->whole_message_header;
    $curproc->{ incoming_message }->{ body  }   = $msg->whole_message_body;

    # save input message for further investigation
    if ($config->yes('use_incoming_mail_cache')) {
	my $dir     = $config->{ incoming_mail_cache_dir };
	my $modulus = $config->{ incoming_mail_cache_size };
	use FML::Cache::Ring;
        my $cache     = new FML::Cache::Ring {
            directory => $dir,
	    modulus   => $modulus,
        };

	if (defined $cache) {
	    my $r = 0; # result code.

	    # 1. try link(2)
	    if ($use_mail_queue) {
		$cache->open();
		$r = $cache->add({
		    file     => $queue_file,
		    try_link => 'yes',
		});
	    }

	    # 2. copy if link(2) failed.
	    unless ($r) {
		$curproc->logwarn("link(2) error");
		my $wh = $cache->open();
		if (defined $wh) {
		    $msg->print($wh);
		    $wh->close();
		    $cache->close();
		}
	    }

	    # XXX "my $path = $obj->cache_file_path();" is wrong.
	    # old implementation saves the FML::Cache::Ring file path
	    # for later use. But it is ambiguous. When many processes
	    # (> modules) runs simultaneously, $path may be
	    # overwritten by the next content. Instead, use $queue_file
	    # since $queue_file (queue/incoming/ID) is unique.
	    $curproc->incoming_message_set_cache_file_path($queue_file);
	}
    }

    # use Content-Type: and Accept-Language: as hints.
    if (defined $msg) {
	$curproc->_inject_charset_hints($msg);
    }
}


# Descriptions:
#    Arguments: OBJ($curproc)
# Side Effects: exit_as_tempfail() if error.
# Return Value: OBJ
sub _store_message_into_incoming_queue
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    use Mail::Delivery::Queue;
    my $queue_dir  = $config->{ mail_queue_dir };
    my $queue      = new Mail::Delivery::Queue { directory => $queue_dir };
    my $queue_id   = $queue->id();
    my $total      = 0;
    my $fatal      = 0;

    # write to queue file.
    my $wh = undef;
    if (defined $queue) {
	$wh = $queue->open("incoming", { mode => "w" });
    }
    if (defined $wh) {
	my $n = 0;
	my $w = 0;
	my $buf;

	$wh->autoflush(1);
	while ($n = sysread(*STDIN{IO}, $buf, 8192)) {
	    $total += $n;
	    $w = syswrite($wh, $buf, 8192) || 0;
	    unless ($w == $n) {
		$fatal = 1;
	    }
	}
	$wh->close();
    }
    else {
	$curproc->logerror("cannot open queue_file qid=$queue_id");
	$fatal = 1;
    }

    unless ($fatal) {
	$curproc->logdebug("queued/incoming: qid=$queue_id read=$total");
	$curproc->incoming_message_set_current_queue($queue);
    }
    else {
	$curproc->logerror("failted to store incoming message");
	$curproc->exit_as_tempfail();
    }
}


# Descriptions: inject charset hints picked up from message header.
#    Arguments: OBJ($curproc) OBJ($msg)
# Side Effects: update corresponding PCB fields.
# Return Value: none
sub _inject_charset_hints
{
    my ($curproc, $msg) = @_;
    my $charset = $msg->charset() || '';
    my $list    = $msg->accept_language_list() || [];
    my $liststr = join("", @$list);

    $curproc->logdebug("hints: charset=\"$charset\" accept_language=[$liststr]");

    # 1. prefer Accept-Language: alyways, ignore Content-Type: in this case.
    #    set $list even if $list == [] to avoid further warning.
    $curproc->langinfo_set_accept_language_list($list);

    # 2. save charset of Content-Type: as a hint.
    if ($charset) {
	# validate charset usage.
	#   iso-2022-jp -> japanese -> iso-2022-jp
	#   sjis        -> japanese -> iso-2022-jp
	#   euc-jp      -> japanese -> iso-2022-jp
	use Mail::Message::Charset;
	my $char = new Mail::Message::Charset;
	my $lang = $char->message_charset_to_language($charset);

	$curproc->logdebug("hints: \"$charset\" => lang=\"$lang\" as a hint.");
	$curproc->langinfo_set_language_hint('reply_message', $lang);
	$curproc->langinfo_set_language_hint('template_file', $lang);
    }
    else {
	$curproc->langinfo_set_language_hint('reply_message', '');
	$curproc->langinfo_set_language_hint('template_file', '');
    }
}


=head1 CREDENTIAL

=head2 is_premit_post()

permit posting.
The restriction rules follows the order of C<article_post_restrictions>.

=cut


# Descriptions: permit this post process
#    Arguments: OBJ($curproc)
# Side Effects: set the error reason at "check_restriction" in pcb.
# Return Value: STR
sub is_permit_post
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $cred      = $curproc->credential(); # user credential
    my $sender    = $cred->sender();
    my $rules     = $config->get_as_array_ref( "article_post_restrictions" );

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
	    $curproc->logdebug("match rule=$rule sender=$sender");
	    return($result);
	}
    }

    return ''; # deny by default
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
	$msg_queue->add($msg);
    }
    else {
	my $debug = $curproc->_get_debug_level();
	if ($debug > 1) {
	    print STDERR "msg: ", $msg->{ buf }, "\n";
	}
    }
}


# Descriptions: print contents in log message queue.
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
    elsif ($level eq 'debug') {
	Log($msg);
    }

    # update message queue
    $curproc->_log_message_queue_append({
	time  => time,
	buf   => $msg,
	level => $level,
	hints => {
	    at_package  => $at_package,
	    at_function => $at_function,
	    at_line     => $at_line,
	},
    });
}


# Descriptions: log message.
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


# Descriptions: log message as debug.
#    Arguments: OBJ($curproc) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logdebug
{
    my ($curproc, $msg, $msg_args) = @_;
    my $config = $curproc->config();
    my (@c)    = caller;

    if ($config->yes('use_debug')) {
	my ($package, $filename, $line) = @c;

	# XXX-TODO: ok? how to implement debug mask.
	my $re = $config->get_as_array_ref('debug_module_regexp_list') || [];
	if (@$re) {
	    my $regexp = '';
	    for my $re (@$re) { $regexp .= $regexp ? "|^$re\$" : "^$re\$";}
	    if ($package =~ /($regexp)/) {
		$curproc->log_message($msg, {
		    msg_args => $msg_args,
		    level    => 'debug',
		    caller   => \@c,
		});
	    }
	}
	else {
	    $curproc->log_message($msg, {
		msg_args => $msg_args,
		level    => 'debug',
		caller   => \@c,
	    });
	}
    }
}


# Descriptions: log informational message CUI shows
#               and forward it into STDERR, too.
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


=head1 REPLY MESSAGES

=head2 reply_message($msg)

C<reply_message($msg)> holds message C<$msg> sent back to the mail
sender.

To send a plain text,

    $curproc->reply_message( "message" );

but to attach an image file, please use in the following way:

    $curproc->reply_message( {
	type        => "image/gif",
	path        => "aaa00123.gif",
	filename    => "logo.gif",
	disposition => "attachment",
    });

If you attach a plain text with the charset = iso-2022-jp,

    $curproc->reply_message( {
	type        => "text/plain; charset=iso-2022-jp",
	path        => "/etc/fml/main.cf",
	filename    => "main.cf",
	disposition => "main.cf example",
    });

=head3 CAUTION

makefml/fml not support message handling not yet.
If given, makefml/fml ignores message output.

=cut


# Descriptions: top level reply message interface.
#               It injects the specified message into the system
#               global message queue on memory in fact.
#               reply_message_inform() recollects them and send it later.
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args)
# Side Effects: none
# Return Value: none
sub reply_message
{
    my ($curproc, $msg, $rm_args) = @_;
    my $lang_list = $curproc->_get_preferred_languages();

    for my $lang (@$lang_list) {
	my $rm_charset = $curproc->_lang_to_charset("report_mail",   $lang);
	my $tf_charset = $curproc->_lang_to_charset("template_file", $lang);
	my $charsets = {
	    reply_message_charset => $rm_charset,
	    template_file_charset => $tf_charset,
	};

	$curproc->_reply_message_queuein($msg, $rm_args, $charsets);
    }
}


# Descriptions: reply message interface for each charset.
#               It injects messages into message queue on memory in fact.
#               reply_message_inform() recollects them and send it later.
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args) HASH_REF($charsets)
# Side Effects: none
# Return Value: none
sub _reply_message_queuein
{
    my ($curproc, $msg, $rm_args, $charsets) = @_;
    my $myname = $curproc->myname();

    $curproc->caller_info($msg, caller) if $debug;

    # process running under MTA can handle reply messages by mail.
    unless ($curproc->is_allow_reply_message()) {
	unless ($curproc->error_message_get_count("disable_reply_message")) {
	    $curproc->logwarn("(debug) $myname disables reply_message()");
	    $curproc->error_message_set_count("disable_reply_message");
	}
	return;
    }

    # get recipients list
    my ($recipient,$recipient_maps) = $curproc->_analyze_recipients($rm_args);
    my $hdr                         = $curproc->_analyze_header($rm_args);

    # check text messages and fix if needed.
    unless (ref($msg)) {
	# \n in the last always.
	$msg .= "\n" unless $msg =~ /\n$/o;
    }

    $curproc->_append_message_into_queue2($msg, $rm_args,
					  $recipient, $recipient_maps,
					  $hdr,
					  $charsets);

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
						 $hdr,
						 $charsets);
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
	my $cred   = $curproc->credential();
	my $sender = $cred->sender();
	$recipient = [ $sender ];
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
#               ARRAY_REF($rcpt) ARRAY_REF($rcpt_maps) OBJ($hdr)
#               HASH_REF($charsets)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue
{
    my ($curproc, $msg, $rm_args, $rcpt, $rcpt_maps, $hdr, $charsets) = @_;
    my $pcb         = $curproc->pcb();
    my $category    = 'reply_message';
    my $class       = 'queue';
    my $rarray      = $pcb->get($category, $class) || [];
    my $smtp_sender = $rm_args->{ smtp_sender } || '';

    $rarray->[ $#$rarray + 1 ] = {
	message        => $msg,
	type           => ref($msg) ? ref($msg) : 'text',
	smtp_sender    => $smtp_sender,
	recipient      => $rcpt,
	recipient_maps => $rcpt_maps,
	header         => $hdr,
	charset        => $charsets->{ reply_message_charset },
    };

    $pcb->set($category, $class, $rarray);
}


# Descriptions: add the specified $msg into on memory queue
#    Arguments: OBJ($curproc) OBJ($msg) HASH_REF($rm_args)
#               ARRAY_REF($rcpt) ARRAY_REF($rcpt_maps) OBJ($hdr)
#               HASH_REF($charsets)
# Side Effects: update on momory queue which is on PCB area.
# Return Value: none
sub _append_message_into_queue2
{
    my ($curproc, $msg, $rm_args, $rcpt, $rcpt_maps, $hdr, $charsets) = @_;
    my $pcb         = $curproc->pcb();
    my $category    = 'reply_message';
    my $class       = 'queue';
    my $rarray      = $pcb->get($category, $class) || [];
    my $smtp_sender = $rm_args->{ smtp_sender } || '';

    for my $rcpt (@$rcpt) {
	$rarray->[ $#$rarray + 1 ] = {
	    message        => $msg,
	    type           => ref($msg) ? ref($msg) : 'text',
	    smtp_sender    => $smtp_sender,
	    recipient      => [ $rcpt ],
	    recipient_maps => [],
	    header         => $hdr,
	    charset        => $charsets->{ reply_message_charset },
	};
    }

    for my $map (@$rcpt_maps) {
	$rarray->[ $#$rarray + 1 ] = {
	    message        => $msg,
	    type           => ref($msg) ? ref($msg) : 'text',
	    smtp_sender    => $smtp_sender,
	    recipient      => [],
	    recipient_maps => [ $map ],
	    header         => $hdr,
	    charset        => $charsets->{ reply_message_charset },
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
    my $pcb         = $curproc->pcb();
    my $category    = 'reply_message';
    my $class       = 'queue';
    my $rarray      = $pcb->get($category, $class) || [];
    my %rcptattr    = ();
    my %rcptlist    = ();
    my %rcptmaps    = ();
    my %hdr         = ();
    my %smtp_sender = ();
    my ($rcptlist, $rcptmaps, $key, $type) = ();

    # mark identifier based on recipients into each message.  messages
    # with same identifier are aggregated into one mail message later.
    # XXX-TODO: we should identify messages based on {sender, recipients} ?
    # XXX-TODO: it may be annoying in some cases... hmm ;-)
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
	    $smtp_sender{ $key } = $m->{ smtp_sender } || '';
	}
    }

    return ( \%rcptattr, \%rcptlist, \%rcptmaps, \%hdr, \%smtp_sender );
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


# Descriptions: set reply message with translation to natual language.
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($rm_args)
# Side Effects: none
# Return Value: none
sub reply_message_nl
{
    my ($curproc, $class, $default_msg, $rm_args) = @_;
    my $lang_list = $curproc->_get_preferred_languages();

    for my $lang (@$lang_list) {
	my $rm_charset = $curproc->_lang_to_charset("report_mail",   $lang);
	my $tf_charset = $curproc->_lang_to_charset("template_file", $lang);
	my $charsets = {
	    reply_message_charset => $rm_charset,
	    template_file_charset => $tf_charset,
	};

	my $s = "lang=$lang charset=($rm_charset, $tf_charset) class=$class";
	$curproc->logdebug("reply_message_nl: $s") if $rm_debug;
	$curproc->_reply_message_nl($class, $default_msg, $rm_args, $charsets);
    }
}


# Descriptions: set reply message with translation to natual language.
#    Arguments: OBJ($curproc)
#               STR($class) STR($default_msg) HASH_REF($rm_args)
#               HASH_REF($charsets)
# Side Effects: none
# Return Value: none
sub _reply_message_nl
{
    my ($curproc, $class, $default_msg, $rm_args, $charsets) = @_;
    my $buf = $curproc->__convert_message_nl($class,
					     $default_msg,
					     $rm_args,
					     $charsets);

    $curproc->caller_info($class, caller) if $debug;

    if (defined $buf) {
	if ($buf =~ /\$/o) {
	    my $config = $curproc->config();
	    $config->expand_variable_in_buffer(\$buf, $rm_args);
	}

	eval q{
	    use Mail::Message::String;
	    my $str = new Mail::Message::String $buf;
	    $str->charcode_convert_to_external_charset();
	    $buf = $str->as_str();

	    $curproc->_reply_message_queuein($buf, $rm_args, $charsets);
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->_reply_message_queuein($buf, $rm_args, $charsets);
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


# Descriptions: translate template message in natual language.
#    Arguments: OBJ($curproc) STR($class) STR($default_msg) HASH_REF($m_args)
# Side Effects: none
# Return Value: STR
sub message_nl
{
    my ($curproc, $class, $default_msg, $m_args) = @_;
    my $charset  = $curproc->langinfo_get_charset("template_file");
    my $charsets = {
	template_file_charset => $charset,
    };

    $curproc->__convert_message_nl($class, $default_msg, $m_args, $charsets);
}


# Descriptions: translate template message in natual language.
#    Arguments: OBJ($curproc)
#               STR($class) STR($default_msg) HASH_REF($m_args)
#               HASH_REF($charsets)
# Side Effects: none
# Return Value: STR
sub __convert_message_nl
{
    my ($curproc, $class, $default_msg, $m_args, $charsets) = @_;
    my $config    = $curproc->config();
    my $dir       = $config->{ message_template_dir };
    my $local_dir = $config->{ ml_local_message_template_dir };
    my $charset   = $charsets->{ template_file_charset };
    my $buf       = '';
    my $_m_args   = {};

    use File::Spec;
    $class =~ s@\.@/@g; # XXX . -> /

    my $local_file = File::Spec->catfile($local_dir, $charset, $class);
    my $file       = File::Spec->catfile($dir,       $charset, $class);

    # override message: replace default one with ml local message template
    if (-f $local_file) { $file = $local_file;}

    # import message template
    if (-f $file) {
	$buf = $curproc->__import_message_from_file($file);
    }
    else {
	$curproc->logwarn("no such file: $file");
    }

    # copy $m_args -> $_m_args;
    my ($k, $v);
    while (($k, $v) = each %$m_args) {
	# TERM_NL(XXX) -> XXX(natural language) or XXX (if failed);
	if ($v =~ /TERM_NL\((\S+)\)/o) {
	    my $x  = $1;
	    my $lf = File::Spec->catfile($local_dir, $charset, "term", $x);
	    my $f  = File::Spec->catfile($dir,       $charset, "term", $x);
	    if (-f $lf) { $f = $lf;}
	    $v = $curproc->__import_message_from_file($f) || $x;
	    $v =~ s/[\s\n]*$//o;
	}
	$_m_args->{ $k } = $v;
    }

    if (defined $buf) {
	my $config = $curproc->config();
        if ($buf =~ /\$/o) {
            $config->expand_variable_in_buffer(\$buf, $_m_args);
        }
    }

    return( $buf || $default_msg || '' );
}


# Descriptions: get message from file.
#    Arguments: OBJ($curproc) STR($file)
# Side Effects: none
# Return Value: STR
sub __import_message_from_file
{
    my ($curproc, $file) = @_;
    my $buf = '';

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	my $xbuf;
	while ($xbuf = <$fh>) { $buf .= $xbuf;}
	$fh->close();
    }

    return $buf;
}


=head2 reply_message_delete

delete message queue matched by the specified condition.

=cut


# Descriptions: delete message queue matched by the specified condition.
#    Arguments: OBJ($curproc) HASH_REF($condition)
# Side Effects: none
# Return Value: none
sub reply_message_delete
{
    my ($curproc, $condition) = @_;
    my $pcb      = $curproc->pcb();
    my $category = 'reply_message';
    my $class    = 'queue';
    my $queue    = $pcb->get($category, $class) || [];

    unless (defined $condition) {
	$pcb->set($category, $class, []);
	return;
    }

    my $queue_fixed = [];
  QUEUE:
    for my $q (@$queue) {
	if (defined $condition->{ smtp_sender }) {
	    if ($q->{ smtp_sender } eq $condition->{ smtp_sender }) {
		$curproc->log("debug: reply_message_delete: $q");
		next QUEUE;
	    }
	}
	if (defined $condition->{ recipient }) {
	    if ($q->{ recipient } eq $condition->{ recipient }) {
		$curproc->log("debug: reply_message_delete: $q");
		next QUEUE;
	    }
	}

	push(@$queue_fixed, $q);
    }
    
    $pcb->set($category, $class, $queue_fixed);
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


# Descriptions: return preferred languages e.g. [ ja ], [ ja en ]...
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_preferred_languages
{
    my ($curproc)  = @_;
    my $config     = $curproc->config();
    my $pref_order = $config->get_as_array_ref('language_preference_order');

    # hints
    #   $pref_order     = [ ja en ]
    #   $acpt_lang_list = [ ja en ]
    #   $mime_lang      = ja        ('en' if no mime charset).
    my $acpt_lang_list = $curproc->langinfo_get_accept_language_list() || [];
    my $mime_lang      = $curproc->langinfo_get_language_hint('reply_message') || 'en';

    # return = [ ja ] or [ ja en ] ...
    my $p = $curproc->__find_preferred_languages($pref_order,
						 $acpt_lang_list,
						 $mime_lang);
    $curproc->logdebug("hints: preferred language = [ @$p ]")
	unless $first_time++;
    return $p;
}


# Descriptions: return preferred charsets e.g. iso-2022-jp, us-ascii, ...
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_preferred_charsets
{
    my ($curproc)  = @_;
    my $lang_order = $curproc->_get_preferred_languages();
    my $list       = [];

    use Mail::Message::Charset;
    my $c = new Mail::Message::Charset;
    for my $lang (@$lang_order) {
	my $x = $c->language_to_message_charset($lang);
	push(@$list, $x);
    }

    return $list;
}


# Descriptions: return preferred languages e.g. [ ja ], [ ja en ]...
#    Arguments: OBJ($curproc)
#               ARRAY_REF($pref_order)
#               ARRAY_REF($acpt_lang_list)
#               ARRAY_REF($mime_lang)
# Side Effects: none
# Return Value: ARRAY_REF
sub __find_preferred_languages
{
    my ($curproc, $pref_order, $acpt_lang_list, $mime_lang) = @_;
    my $orig_mime_lang = $mime_lang;
    my $selected       = [];

    # 0. fix
    $mime_lang ||= 'en';

    # 1. prefer Accept-Languge: always.
    if (@$acpt_lang_list) {
	if ($acpt_lang_list->[ 0 ]) {
	    my $x = $acpt_lang_list->[ 0 ];
	    $selected = [ $x ] if $x =~ /^\w+$/;
	}
    }
    # 2. when no Accept-Language:
    elsif ($mime_lang) {
	# for (ja, en, ...) { ... }
      LANG:
	for my $lang (@$pref_order) {
	    push(@$selected, $lang);
	    last LANG if $lang eq $mime_lang;
	}
    }

    if ($debug) {
	print STDERR "      pref_order  = [ @$pref_order ]\n";
	print STDERR "accpet languages  = [ @$acpt_lang_list ]\n";
	print STDERR "  mime language   = \" $orig_mime_lang \"\n";
	print STDERR "preferred languge = [ @$selected ]\n";
	print STDERR "\n";
	$curproc->logdebug("pref_order=[@$pref_order]");
	$curproc->logdebug("acpt lang =[@$acpt_lang_list]");
	$curproc->logdebug("mime_lang=$orig_mime_lang selected=[@$selected]");
    }

    if (@$selected) {
	return $selected;
    }
    else {
	my $lang = $pref_order->[0];
	return [ $lang ];
    }
}


# Descriptions: convert lang (e.g. ja) to charset (e.g. iso-2022-jp).
#    Arguments: OBJ($curproc) STR($category) STR($lang)
# Side Effects: none
# Return Value: none
sub _lang_to_charset
{
    my ($curproc, $category, $lang) = @_;
    my $config  = $curproc->config();
    my $key     = sprintf("%s_charset_%s", $category, $lang);
    my $charset = $config->{ $key } || '';

    if ($charset) {
	return $charset;
    }
    else {
	my $s = "category=$category lang=$lang charset=none";
	$curproc->logerror("_lang_to_charset: $s");
	return 'us-ascii';
    }
}


=head2 reply_message_inform($args)

inform the error messages to the sender or maintainer.
C<reply_message_inform($args)> checks existence of message(s) of the
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
#               multipart/mixed if both "text" and "queue" are defined.
#               $r  = get(message, queue)
#               msg = header + "text" + $r->[0] + $r->[1] + ...
#
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub reply_message_inform
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
    my ($attr, $list, $maps, $hdr, $smtp_sender) =
	$curproc->_reply_message_recipient_keys();
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
		    smtp_sender    => $smtp_sender->{ $key },
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
    my $charset      = $curproc->langinfo_get_charset($category);
    my $myname       = $curproc->myname();
    my $_defsubj     = "message from fml8 $myname system";
    my $subject      = $config->{ "${category}_subject" } || $_defsubj;
    my $_rpto        = $config->{ command_mail_address };
    my $reply_to     = $config->{ outgoing_mail_header_reply_to }   || $_rpto;
    my $precedence   = $config->{ outgoing_mail_header_precedence } || 'bulk';
    my $errors_to    = $config->{ outgoing_mail_header_errors_to }  || $sender;
    my $message_id   = $curproc->_generate_message_id();
    my $is_multipart = 0;
    my $rcptkey      = '';
    my $rcptlist     = [];
    my $rcptmaps     = [];
    my $msg          = '';
    my $hdr_to       = '';
    my $smtp_sender  = '';

    use Mail::Message::Date;
    my $_nowdate     = new Mail::Message::Date time;
    my $our_date     = $_nowdate->{ mail_header_style };
    my $stardate     = $_nowdate->stardate();

    # override parameters (may be processed here always)
    if (defined $optargs) {
	my $a = $optargs;
	my $h = $optargs->{ header };
	my $c = $optargs->{ header }->{ 'content-type' };

	# override header parameters
	$sender    = $h->{'sender'}         if defined $h->{'sender'};
	$subject   = $h->{'subject'}        if defined $h->{'subject'};
	$hdr_to    = $h->{'to'}             if defined $h->{'to'};
	$reply_to  = $h->{'reply-to'}       if defined $h->{'reply-to'};
	$charset   = $c->{'charset'}        if defined $c->{'charset'};
	$rcptkey   = $a->{'recipient_key'}  if defined $a->{'recipient_key'};
	$rcptlist  = $a->{ recipient_list } if defined $a->{'recipient_list'};
	$rcptmaps  = $a->{ recipient_maps } if defined $a->{'recipient_maps'};

	# override smtp_sender
	$smtp_sender = $optargs->{ smtp_sender } || '';

	# we need multipart style or not ?
	if (defined $a->{'recipient_attr'}) {
	    my $attr = $a->{ recipient_attr }->{ $rcptkey };

	    # count up non text message in the queue
	    for my $attr (keys %$attr) {
		$is_multipart++ if $attr;
	    }
	}
    }

    # use multipart if plural languages are used.
    {
	my $mesg_queue = $pcb->get($category, 'queue');
	my %lang_count = ();

	for my $m ( @$mesg_queue ) {
	    my $c = $m->{ charset };
	    $lang_count{ $c }++ if defined $c;
	}

	my @lang = keys %lang_count;
	if ($#lang > 0) {
	    $curproc->logdebug("plural languages, so use mulitpart");
	    $is_multipart = 1;
	}
    }

    # default recipient if undefined.
    unless ($rcptkey) {
	my $cred   = $curproc->credential();
	my $sender = $cred->sender() || undef;
	if (defined $cred) {
	    $rcptkey = $sender;
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


    $curproc->logdebug("queue_in: sender=$sender");
    $curproc->logdebug("queue_in: recipient=$rcptkey");
    $curproc->logdebug("queue_in: rcptlist=[ @$rcptlist ]");
    $curproc->logdebug("queue_in: is_multipart=$is_multipart");


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
		From          => $sender,
		To            => $_to,
		Subject       => $subject,
		"Errors-To:"  => $errors_to,
		"Precedence:" => $precedence,
		"X-Stardate:" => $stardate,
		"Message-Id:" => $message_id,
		Type          => "multipart/mixed",
	        Datestamp     => undef,
	};
	$msg->add('Reply-To' => $reply_to);
	$msg->add('Date' => $our_date);
	_add_info_on_header($config, $msg);

	my $mesg_queue = $pcb->get($category, 'queue');
	my %s = ();
	my $s = '';

      QUEUE:
	for my $m ( @$mesg_queue ) {
	    my $q = $m->{ message };
	    my $t = $m->{ type };
	    my $c = $m->{ charset };
	    my $r = $curproc->_gen_recipient_key($m->{ recipient },
						 $m->{ recipient_maps } );

	    # pick up only messages returned to specified $rcptkey
	    next QUEUE unless $r eq $rcptkey;

	    if ($t eq 'text') {
		$s{ $c } .= $q;
		$s       .= $q;
	    }
	}

	# 1. eat up text messages and put them into the first part.
	# XXX-TODO: wrong handling of $charset ???
	# XXX-TODO: reply message should be determined by context and
	# XXX-TODO: accept-language: information.
	if ($s) {
	    # use [ iso-2022-jp us-ascii ] not [ ja en ] list.
	    my $list = $curproc->_get_preferred_charsets();
	    for my $charset (@$list) {
		if ($s{$charset}) {
		    $msg->attach(Type => "text/plain; charset=$charset",
				 Data => $s{$charset},
				 );
		}
	    }
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
		    $curproc->logerror("queue_in: unknown type=<$t>") unless $t eq 'text';
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
		# XXX-TODO: meaningless ?
		$curproc->_append_rfc822_message($q, $msg);
	    }
	    else {
		if ($t eq 'text') {
		    $s .= $q;
		}
		else {
		    $curproc->logerror("queue_in: unknown type $t");
		}
	    }
	}

	my $_to = $hdr_to || $rcptkey;
	eval q{
	    $msg = new Mail::Message::Compose
		From          => $sender,
		To            => $_to,
		Subject       => $subject,
		"Errors-To:"  => $errors_to,
		"Precedence:" => $precedence,
		"X-Stardate:" => $stardate,
		"Message-Id:" => $message_id,
		Data          => $s,
	        Datestamp     => undef,
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
	$queue->set('sender', $smtp_sender || $sender);

	if ($rcptlist) {
	    $queue->set('recipients', $rcptlist);
	}

	# $rcptlist and $rcptmaps duplication is ok.
	if ($rcptmaps) {
	    $queue->set('recipient_maps', $rcptmaps);
	}

	$queue->in( $msg ) && $curproc->logdebug("queued/new: qid=$qid");
	if ($queue->setrunnable()) {
	    $curproc->logdebug("queued/active: qid=$qid runnable");
	}
	else {
	    $curproc->logerror("queue: qid=$qid broken");
	}

	# return queue object
	return $queue;
    }
    else {
	return undef;
    }
}


# Descriptions: append message in $msg_in into $msg_out.
#    Arguments: OBJ($curproc) OBJ($msg_in) OBJ($msg_out)
# Side Effects: create a new $tmpfile
#               update garbage collection queue (cleanup_queue)
# Return Value: none
sub _append_rfc822_message
{
    my ($curproc, $msg_in, $msg_out) = @_;
    my $tmpfile = $curproc->tmp_file_path();

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
    }
    else {
	$curproc->logerror("_append_rfc822_message: \$tmpfile not found");
    }
}


# Descriptions: insert $file into garbage collection queue (cleanup_queue).
#    Arguments: OBJ($curproc) STR($file)
# Side Effects: update $curproc->{ __tmp_file_cleanup };
# Return Value: none
sub _add_into_cleanup_queue
{
    my ($curproc, $file) = @_;
    my $queue = $curproc->{ __tmp_file_cleanup };

    if (defined $queue) {
	push(@$queue, $file);
    }
    else {
	$curproc->{ __tmp_file_cleanup } = [ $file ];
    }
}


# Descriptions: generate a new Message-ID: string and cache it in our database.
#    Arguments: OBJ($curproc)
# Side Effects: update message_id cache.
# Return Value: STR
sub _generate_message_id
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # generate a new message-id string.
    use FML::Header::MessageID;
    my $mid = FML::Header::MessageID->new->gen_id($config);

    # insert generated message-id into the cache.
    use FML::Header;
    my $header = new FML::Header;
    my $_mid   = $header->address_cleanup($mid);
    $header->insert_message_id_cache($config, $_mid);

    # return generated message-id.
    return $mid;
}


# Descriptions: remove garbage collection queue (cleanup_queue).
#    Arguments: OBJ($curproc)
# Side Effects: remove files in $curproc->{ __tmp_file_cleanup }
# Return Value: none
sub tmp_file_cleanup
{
    my ($curproc) = @_;
    my $queue = $curproc->{ __tmp_file_cleanup };

    if (defined $queue) {
	for my $q (@$queue) {
	    $curproc->logdebug("unlink $q");
	    unlink $q;
	}
    }

    # XXX ONLY WHEN VALID $ml_home_dir EXISTS.
    # clean up tmp_dir.
    if ($curproc->_is_valid_ml_home_dir()) {
	my $channel = "cleanup_tmp_dir";
	if ($curproc->is_event_timeout($channel)) {
	    my $config   = $curproc->config();
	    my $tmp_dir  = $config->{ tmp_dir };
	    $curproc->_delete_too_old_files_in_dir($tmp_dir);
	    $curproc->event_set_timeout($channel, time + 24*3600);
	}
    }
}


# Descriptions: remove incoming queue managed by Mail::Delivery::Queue.
#    Arguments: OBJ($curproc)
# Side Effects: remove incoming queue.
# Return Value: none
sub incoming_message_cleanup_queue
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $channel   = 'mail_incoming_queue_cleanup';

    # XXX ONLY WHEN VALID $ml_home_dir EXISTS.
    if ($curproc->_is_valid_ml_home_dir()) {
	# 1. remove incoming queue files.
	# 2. remove queues marked as removal in incoming/ queue.
	#    XXX cond. 1 must include cond. 2,
	#    XXX but we try again to ensure garbage collection.
	$curproc->incoming_message_remove_queue();

	# 3. remove too old incoming queue files.
	if ($curproc->is_event_timeout($channel)) {
	    my $fp = sub { $curproc->log(@_);};

	    use Mail::Delivery::Queue;
	    my $queue_dir = $config->{ mail_queue_dir };
	    my $queue     = new Mail::Delivery::Queue {
		directory => $queue_dir,
	    };
	    $queue->set_log_function($fp);
	    $queue->cleanup();
	    $curproc->event_set_timeout($channel, time + 24*3600);
	}
    }
}


# Descriptions: check if the valid ml_home_dir exists?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub _is_valid_ml_home_dir
{
    my ($curproc)   = @_;
    my $config      = $curproc->config();
    my $ml_home_dir = $config->{ ml_home_dir };
    my $cf          = File::Spec->catfile($ml_home_dir, "config.cf");

    if (-d $ml_home_dir && -w $ml_home_dir && -f $cf && -w $cf) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: return the temporary file path you can use.
#    Arguments: OBJ($curproc)
# Side Effects: update the counter to ensure file name uniqueness
# Return Value: STR
sub tmp_file_path
{
    my ($curproc) = @_;
    my $config  = $curproc->config();
    my $tmp_dir = $config->{ tmp_dir };

    $TmpFileCounter++; # ensure uniqueness
    my $f = sprintf("tmp.%s.%s.%s", $$, time, $TmpFileCounter);

    if (-d $tmp_dir && -w $tmp_dir) {
	use File::Spec;
	my $_file = File::Spec->catfile($tmp_dir, $f);
	$curproc->_add_into_cleanup_queue($_file);
	return $_file;
    }
    else {
	my $tmp_dir = $curproc->global_tmp_dir_path();
	use File::Spec;
	my $_file = File::Spec->catfile($tmp_dir, $f);
	$curproc->_add_into_cleanup_queue($_file);
	return $_file;
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


# Descriptions: remove too old incoming queue files.
#    Arguments: OBJ($curproc) STR($dir) NUM($_limit)
# Side Effects: remove too old incoming queue files.
# Return Value: none
sub _delete_too_old_files_in_dir
{
    my ($curproc, $dir, $_limit) = @_;
    my $limit = $_limit || 14*24*3600; # 2 weeks by default.

    use DirHandle;
    use File::stat;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my ($file, $entry, $stat);
	my $day_limit = time - $limit;

      ENTRY:
	while ($entry = $dh->read()) {
	    next ENTRY if $entry =~ /^\./o;

	    $file = File::Spec->catfile($dir, $entry);
	    $stat = stat($file);
	    if ($stat->mtime < $day_limit) {
		$curproc->log("remove too old file: $entry");
		unlink $file;
	    }
	}
	$dh->close();
    }
}


# Descriptions: add some information into header.
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
	mode    => 'default',
	message => $msg,
    };
  FML::Header->add_message_id($config, $hrw_args);
  FML::Header->add_software_info($config, $hrw_args);
  FML::Header->add_rfc2369($config, $hrw_args);
}


=head2 queue_flush()

flush all queue.

C<TODO:>
   flush C<$queue>, that is, send mail specified by C<$queue>.

=cut


# Descriptions: flush all queue.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub queue_flush
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };
    my $qmgr_args = { directory => $queue_dir };
    my $channel   = 'mail_queue_cleanup';

    # XXX-TODO: timeout should be customizable.
    eval q{
	use FML::Process::QueueManager;
	my $q = new FML::Process::QueueManager $curproc, $qmgr_args;
	$q->send();

	if ($curproc->is_event_timeout($channel)) {
	    $q->cleanup();
	    $curproc->event_set_timeout($channel, time + 3600);
	}
    };
    croak($@) if $@;
}


=head2 reply_message_prepare_template($pf_args)

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
sub reply_message_prepare_template
{
    my ($curproc, $pf_args) = @_;
    my $config      = $curproc->config();
    my $tmp_dir     = $config->{ tmp_dir };
    my $tmpf        = $curproc->tmp_file_path();
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

	# XXX-TODO: NL
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
sub outgoing_message_cache_open
{
    my ($curproc, $optargs) = @_;
    my $config = $curproc->config();

    # save message for further investigation
    if ($config->yes('use_outgoing_mail_cache')) {
	my $dir     = $config->{ outgoing_mail_cache_dir };
	my $modulus = $config->{ outgoing_mail_cache_size };
	use FML::Cache::Ring;
        my $cache     = new FML::Cache::Ring {
            directory => $dir,
	    modulus   => $modulus,
        };

	if (defined $cache) {
	    return $cache->open();
	}
	else {
	    return undef;
	}
    }

    return undef;
}


# Descriptions: parse exception error message and return (key, reason).
#    Arguments: OBJ($curproc) STR($exception)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub exception_parse
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
sub sysflow_reopen_stderr_channel
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($curproc->is_cgi_process()       ||
	$curproc->is_under_mta_process() ||
	defined $option->{ quiet }  || defined $option->{ q } ||
	$config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') ||
	$option->{'log-computer-output'}) {
	my $tmpfile = $curproc->tmp_file_path();
	my $pcb     = $curproc->pcb();
	$pcb->set("stderr", "logfile", $tmpfile);
	$pcb->set("stderr", "use_log_dup", 1);

	open(STDERR, "> $tmpfile") || croak("fail to open $tmpfile");
    }
}


# Descriptions: close and log messages written into STDERR channel.
#    Arguments: OBJ($curproc)
# Side Effects: close(STDERR)
# Return Value: none
sub sysflow_finalize_stderr_channel
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


# Descriptions: set umask as 000 for public use.
#    Arguments: OBJ($curproc)
# Side Effects: update umask
#               save the current umask in PCB
# Return Value: NUM
sub umask_set_as_public
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    # reset umask since html archives should be public open.
    my $saved_umask = umask;
    $pcb->set('umask', 'saved_umask', $saved_umask);
    umask(000);
}


# Descriptions: back to the saved umask in PCB.
#    Arguments: OBJ($curproc)
# Side Effects: umask
# Return Value: NUM
sub umask_reset
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    my $saved_umask = $pcb->get('umask', 'saved_umask');

    # back to the original umask;
    umask($saved_umask);
}


# Descriptions: whether we should be quiet or not ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub be_quiet
{
    my ($curproc) = @_;
    my $debug     = $curproc->_get_debug_level();
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($curproc->is_cgi_process()       ||
	$curproc->is_under_mta_process() ||
	defined $option->{ quiet }  || defined $option->{ q } ||
	$config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') ||
	$option->{'log-computer-output'}) {
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
    my $debug     = $curproc->_get_debug_level();
    my $config    = $curproc->config();
    my $option    = $curproc->command_line_options();

    if ($config->yes('use_log_dup') || $option->{ 'log-dup' } ||
	$config->yes('use_log_computer_output') ||
	$option->{'log-computer-output'}) {
	$curproc->sysflow_finalize_stderr_channel();
	$curproc->_log_message_print();
    }

    if ($debug > 100) {
	$curproc->logdebug("debug: dump curproc structure");
	eval q{
	    use FML::Process::Debug;
	    my $obj = new FML::Process::Debug;
	    $obj->dump_curproc($curproc);
	};
	$curproc->logerror($@) if $@;
    }

    # log rotation
    $curproc->log_rorate();

    # commit transaction
    $curproc->_commit_message_id_cache_update_transaction();
}


# Descriptions: return debug level.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub _get_debug_level
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return( $args->{ main_cf }->{ debug } || 0 );
}


=head1 EXIT AS SPECIAL CODE

=head2 exit_as_tempfail()

exit as EX_TEMPFAIL.

=cut


# Descriptions: exit as EX_TEMPFAIL.
#    Arguments: OBJ($curproc)
# Side Effects: long jump.
# Return Value: none
sub exit_as_tempfail
{
    my ($curproc) = @_;

    # clean up temporary files
    $curproc->tmp_file_cleanup();
    $curproc->incoming_message_cleanup_queue();

    # main.
    $curproc->logerror("exit(EX_TEMPFAIL) to retry later.");

    $main::ERROR_EXIT_CODE = 75;
    exit(75);
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

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
