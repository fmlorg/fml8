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

=head1 NAME

FML::Process::Kernel - provide core functions

=head1 SYNOPSIS

    use FML::Process::Kernel;
    $curproc = new FML::Process::Kernel;
    $curproc->prepare($args);

=head1 DESCRIPTION

This modules is the base class of fml processes.
It provides basic core functions.
See L<FML::Process::Flow> on where and how each function is used 
in the process flow.

=head1 METHODS

=head2 C<new($args)>

1. import variables from libexec/loader
   e.g. C<$ml_home_dir>

2. define C<$fml_version>

3. initialize
    $curproc->{ config }
    $curproc->{ pcb }

4. load and evaluate configuration files 
   e.g. /var/spool/ml/elena/config.cf

5. initialize signal handlders

=cut

use FML::Process::Flow;
use FML::Parse;
use FML::Header;
use FML::Config;
use FML::Log qw(Log);
use File::SimpleLock;
use FML::Messages;

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
    my (@import_vars) = qw(ml_home_prefix ml_home_dir);
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
    if ($0 =~ /loader/) { 
	eval q{ 
	    require Data::Dumper; Data::Dumper->import();
	    print Dumper( $curproc );
	    sleep 3;
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


=head2 C<prepare($args)>

It does preliminary works before the main part.
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


=head2 C<inform_reply_messages($args)>

inform the error messages to the sender.
C<not yet implemented>.

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub inform_reply_messages
{
    my ($curproc, $args) = @_;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub validate_incoming_message
{
    my ($curproc, $args) = @_;
}


=head2 C<verify_sender_credential($args)>

verify the mail sender and put the adddress at 
$curproc->{ credential } object.

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
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


=head2 C<sender_is_member($args)>

not yet implemented.

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub sender_is_member
{
    my ($curproc, $args) = @_;
    $curproc->{'credential'}->{'sender'}
    # &IsMailingListMember( $from );
}


=head2 C<simple_loop_check($args)>

loop checks following rules of $config->{ header_check_rules }.

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

    for my $rule (split(/\s+/, $config->{ header_check_rules })) {
	if ($header->can($rule)) {
	    $header->$rule($config, $args);
	}
	else {
	    Log("header->${rule}() is undefined");
	}
    }
}


=head2 C<load_config_files($files)>

load configuration variables from C<@$files> and expand them in the
last.

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
    $curproc->{ config }->expand_variables();
}


=head2 C<parse_incoming_message($args)>

parse the message to a set of header and body. 
$curproc->{'incoming_message'} holds the parsed message
which consists of a set of
   $curproc->{'incoming_message'}->{ header }
and
   $curproc->{'incoming_message'}->{ body }
.
The C<header> is C<FML::Header> object.
The C<body> is C<MailingList::Messages> object.

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
    my $r_msg = {};
    ($r_msg->{'header'}, $r_msg->{'body'}) = new FML::Parse $curproc, \*STDIN;
    $curproc->{'incoming_message'} = $r_msg;
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
