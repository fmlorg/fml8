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

    bless $me, $type;

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

=head2 C<new($args)>

constructor. if $args is given, create() method is called.

=head2 C<create($args)>

build a template message following the given $args (a hash reference).

=cut


sub create
{
    my ($self, $args) = @_;

    # parse the non multipart mail
    if ($args->{ content_type } =~ /multipart/i) { 
	$self->parse_mime_multipart($args);
    }
    else {
	$self->_create($args);
    }
}


sub _create
{
    my ($self, $args) = @_;

    # message chains
    $self->{ next }         = $args->{ next } || undef;
    $self->{ prev }         = $args->{ prev } || undef;

    # basic content information
    $self->{ version }      = $args->{ version }       || 1.0; 
    $self->{ mime_version } = $args->{ mime_version }  || 1.0; 
    $self->{ content_type } = $args->{ content_type  } || 'text/plain';

    # header
    $self->{ header  }      = $args->{ header  } || undef;

    # message itself (mail body)
    my $r_content = $args->{ content };
    my $len       = length( $$r_content );
    $self->{ content }      = $args->{ content } || '';
    $self->{ offset_begin } = $args->{ offset_begin } || 0;
    $self->{ offset_end }   = $args->{ offset_end   } || $len;
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


=head2 C<next_chain( $reference_to_message )>

The next one of this message is $reference_to_message.

=head2 C<prev_chain( $reference_to_message )>

The previous one of this message is $reference_to_message.

=head2 C<print( $fd )>

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

    # set up offset on $fd
    my $offset_begin  = $self->{ offset_begin };
    my $offset_end    = $self->{ offset_end };
    seek($fd, $offset_begin, 0);

    # write each line in buffer
    my ($p, $len, $buf, $pbuf, $pe);
  SMTP_IO:
    while (1) {
	$p   = index($$r_body, "\n", $pp);
	$len = $p - $pp + 1;
	$len = ($p < 0 ? ($maxlen - $pp) : $len);
	$pe  = $pp + $len;
	$buf = substr($$r_body, $pp, $len);
	if ($buf !~ /\r\n$/) { $buf =~ s/\n$/\r\n/;}

	# ^. -> ..
	$buf =~ s/^\./../;

	print $fd    $buf;
	&$logfp($buf) if $logfp;

	# XXX debug (remove this in the future) 
	{
	    print STDERR "buf: $pp,$pe < $offset_end = {$buf}\n";
	    last SMTP_IO if $pe >= $offset_end;
	}

	last SMTP_IO if $p < 0;
	$pp = $p + 1;
    }
}


=head2 C<parse_mime_multipart()>

parse the multipart mail. Actually it calculates the begin and end
offset for each part of content, not split() and so on.
C<new()> calls this routine if the message looks MIME multipart.

=cut

# CAUTION: $args must be the same as it of new().
sub parse_mime_multipart
{
    my ($self, $args) = @_;

    # the MIME boundary and the content to parse
    my $boundary = $args->{ boundary };
    my $content  = $args->{ content };

    # check input parameters
    return undef unless $boundary;
    return undef unless $content;

    # V
    # ---boundary
    #    ... message 1 ...
    # ---boundary
    #    ... message 2 ...
    # V here       V X not here
    # ---boundary--
    # 
    my $buf_begin = index($$content, $boundary     , 0);
    my $buf_end   = index($$content, $boundary."--", 0);

    # prepare lexical variables
    my $p   = 0;
    my $pp  = 0;
    my $pb  = 0;
    my $pe  = $buf_begin;
    $self->_set_pos( $pe + 1 );

    do {
	# alloc new message block
	_new_block({
	    boundary     => $boundary,

	    offset_begin => $pb,
	    offset_end   => $pe,
	    content      => $content,

	    debug        => $args->{ debug },
	});

	print $boundary;

	($pb, $pe) = $self->_next_block($content, $boundary);

	print "--" if $pe > $buf_end;
	print "\n";

    } while ($pe <= $buf_end);
}


sub _get_pos
{
    my ($self) = @_;
    defined $self->{ _current_pos } ? $self->{ _current_pos } : 0;
}


sub _set_pos
{
    my ($self, $pos) = @_;
    $self->{ _current_pos } = $pos;
}


sub _next_block
{
    my ($self, $content, $boundary) = @_;
    my ($len, $p, $pb, $pe, $pp);
    my $maxlen = length($$content);

    # get the next boundary position
    $pp  = $self->_get_pos();
    $p   = index($$content, $boundary, $pp);
    $self->_set_pos( $p + 1 );

    # determine the begin and end of the next block without delimiter
    $len       = $p > 0 ? ($p - $pp) : ($maxlen - $pp);
    $pb        = $pp + length($boundary);
    $pe        = $pb + $len - length($boundary);

    return ($pb, $pe);
}


# XXX $buf contains no MIME boundary, acutual message itself:
#     {Content-Type: ...
#
#       ... body ...}
sub _new_block
{
    my ($args) = @_;
    my $me = {};
    my $content = $args->{ content }; 
    my $begin   = $args->{ offset_begin };
    my $end     = $args->{ offset_end };

    if (defined $args->{ debug }) {
	my $buf = substr($$content, $begin, $end - $begin);
	print STDERR "[$args->{ offset_begin },$args->{ offset_end }]";
	print STDERR "{";
	print $buf;
	print STDERR "}\n";
    }

    _create($me, {
	next         => $args->{ next },
	prev         => $args->{ prev },

	offset_begin => $args->{ offset_begin },
	offset_end   => $args->{ offset_end },
	content      => $content,
    });
}


=head2 C<size()>

return the message size.

=head2 C<is_empty()>

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

=head2 C<get_xxx_reference()>

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
