#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Process::Kernel;

use strict;
use Carp;

use FML::Process::Flow;

use FML::Parse;
use FML::Header;
use FML::Config;
use FML::Log qw(Log);
use FML::Lock;
use FML::Messages;


sub new
{
    my ($self, $args)    = @_;
    my ($curproc) = {}; # alloc memory as the struct current_process.
    my ($cfargs)  = {};

    # import variables
    my (@import_vars) = qw(ml_home_prefix ml_home_dir);
    for my $var (@import_vars) {
	if (defined $args->{ $var }) {
	    $cfargs->{ $var } = $args->{ $var };
	}
	else {
	    if ($var eq 'ml_home_dir') {
		next unless $args->{ need_ml_name };
	    }

	    croak "variable $var is not defined.\n";
	}
    }

    # import $fml_version
    if (defined $args->{ fml_version }) {
	$cfargs->{ fml_version } = "fml-devel ". $args->{ fml_version };
    }

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
    if ($0 =~ /loader/) { $curproc->debug; sleep 3;}

    return $curproc;
}


# default signal handling
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


sub prepare
{
    my ($curproc, $args) = @_;
    $curproc->parse_incoming_message();
}


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

    require FML::Lock;
    my $lockobj = new FML::Lock;

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


sub inform_reply_messages
{
    my ($curproc, $args) = @_;
}


sub ValidateInComingMail
{
    my ($curproc, $args) = @_;
}


sub verify_sender_credential
{
    my ($curproc, $args) = @_;
    my $r_msg = $curproc->{'incoming_message'};
    my $from  = $r_msg->{'header'}->get('from');

    use Mail::Address;
    my ($addr, @addrs) = Mail::Address->parse($from);

    # extract the first address as a sender.
    $from = $addr->address;
    $from =~ s/\n$//o;

    unless (@addrs) { # XXX @addrs must be empty.
	Log("sender: $from");
	use FML::Credential;
	$curproc->{'credential'} = new FML::Credential;
	$curproc->{'credential'}->set( 'sender', $from );
    }
    else {
	Log("invalid From:");
    }
}


sub sender_is_member
{
    my ($curproc, $args) = @_;
    $curproc->{'credential'}->{'sender'}
    # &IsMailingListMember( $from );
}


sub simple_loop_check
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $r_msg  = $curproc->{ incoming_message };
    my $header = $r_msg->{ header };

    for my $rule (split(/\s+/, $config->{ header_check_rules })) {
	if ($header->can($rule)) {
	    $header->$rule($config, $args);
	}
	else {
	    Log("header->${rule}() is undefined");
	}
    }
}


# fml5::init_main() routine
sub load_config_files
{
    my ($curproc, $files) = @_;

    # load configuration variables from given files e.g. /some/where.cf 
    # XXX overload variables from each $cf
    for my $cf (@$files) { 
      $curproc->{ config }->overload( $cf );
    }

    # XXX We need to expand variables after we load all *cf files.
    $curproc->{ config }->expand_variables();
}


sub parse_incoming_message
{
    my ($curproc, $args) = @_;

    # parse incoming mail to cut off it to the header and the body.
    use FML::Parse;

    # malloc the incoming message on memory.
    # $r_msg is the reference to the memory area.
    my $r_msg = {};
    ($r_msg->{'header'}, $r_msg->{'body'}) = new FML::Parse $curproc, \*STDIN;
    $curproc->{'incoming_message'} = $r_msg;
}


# debug
sub debug
{
    my ($curproc, $args) = @_;

    eval {
	use FML::Debug;
	my $fp = new FML::Debug;
	$fp->show_structure($curproc);
    };
}


1;
