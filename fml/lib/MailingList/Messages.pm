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

Whereas the usual mail, which Content-Type is text/plain, is described
as

  mesg1 (-> undef)

To describe such chains, a message format is a hash reference
internally.

   $message = {
                version           => 1.0

                next              => $next_message (HASH reference)
                prev              => $prev_message (HASH reference)

                mime_version      => 1.0
                base_content_type => text/plain
                content_type      => text/plain
                header            => {
                                       field_name => field_value
                                     }
                content           => \$message_body
               }

   key                value
   -----------------------------------------------------
   next               pointer to the next message
   prev               pointer to the previous message
   version            MailingList::Message object version
   mime_version       MIME version
   base_content_type  MIME content-type specified in the header
   content_type       MIME content-type
   header             reference to a header hash
   content            reference to the content (that is, memory area)

Each default value follows:

   key              value
   -----------------------------------------------------
   next              undef
   prev              undef
   version           1.0
   mime_version      1.0
   base_content_type
   content_type      text/plain
   header            undef
   content           ''

C<header> is not used now.

=head1 INTERNAL REPRESENTATION

=head2 plain/text

If the message is just an plain/text, which is usual,
internal representation follows:

   i  base_content_type              content_type
   ----------------------------------------------------------
   0: text/plain                      text/plain

where the C<i> is the C<i>-th element of a chain.

=head2 multipart/...

Consider a multipart such as

   Content-Type: multipart/mixed; boundary="boundary"

      ... preamble ...

   --boundary
   Content-Type: text/plain; charset="iso-2022-jp"

   --boundary
   Content-Type: image/gif;

   --boundary--
      ... trailor ...

The internal parser interpetes it as follows:

      base_content_type              content_type
   ----------------------------------------------------------
   0: multipart/mixed                multipart.preamble/plain
   1: multipart/mixed                multipart.delimiter/plain
   2: multipart/mixed                text/plain
   3: multipart/mixed                multipart.delimiter/plain
   4: multipart/mixed                image/gif
   5: multipart/mixed                multipart.close-delimiter/plain
   6: multipart/mixed                multipart.trailer/plain

C<multipart.something> is a faked type to treat both real content,
delimiters and others in the same MailingList::Messages framework.

=head1 METHOD

=head2 C<new($args)>

constructor. if $args is given, create() method is called.

=head2 C<create($args)>

build a template message following the given $args (a hash reference).

=cut


sub create
{
    my ($self, $args) = @_;

    # set up template anyway
    $self->_set_up_template($args);

    # parse the non multipart mail
    if ($args->{ content_type } =~ /multipart/i) {
	$self->parse_mime_multipart($args);
    }
    else {
	$self->_create($args);
    }
}


sub _set_up_template
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

    # save the mail header Content-Type information
    $self->{ base_content_type } =
	$args->{ base_content_type } || $args->{ content_type } || undef;
}


sub _create
{
    my ($self, $args) = @_;

    _set_up_template($self, $args);

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
	if (defined $msg->{ content }) {
	    $msg->_print($fd, $msg->{ content });
	}

	last MSG unless $msg->{ next };
	$msg = $msg->{ next };
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

    # set up offset for the buffer
    my $pp     = $self->{ offset_begin };
    my $p_end  = $self->{ offset_end };
    my $maxlen = length($$r_body);
    my $logfp  = $self->{ _log_function };
    $logfp     = ref($logfp) eq 'CODE' ? $logfp : undef;

    # \n -> \r\n
    my $raw_print_mode = 1 if defined $self->{ _raw_print };

    # write each line in buffer
    my ($p, $len, $buf, $pbuf, $pe);
  SMTP_IO:
    while (1) {
	$p   = index($$r_body, "\n", $pp);
	last SMTP_IO if $p >= $p_end;

	$len = $p - $pp + 1;
	$len = ($p < 0 ? ($maxlen - $pp) : $len);
	$pe  = $pp + $len;
	$buf = substr($$r_body, $pp, $len);

	unless (defined $raw_print_mode) {
	    # fix \n -> \r\n in the end of the line
	    if ($buf !~ /\r\n$/) { $buf =~ s/\n$/\r\n/;}

	    # ^. -> ..
	    $buf =~ s/^\./../;
	}

	print $fd $buf;
	&$logfp($buf) if $logfp;

	last SMTP_IO if $p < 0;
	$pp = $p + 1;
    }
}


