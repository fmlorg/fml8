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

    # bind FML::Config object to $curproc
    use FML::Config;
    $curproc->{ config } = new FML::Config;

    bless $curproc, $self;

    # load config.cf files, which is passed from fmlwrapper.
    $curproc->load_config_files( $args->{ cf_list } );

    return $curproc;
}


sub prepare
{
    my ($curproc, $args) = @_;
    $curproc->parse_incoming_mail();
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
	$curproc->{ pcb }->{ lock }->{ object } = $lockobj;
	$curproc->{ pcb }->{ lock }->{ file   } = $lock_file;
	Log( "locked $lock_file");
    }
    else {
	croak("Error: cannot lock");
    }
}


sub unlock
{
    my ($curproc, $args) = @_;

    my $lockobj   = $curproc->{ pcb }->{ lock }->{ object };
    my $lock_file = $curproc->{ pcb }->{ lock }->{ file };

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
    my $r_msg = $curproc->{'incoming_mail'};
    my $from  = $r_msg->{'header'}->get('from');

    use Mail::Address;
    my @addrs = Mail::Address->parse($from);

    my $count = 0;
    for my $a (@addrs) {
	$count++;

	# extract the first address as a sender.
	$from = $a->format unless $from;
	$from =~ s/\n$//o;
    }

    if ($count == 1) {
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


sub parse_incoming_mail
{
    my ($curproc, $args) = @_;

    # parse incoming mail to cut off it to the header and the body.
    use FML::Parse;

    # malloc the incoming message on memory.
    # $r_msg is the reference to the memory area.
    my $r_msg = {};
    ($r_msg->{'header'}, $r_msg->{'body'}) = new FML::Parse \*STDIN;
    $curproc->{'incoming_mail'} = $r_msg;
}


# debug
sub Debug
{
    my ($curproc, $args) = @_;

    eval {
	use FML::Debug;
	my $fp = new FML::Debug;
	$fp->show_structure($curproc);
    };
}


1;
