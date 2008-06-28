#-*- perl -*-
#
#  Copyright (C) 2005,2006,2007,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: POP3.pm,v 1.8 2007/01/16 12:16:52 fukachan Exp $
#

package FML::MUA::POP3;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FileHandle;

# optional queue class.
my $opt_class = [ "article_post", "command_mail", "error_mail_analyzer" ];


=head1 NAME

FML::MUA::POP3 - retrieve a message by pop3 protocol.

=head1 SYNOPSIS

use FML::MUA::POP3;
my $mua = new FML::MUA::POP3 $curproc;
MUA:
    for my $server (@$servers) {
        if (defined $mua) {
            $mua->login({
                server   => $server,
                username => $username,
                password => $password,
            });
        }
        else {
            $curproc->logerror("object undefined.");
        }

        if ($mua->error()) {
            $curproc->logerror($mua->error());
            next MUA;
        }
    }

if ($mua->error()) {
    $curproc->logerror($mua->error());
    $curproc->stop_this_process();
    return;
}

$mua->retrieve( { class => $class } );
if ($mua->error()) {
    $curproc->logerror($mua->error());
    $curproc->stop_this_process();
    return;
}

$mua->quit();
if ($mua->error()) {
    $curproc->logerror($mua->error());
}

=head1 DESCRIPTION

This class provides POP3 protocol interface.
It behaves a MUA.

=head1 METHODS

=head2 new()

constructor.

=cut

# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 login($r_args)

login to pop3 server.

=cut


# Descriptions: login to pop3 server.
#    Arguments: OBJ($self) HASH_REF($r_args);
# Side Effects: none
# Return Value: OBJ
sub login
{
    my ($self, $r_args) = @_;
    my $server   = $r_args->{ server }   || '';
    my $username = $r_args->{ username } || '';
    my $password = $r_args->{ password } || '';
    my $timeout  = $r_args->{ timeout  } || 60;

    if ($server && $username && $password) {
        use Net::POP3;
        my $pop = Net::POP3->new($server, Timeout => $timeout);
	if (defined $pop) {
	    my $status = undef;
	    my $capa   = $pop->capa();

	    # 1. try APOP if APOP is supported (we can know it via CAPA).
	    # 2. try ordinary POP if APOP fails or not supported. 
	    if ($capa->{ APOP }) {
		$status = $pop->apop($username, $password);
	    }
	    unless ($status) {
		$status = $pop->login($username, $password);
	    }

	    if (defined $status) {
		$self->{ _pop } = $pop;
		return $pop;
	    }
	    else {
		$self->error_set("login failed.");
	    }
	}
	else {
	    $self->error_set("undefined object.");
	}
    }
    else {
	$self->error_set("invalid login arguments");
    }
}


=head2 retrieve($r_args)

retrieve messages.

=cut


# Descriptions: retrieve messages.
#    Arguments: OBJ($self) HASH_REF($r_args);
# Side Effects: none
# Return Value: OBJ
sub retrieve
{
    my ($self, $r_args) = @_;
    my $curproc   = $self->{ _curproc };
    my $pop       = $self->{ _pop }    || undef;
    my $class     = $r_args->{ class } || undef;
    my $tmp_queue = "incoming";

    # ASSERT
    unless (defined $pop) {
	$self->error_set("invalid state");
	return undef;
    }
    unless (defined $class) {
	$self->error_set("invalid class");
	return undef;
    } 

    my $msgnums = $pop->list; # hashref of msgnum => size
  MSG:
    foreach my $msgnum (keys %$msgnums) {
	my $q = $self->_new_queue_file($r_args);
	if (defined $q) {
	    my $wh = $q->open($tmp_queue, { mode => "w" });
	    if (defined $wh) {
		$wh->autoflush(1);

		$wh->clearerr();
		$pop->get($msgnum, $wh);
		if ($wh->error()) {
		    $curproc->logerror("failed to retrieve NUM=$msgnum.");
		    $q->remove();
		}
		else {
		    my $id = $q->id();
		    $q->dup_content($tmp_queue, $class);
		    $q->remove();
		    $pop->delete($msgnum);
		    $curproc->log("fetched: qid=$id");
		}

		$wh->close();
	    }
	    else {
		last MSG;
	    }
	}
	else {
	    $curproc->logerror("queue not prepared");
	}
    }
}


=head2 quit($r_args)

close pop session.

=cut