=head2 C<parse_mime_multipart($args)>

parse the multipart mail. Actually it calculates the begin and end
offset for each part of content, not split() and so on.
C<new()> calls this routine if the message looks MIME multipart.

=cut


# CAUTION: $args must be the same as it of new().
#
#         ... preamble ...
#      V $mpb_begin
#      ---boundary
#         ... message 1 ...
#      ---boundary
#         ... message 2 ...
#      V $mpb_end  (V here is not $buf_end)
#      ---boundary--
#         ... trailor ...
#
sub parse_mime_multipart
{
    my ($self, $args) = @_;

    # virtual content-type
    my %content_type = 
	(
	 'preamble'        => 'multipart.preamble/plain',
	 'delimiter'       => 'multipart.delimiter/plain',
	 'close-delimiter' => 'multipart.close-delimiter/plain',
	 'trailer'         => 'multipart.trailer/plain',
	 );


    # check input parameters
    return undef unless $args->{ boundary };
    return undef unless $args->{ content  };

    # base content-type
    my $base_content_type = $args->{ content_type };

    # boundaries of the continuous multipart blocks
    my $content     = $args->{ content };  # reference to content
    my $content_end = length($$content);   # end position of the content
    my $boundary    = $args->{ boundary }; # MIME boundary string
    my $mpb_begin   = index($$content, $boundary     , 0);
    my $mpb_end     = index($$content, $boundary."--", 0);

    # prepare lexical variables
    my ($msg, $next_part, $prev_part, @m);
    my $i = 0; # counter to indicate the $i-th message

    # 1. check the preamble before multipart blocks
    my $pb  = 0;          # pb = position of the beginning in $content
    my $pe  = $mpb_begin; # pe = position of the end in $content
    $self->_set_pos( $pe + 1 );

    do {
	# 2. analyze the region for the next part in $content
	#     we should check the condition "$pe > $pb" here
	#     to avoid the empty preamble case.
	# XXX this function is not called
	# XXX if there is not the prededing preamble.
	if ($pe > $pb) { # XXX not effective region if $pe <= $pb
	    my $args = {
		boundary          => $boundary,
		offset_begin      => $pb,
		offset_end        => $pe,
		content           => $content,
		base_content_type => $base_content_type,
	    };
	    my $default = ($i == 0) ? $content_type{'preamble'} : undef;
	    $args->{ content_type } = _get_content_type($args, $default);

	    $m[ $i++ ] = $self->_alloc_new_part($args);
	}

	# 3. where is the region for the next part?
	($pb, $pe) = $self->_next_part_pos($content, $boundary);

	# 4. insert a multipart delimiter
	#    XXX we malloc(), "my $tmpbuf", to store the boundary string.
	if ($pe > $mpb_end) { # check the closing of the blocks or not
	    my $tmpbuf = $boundary . "--\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		content           => \$tmpbuf,
		content_type      => $content_type{'close-delimiter'},
		base_content_type => $base_content_type,
	    });

	}
	else {
	    my $tmpbuf = $boundary . "\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		content           => \$tmpbuf,
		content_type      => $content_type{'delimiter'},
		base_content_type => $base_content_type,
	    });
	}

    } while ($pe <= $mpb_end);

    # check the trailor after multipart blocks exists or not.
    {
	my $p = index($$content, "\n", $mpb_end) + 1;
	if (($content_end - $p) > 0) {
	    $m[ $i++ ] = $self->_alloc_new_part({
		boundary          => $boundary,
		offset_begin      => $p,
		offset_end        => $content_end,
		content           => $content,
		content_type      => $content_type{'trailor'},
		base_content_type => $base_content_type,
	    });
	}
    }

    # build a chain of multipart blocks and delimeters
    my $j = 0;
    for ($j = 0; $j < $i; $j++) {
	if (defined $m[ $j + 1 ]) {
	    next_chain( $m[ $j ], $m[ $j + 1 ] );
	}
	if (($j > 1) && defined $m[ $j - 1 ]) {
	    prev_chain( $m[ $j ], $m[ $j - 1 ] );
	}

	if (0) { # debug
	    printf STDERR "%d: %-30s %-30s\n", $j,
		$m[ $j]->{ base_content_type },
		$m[ $j]->{ content_type };
	}
    }

    # chain $self and our chains built here.
    next_chain($self, $m[0]);

    # use Data::Dumper; print STDERR Dumper( $self ); # debug
}


