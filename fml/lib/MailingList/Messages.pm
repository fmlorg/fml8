#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::Messages;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    if ($args) { create($me, $args);}
    return bless $me, $type;
}


######################################################################
=head1 NAME

MailingList::Messages -- message manipulator

=head1 SYNOPSIS

    my $m1 = new MailingList::Messages { content => \$body1 };

    my $m2 = new MailingList::Messages;
    $m2->create( { content => \$body2 });

    # make a chain of $m1, $m2, ...
    $m1->chain( $m2 );

    # print the contents in the order:  $m1, $m2, ... 
    $m1->print;

=head1 DESCRIPTION

A message has the content and a header including the next message
pointer, et. al. 

The messages are chained from/to others among them.
Out idea on the chain is similar to IPv6.
For example, MIME/multipart is a chain of messages such as

  mesg1 -> mesg2 -> mesg3 (-> undef)

So the message format is as follows. 
We describe a message as a hash reference.

   $message = {
                next         => \%next_message
                prev         => \%prev_message

                version      => 1.0
                mime_version => 1.0
                content_type => text/plain
                header       => {
                                    field_name => field_value
                                 }
                content      => \$message_body
               }

   key              value
   -----------------------------------------------------
   next             pointer to the next message
   prev             pointer to the previous message
   version          MailingList::Message object version
   mime_version     MIME version
   content_type     MIME content-type
   header           reference to a header hash
   content          reference to the content (that is, memory area)

Each default value follows:

   key              value
   -----------------------------------------------------
   next             undef
   prev             undef
   version          1.0
   mime_version     1.0
   content_type     text/plain
   header           undef
   content          ''

=head1 METHOD

=item C<new($args)>

constructor. if $args is given, create() method is called.

=item C<create($args)>

build a template message following the given $args (a hash reference).

=cut


sub create
{
    my ($self, $args) = @_;

    $self->{ next    }      = $args->{ next    } || undef;
    $self->{ prev    }      = $args->{ prev    } || undef;

    $self->{ version }      = $args->{ version }       || 1.0; 
    $self->{ mime_version } = $args->{ mime_version }  || 1.0; 
    $self->{ content_type } = $args->{ content_type  } || 'text/plain';
    $self->{ header  }      = $args->{ header  } || undef;
    $self->{ content }      = $args->{ content } || '';
}


sub next_chain
{
    my ($self, $ref_next_message) = @_;
    $self->{ next } = $ref_next_message;
}


sub prev_chain
{
    my ($self, $ref_prev_message) = @_;
    $self->{ prev } = $ref_prev_message;
}


=head2

=item C<next_chain( $reference_to_message )>

The next one of this message is $reference_to_message.

=item C<prev_chain( $reference_to_message )>

The previous one of this message is $reference_to_message.

=item C<print( $fd )>

print out a chain of messages to the file descriptor $fd.
If $fd is not specified, STDOUT is used.

=cut

sub raw_print
{
    my ($self, $fd) = @_;

    $self->{ _raw_print } = 1;
    $self->print($fd);
    delete $self->{ _raw_print };
}


sub print
{
    my ($self, $fd) = @_;
    my $msg = $self;

    # if $fd is not given, we use STDOUT.
    unless (defined $fd) { $fd = \*STDOUT;}
    
  MSG:
    while (1) {
	if (defined $self->{ _raw_print }) {
	    my $r_body = $msg->{ content };
	    print $fd $$r_body;
	}
	else {
	    $self->_print($fd, $msg->{ content });
	}

	last MSG unless $msg->{ next };
	$msg = $self->{ next };
    }
}


# Descriptions: send the body part of the message to socket
#               replace "\n" in the end of line with "\r\n" on memory.
#               We should do it to use as less memory as possible.
#               So we use substr() to process each line.
#    Arguments: $self $socket $ref_to_body
# Side Effects: none
# Return Value: none
sub _print
{
    my ($self, $fd, $r_body) = @_;

    my $pp     = 0;
    my $maxlen = length($$r_body);
    my $logfp  = $self->{ _log_function };
    $logfp     = ref($logfp) eq 'CODE' ? $logfp : undef;

    # write each line in buffer
    my ($p, $len, $buf, $pbuf);
  SMTP_IO:
    while (1) {
	$p   = index($$r_body, "\n", $pp);
	$len = $p  - $pp + 1;
	$buf = substr($$r_body, $pp, ($p < 0 ? $maxlen-$pp : $len));
	if ($buf !~ /\r\n$/) { $buf =~ s/\n$/\r\n/;}

	# ^. -> ..
	$buf =~ s/^\./../;

	print $fd    $buf;
	&$logfp($buf) if $logfp;

	last SMTP_IO if $p < 0;
	$pp = $p + 1;
    }
}


=head2

=item C<size()>

return the message size.

=item C<is_empty()>

return this message has empty content or not.

=cut

sub size
{
    my ($self) = @_;
    my $c = $self->{ content };
    length($$c);
}


sub is_empty
{
    my ($self) = @_;
    my $size   = $self->size;
    my $c      = $self->{ content };

    if ($size == 0) { return 1;}
    if ($size <= 8) {
	if ($$c =~ /^\s*$/) { return 1;}
    }

    # false
    return 0;
}


sub set_log_function
{
    my ($self, $fp) = @_;
    $self->{ _log_function } = $fp; # log function pointer
}


sub AUTOLOAD
{
    my ($self, $args) = @_;
    my $function = $AUTOLOAD;
    $function =~ s/.*:://;

    if ($function =~ /^get_(\w+)_reference$/) {
	return $self->{ $1 };
    }
    else {
	return undef;
    }
}

=head2

=item C<get_xxx_reference()>

get the reference to xxx, which is a key of the message. 
For example, 
C<get_content_reference()>
returns the reference to the
content of the message.

=cut

######################################################################

=head1 TODO

The chain structure of messages is implemented, but 
MIME/multipart is not yet handled well.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

MailingList::Messages.pm appeared in fml5.

=cut

1;
