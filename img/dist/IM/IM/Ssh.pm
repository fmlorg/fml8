# -*-Perl-*-
################################################################
###
###			  Ssh.pm
###
### Author:  Masatoshi Tsuchiya <tsuchiya@pine.kuee.kyoto-u.ac.jp>
### Created: Oct 05, 1999
### Revised: Feb 28, 2000
###

my $PM_VERSION = "IM::Ssh.pm version 20000228(IM140)";

package IM::Ssh;
require 5.003;
require Exporter;
use IM::Config qw( connect_timeout command_timeout $SSH_PATH );
use IM::Util;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $SSH $FH @PID );
@ISA       = qw( Exporter );
@EXPORT    = qw( ssh_proxy );

# Global Variables
$FH      = "SSH00000";
@PID     = ();

sub ssh_proxy ($$$$) {
    my( $server, $remote, $local, $host ) = @_;

    unless( $host ){
	im_err( "Missing relay host.\n" );
	return 0;
    }
    im_notice( "openning SSH-tunnel to $server/$remote\%$local via $host\n" )
	if &verbose;

    my( $pid, $read, $write );
  FORK: {
	no strict 'refs';
	$read  = $FH++;
	$write = $FH++;
	pipe( $read, $write );
	if ( $pid = fork ) {
	    close $write;
	    my( $buf, $sig, $i );
	    for( $i=0; $i<3; $i++ ){
		$sig = $SIG{ALRM};
		$SIG{ALRM} = sub { die "SIGALRM is received\n"; };
		eval {
		    alarm &connect_timeout();
		    $buf = <$read>;
		    alarm 0;
		};
		$SIG{ALRM} = $sig;
		if ( $@ !~ /SIGALRM is received/ ) {
		    push( @PID, $pid );
		    if ( $buf =~ /ssh_proxy_connect/ ) {
			return $local;
		    } elsif ( $buf =~ /Local: bind: Address already in use/ ) {
			$local++;
			redo FORK;
		    } elsif( $buf ){
			last;
		    }
		}
	    }
	    $buf =~ s/\s+$//;
	    $buf =~ s/\n/\\n/g;
	    im_warn( "Accident in Port Forwading: $buf\n" );
	} elsif ( $pid == 0 ) {
	    close $read;
	    open(STDOUT, ">&$write" );
	    open(STDERR, ">&$write" );
 	    exec($SSH_PATH, '-n', '-x', '-o', 'BatchMode yes',
		  "-L$local:$server:$remote", $host,
		  sprintf( 'echo ssh_proxy_connect ; sleep %s', &command_timeout() ) );
	    exit 0;			# Not reach.
	} elsif ( $! =~ /No more process/ ) {
	    sleep 5;
	    redo FORK;
	} else {
	    im_warn( "Can't fork $SSH_PATH.\n" );
	}
    }
    0;
}


sub END {
    if ( @PID ) {
	kill 15, @PID;
	sleep 3;
	kill 9, @PID;
    }
}


1;