sub _get_content_type
{
    my ($args, $default) = @_;
    my $content   = $args->{ content };
    my $pos_begin = $args->{ offset_begin };
    my $pos       = index($$content, "\n\n", $pos_begin);
    my $buf       = substr($$content, $pos_begin, $pos - $pos_begin );

    if ($buf =~ /Content-Type:\s*(\S+)\;/) {
	return $1;
    }
    else {
	$default
    }
}


# XXX $buf contains no MIME boundary, acutual message itself:
#     {Content-Type: ...
#
#       ... body ...}
sub _alloc_new_part
{
    my ($self, $args) = @_;
    my $me = {};

    _create($me, $args);
    return bless $me, ref($self);
}


sub _next_part_pos
{
    my ($self, $content, $boundary) = @_;
    my ($len, $p, $pb, $pe, $pp);
    my $maxlen = length($$content);

    # get the next boundary position
    $pp  = $self->_get_pos();
    $p   = index($$content, $boundary, $pp);
    $self->_set_pos( $p + 1 );

    # determine the begin and end of the next block without delimiter
    $len = $p > 0 ? ($p - $pp) : ($maxlen - $pp);
    $pb  = $pp + length($boundary);
    $pe  = $pb + $len - length($boundary);

    return ($pb, $pe);
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


=head2 C<size()>

return the message size.

=head2 C<is_empty()>

return this message has empty content or not.

=head2 C<set_log_function()>

internal use. set CODE REFERENCE to the log function

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


sub get_content_type
{
    my ($self) = @_;
    $self->{ content_type };
}


=head2 C<get_content_header($size)>

get header in the content, which is whole mail or a part of multipart.

=head2 C<get_content_body($size)>

get body part in the content.

=head2 C<get_first_plaintext_message($args)>

    $args->{ size }

=cut


sub get_content_header
{
    my ($self, $size) = @_;
    my $content = $self->{ content };
    my $pos     = index($$content, "\n\n", $self->{ offset_begin });
    my $len     = $pos - $self->{ offset_begin };

    substr($$content, $self->{ offset_begin }, $len);
}


sub get_content_body
{
    my ($self, $size) = @_;
    my $content   = $self->{ content };
    my $pos       = index($$content, "\n\n", $self->{ offset_begin });
    my $pos_begin = $pos + 2;
    my $msglen    = $self->{ offset_end } - $pos_begin;

    $size ||= 512;
    if ($msglen < $size) { $size = $msglen;}
    return substr($$content, $pos_begin, $size);
}


sub get_first_plaintext_message
{
    my ($self, $args) = @_;

    $size = $args->{ size } || 512;

    # use Data::Dumper; print STDERR Dumper( $self ), "\n";

    my $mp;
    for ($mp = $self; 
	 defined $mp->{ content } || defined $mp->{ next }; 
	 $mp = $mp->{ next }) {
	my $type = $mp->get_content_type;

	if ($type eq 'text/plain') {
	    return $mp->get_content_body($size);
	}
    }

    return undef;
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
