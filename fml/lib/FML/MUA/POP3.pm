#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: POP3.pm,v 1.3 2005/08/09 03:23:30 fukachan Exp $
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

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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


# Descriptions: retrieve messages.
#    Arguments: OBJ($self) HASH_REF($r_args);
# Side Effects: none
# Return Value: OBJ
sub retrieve
{
    my ($self, $r_args) = @_;
    my $curproc = $self->{ _curproc };
    my $pop     = $self->{ _pop }   || undef;
    my $class   = $r_args->{ class } || undef;

    if (defined $pop && defined $class) {
	my $msgnums = $pop->list; # hashref of msgnum => size

      MSG:
	foreach my $msgnum (keys %$msgnums) {
	    my $q = $self->_new_queue_file($r_args);
	    if (defined $q) {
		my $wh = $q->open("incoming", { mode => "w" });
		if (defined $wh) {
		    $wh->autoflush(1);

		    $wh->clearerr();
		    $pop->get($msgnum, $wh);
		    if ($wh->error()) {
			$curproc->logerror("failed to retrieve.");
			$q->remove();
		    }
		    else {
			my $id = $q->id();
			$q->dup_content($class);
			$q->remove();
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
    else {
	$self->error_set("invalid state") unless defined $pop;
	$self->error_set("invalid class") unless defined $class;
    }
}


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


# Descriptions: new queue file path.
#    Arguments: OBJ($self) HASH_REF($r_args);
# Side Effects: none
# Return Value: OBJ
sub _new_queue_file
{
    my ($self, $r_args) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config(); 
    my $queue_dir = $config->{ fetchfml_queue_dir };
    my $class     = $r_args->{ class } || undef;

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue {
	directory   => $queue_dir,
	local_class => $opt_class,
    };
    return $queue;
}


# Descriptions: pick up one queue and return the queue id.
#    Arguments: OBJ($self) HASH_REF($r_args)
# Side Effects: none
# Return Value: OBJ
sub pickup_queue
{
    my ($self, $r_args) = @_;
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->config();
    my $class     = $r_args->{ class } || $opt_class->[ 0 ];
    my $queue_dir = $config->{ fetchfml_queue_dir };

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
# Side Effects: update reason.
# Return Value: none
sub error_set
{
    my ($self, $reason) = @_;
    $self->{ _error_reason } = $reason;
}


# Descriptions: return the last error reason.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub error
{
    my ($self) = @_;
    $self->{ _error_reason } || '';
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

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MUA::POP3 appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