# Descriptions: close pop session.
#    Arguments: OBJ($self) HASH_REF($r_args)
# Side Effects: close pop session.
# Return Value: none
sub quit
{
    my ($self, $r_args) = @_;
    my $pop = $self->{ _pop };

    if (defined $pop) {
	$pop->quit();
    }
}


=head1 UTILITY

=cut


# Descriptions: create a new queue and return the object.
#    Arguments: OBJ($self) HASH_REF($r_args);
# Side Effects: none
# Return Value: OBJ
sub _new_queue_file
{
    my ($self, $r_args) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $queue_dir = $config->{ fetchfml_queue_dir } || '';
    my $class     = $r_args->{ class }              || '';

    # ASSERT
    unless ($class) {
	$self->error_set("invalid class");
	return undef;
    } 
    unless ($queue_dir) {
	$self->error_set("queue_dir undefined");
	return undef;
    } 

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue {
	directory   => $queue_dir,
	local_class => $opt_class,
    };
    return $queue;
}


=head2 pickup_queue($r_args)

=cut


# Descriptions: pick up one queue and return the queue id.
#    Arguments: OBJ($self) HASH_REF($r_args)
# Side Effects: none
# Return Value: OBJ
sub pickup_queue
{
    my ($self, $r_args) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $class     = $r_args->{ class } || $opt_class->[ 0 ] || '';
    my $queue_dir = $config->{ fetchfml_queue_dir }         || '';

    # ASSERT
    unless ($class) {
	$self->error_set("invalid class");
	return undef;
    } 
    unless ($queue_dir) {
	$self->error_set("queue_dir undefined");
	return undef;
    } 

    use Mail::Delivery::Queue;
    my $queue      = new Mail::Delivery::Queue {
	directory   => $queue_dir,
	local_class => $opt_class,
    };

    my $list     = $queue->list($class, "oldest");
    my $queue_id = $list->[ 0 ] || '';
    if (defined $queue_id && $queue_id) {
	my $queue       = new Mail::Delivery::Queue {
	    id          => $queue_id,
	    directory   => $queue_dir,
	    local_class => $opt_class,
	};
	return $queue;
    }
    else {
	return undef;
    }
}


=head1 ERROR HADNLING

=head2 error_set($reason)

save error reason.

=head2 error()

return the last error reason.

=cut


# Descriptions: save error reason.
#    Arguments: OBJ($self) STR($reason)
# Side Effects: update $self.
# Return Value: none
sub error_set
{
    my ($self, $reason) = @_;

    $self->{ _error_reason } = $reason || '';
}


# Descriptions: return the last error reason.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error
{
    my ($self) = @_;

    return( $self->{ _error_reason } || '' );
}


#
# debug
#
if ($0 eq __FILE__) {
    my ($username, $password, $buf) = ();
    my $server = shift @ARGV || croak("usage: $0 server\n");

    use Term::ReadLine;
    my $term   = new Term::ReadLine 'Simple Perl calc';
    my $prompt = "Username: ";
  LINE:
    while ( defined ($buf = $term->readline($prompt)) ) {
	system "stty -echo";
	eval( $username = $buf );
	last LINE if $@;
	last LINE if $username;
    }
    $username =~ s/\s*$//;

    $prompt = "Password: ";
  LINE:
    while ( defined ($buf = $term->readline($prompt)) ) {
	system "stty -echo";
	eval( $password = $buf );
	last LINE if $@;
	last LINE if $password;
    }
    $password =~ s/\s*$//;

    print "\n";

    if ($username && $password) {
	use Net::POP3;
	my $pop    = Net::POP3->new($server, Timeout => 60);
	my $capa   = $pop->capa();
	my $status = 0;

	if ($capa->{ APOP }) {
	    print "try apop ...\n";
	    $status = $pop->apop($username, $password) || undef;
	}
	unless ($status) {
	    print "try usual login ...\n";
	    $status = $pop->login($username, $password) || undef;
	}

	if (defined $status) {
	    if ($status > 0) {
		my $msgnums = $pop->list; # hashref of msgnum => size
		foreach my $msgnum (keys %$msgnums) {
		    print ">>> $msgnum\n";
		    $pop->get($msgnum, \*STDOUT);
		    # $pop->delete($msgnum);
		}
	    }
	}
	else {
	    croak("login failed.");
	}

	$pop->quit;
    }
    else {
	croak("username and password unspecified.");
    }
}

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006,2007,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MUA::POP3 appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
