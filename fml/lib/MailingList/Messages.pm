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


# virtual content-type
my %content_type = 
    (
     'preamble'        => '_multipart_preamble/plain',
     'delimiter'       => '_multipart_delimiter/plain',
     'close-delimiter' => '_multipart_close-delimiter/plain',
     'trailer'         => '_multipart_trailer/plain',
     );


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
   header             MIME header
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
   0: multipart/mixed                _multipart_preamble/plain
   1: multipart/mixed                _multipart_delimiter/plain
   2: multipart/mixed                text/plain
   3: multipart/mixed                _multipart_delimiter/plain
   4: multipart/mixed                image/gif
   5: multipart/mixed                _multipart_close-delimiter/plain
   6: multipart/mixed                _multipart_trailer/plain

C<_multipart_something> is a faked type to treat both real content,
delimiters and others in the same MailingList::Messages framework.

=head1 METHOD

=head2 C<new($args)>

constructor. if $args is given, create() method is called.

=head2 C<create($args)>

build a template message following the given $args (a hash reference).

=cut


# Descriptions: adapter to forward the request to object builders
#               by following content-type. The real work is done at
#                 &parse_and_build_mime_multipart_chain() if multipart
#                 &_create() if not
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub create
{
    my ($self, $args) = @_;

    # set up template anyway
    $self->_set_up_template($args);

    # parse the non multipart mail and build a chain
    if ($args->{ content_type } =~ /multipart/i) {
	$self->parse_and_build_mime_multipart_chain($args);
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
    my $filename  = $args->{ filename };

    # on memory
    if (defined $r_content) {
	my $len = length( $$r_content );
	$self->{ content }      = $args->{ content } || '';
	$self->{ offset_begin } = $args->{ offset_begin } || 0;
	$self->{ offset_end }   = $args->{ offset_end   } || $len;
	$self->{ _on_memory }   = 1;
    }
    # on disk
    elsif (defined $filename) {
	if (-f $filename) {
	    undef $self->{ content };
	    $self->{ header }     = build_mime_header($self, $args);
	    $self->{ filename }   = $filename;
	    $self->{ _on_memory } = 0; # not on memory
	}
	else {
	    carp("$filename not exist");
	}
    }
    else {
	carp("neither content nor filename specified");
    }
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


sub build_mime_multipart_chain
{
    my ($self, $args) = @_;
    my ($head, $prev_m);

    my $base_content_type = $args->{ base_content_type };
    my $msglist           = $args->{ message_list };
    my $boundary          = $args->{ boundary } || "--". time ."-$$-";
    my $dash_boundary     = "--". $boundary;
    my $delbuf            = "\n". $dash_boundary."\n";
    my $delbuf_end        = "\n". $dash_boundary . "--\n";

    for my $m (@$msglist) {
	# delimeter: --boundary
	my $msg = new MailingList::Messages {
	    base_content_type => $base_content_type,
	    content_type      => $content_type{'delimeter'},
	    boundary          => $boundary,
	    content           => \$delbuf,
	};

	$head = $msg unless $head; # save the head $msg

	# boundary -> content -> boundary ...
	if (defined $prev_m) { $prev_m->next_chain( $msg );}
	$msg->next_chain( $m );

	# for the next loop
	$prev_m = $m;
    }

    # close delimeter: --boundary--
    my $msg = new MailingList::Messages {
	base_content_type => $base_content_type,
	content_type      => $content_type{'close-delimeter'},
	boundary          => $boundary,
	content           => \$delbuf_end,
    };
    $prev_m->next_chain( $msg ); # ... -> content -> close-delimeter

    return $head; # return the pointer to the head of a chain
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
    my $msg  = $self;
    my $args = $self; # e.g. pass _raw_print flag among functions

    # if $fd is not given, we use STDOUT.
    unless (defined $fd) { $fd = \*STDOUT;}

  MSG:
    while (1) {
	# on memory
	if (defined $msg->{ content }) {
	    $msg->_print_messsage_on_memory($fd, $args);
	}
	# not on memory, may be on disk
	elsif (defined $msg->{ filename } &&
	    -f $msg->{ filename }) {
	    $msg->_print_messsage_on_disk($fd, $args);
	}

	last MSG unless $msg->{ next };
	$msg = $msg->{ next };
    }
}


# Descriptions: send the body part of the message on memory to socket
#               replace "\n" in the end of line with "\r\n" on memory.
#               We should do it to use as less memory as possible.
#               So we use substr() to process each line.
#               XXX the message to send out is $self->{ content }.
#    Arguments: $self $socket
# Side Effects: none
# Return Value: none
sub _print_messsage_on_memory
{
    my ($self, $fd, $args) = @_;

    # \n -> \r\n
    my $raw_print_mode = 1 if defined $args->{ _raw_print };

    # set up offset for the buffer
    my $r_body = $self->{ content };
    my $header = $self->{ header };
    my $pp     = $self->{ offset_begin };
    my $p_end  = $self->{ offset_end };
    my $maxlen = length($$r_body);
    my $logfp  = $self->{ _log_function };
    $logfp     = ref($logfp) eq 'CODE' ? $logfp : undef;

    # 1. print content header if exists
    if (defined $header) {
	$header =~ s/\n/\r\n/g unless (defined $raw_print_mode);
	print $fd $header;
	print $fd ($raw_print_mode ? "\n" : "\r\n");
    }

    # 2. print content body: write each line in buffer
    my ($p, $len, $buf, $pbuf);
  SMTP_IO:
    while (1) {
	$p = index($$r_body, "\n", $pp);
	last SMTP_IO if $p >= $p_end;

	$len = $p - $pp + 1;
	$len = ($p < 0 ? ($maxlen - $pp) : $len);
	$buf = substr($$r_body, $pp, $len);

	# do nothing, get away from here 
	last SMTP_IO if $len == 0;

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



sub _print_messsage_on_disk
{
    my ($self, $fd, $args) = @_;

    # \n -> \r\n
    my $raw_print_mode = 1 if defined $args->{ _raw_print };
    my $header   = $self->{ header }   || undef;
    my $filename = $self->{ filename } || undef;
    my $logfp    = $self->{ _log_function };
    $logfp       = ref($logfp) eq 'CODE' ? $logfp : undef;

    # 1. print content header if exists
    if (defined $header) {
	$header =~ s/\n/\r\n/g unless (defined $raw_print_mode);
	print $fd $header;
	print $fd ($raw_print_mode ? "\n" : "\r\n");
    }

    # 2. print content body: write each line in buffer
    use FileHandle;
    my $fh = new FileHandle $filename;
    if (defined $fh) {
	my $buf;

      SMTP_IO:
	while (<$fh>) {
	    $buf = $_;

	    unless (defined $raw_print_mode) {
		# fix \n -> \r\n in the end of the line
		if ($buf !~ /\r\n$/) { $buf =~ s/\n$/\r\n/;}

		# ^. -> ..
		$buf =~ s/^\./../;
	    }

	    print $fd $buf;
	    &$logfp($buf) if $logfp;
	}
	close($fh);
    }
    else {
	carp("cannot open $filename");
    }
}


=head2 C<parse_and_build_mime_multipart_chain($args)>

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
# RFC2046 Appendix say,
#           multipart-body := [preamble CRLF]
#                              dash-boundary transport-padding CRLF
#                              body-part *encapsulation
#                              close-delimiter transport-padding
#                              [CRLF epilogue]
#
sub parse_and_build_mime_multipart_chain
{
    my ($self, $args) = @_;

    # check input parameters
    return undef unless $args->{ boundary };
    return undef unless $args->{ content  };

    # base content-type
    my $base_content_type = $args->{ content_type };

    # boundaries of the continuous multipart blocks
    my $content         = $args->{ content };  # reference to content
    my $content_end     = length($$content);   # end position of the content
    my $boundary        = $args->{ boundary }; # MIME boundary string
    my $dash_boundary   = "--".$boundary;
    my $delimeter       = "\n". $dash_boundary;
    my $close_delimeter = $delimeter ."--";

    # 1. check the preamble before multipart blocks
    #    XXX mpb = multipart-body
    my $mpb_begin       = index($$content, $delimeter, 0);
    my $mpb_end         = index($$content, $close_delimeter, 0);
    my $pb              = 0; # pb = position of the beginning in $content
    my $pe              = $mpb_begin; # pe = position of the end in $content
    $self->_set_pos( $pe + 1 );

    # prepare lexical variables
    my ($msg, $next_part, $prev_part, @m);
    my $i = 0; # counter to indicate the $i-th message
    do {
	# 2. analyze the region for the next part in $content
	#     we should check the condition "$pe > $pb" here
	#     to avoid the empty preamble case.
	# XXX this function is not called
	# XXX if there is not the prededing preamble.
	if ($pe > $pb) { # XXX not effective region if $pe <= $pb
	    my ($header, $pb) = _get_mime_header($content, $pb);

	    my $args = {
		boundary          => $boundary,
		offset_begin      => $pb,
		offset_end        => $pe,
		header            => $header || undef,
		content           => $content,
		base_content_type => $base_content_type,
	    };
	    my $default = ($i == 0) ? $content_type{'preamble'} : undef;
	    $args->{ content_type } = _get_content_type($args, $default);

	    $m[ $i++ ] = $self->_alloc_new_part($args);
	}

	# 3. where is the region for the next part?
	($pb, $pe) = $self->_next_part_pos($content, $delimeter);

	# 4. insert a multipart delimiter
	#    XXX we malloc(), "my $tmpbuf", to store the delimeter string.
	if ($pe > $mpb_end) { # check the closing of the blocks or not
	    my $buf = $close_delimeter."\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		content           => \$buf,
		content_type      => $content_type{'close-delimiter'},
		base_content_type => $base_content_type,
	    });

	}
	else {
	    my $buf = $delimeter."\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		content           => \$buf,
		content_type      => $content_type{'delimiter'},
		base_content_type => $base_content_type,
	    });
	}

    } while ($pe <= $mpb_end);

    # check the trailor after multipart blocks exists or not.
    {
	my $p = index($$content, "\n", $mpb_end + length($close_delimeter)) +1;
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
}


sub _get_content_type
{
    my ($args, $default) = @_;
    my $buf = $args->{ header } || '';

    if ($buf =~ /Content-Type:\s*(\S+)\;/) {
	return $1;
    }
    else {
	$default
    }
}


sub _get_mime_header
{
    my ($content, $pos_begin) = @_;
    my $pos = index($$content, "\n\n", $pos_begin) + 1;
    my $buf = substr($$content, $pos_begin, $pos - $pos_begin);

    if ($buf =~ /Content-Type:\s*(\S+)\;/) {
	return ($buf, $pos + 1);
    }
    else {
	return ('', $pos_begin);
    }
}


sub build_mime_header
{
    my ($self, $args) = @_;
    my ($buf, $charset);
    my $content_type = $args->{ content_type };

    if ($content_type =~ /^text/) {
	$charset = $args->{ charset } || 'us-ascii';
    }

    $buf .= "Content-Type: $content_type" if defined $content_type;
    $buf .= ";\n\tcharset=$charset" if $charset;

    # use File::Basename;
    # my $fn = basename($args->{ filename } || '');
    # $buf .= ";\n\tfilename=\"$fn\"" if $fn;

    return ($buf ? $buf."\n" : undef);
}


# XXX $buf contains no MIME delimeter, acutual message itself:
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
    my ($self, $content, $delimeter) = @_;
    my ($len, $p, $pb, $pe, $pp);
    my $maxlen = length($$content);

    # get the next deliemter position
    $pp  = $self->_get_pos();
    $p   = index($$content, $delimeter, $pp);
    $self->_set_pos( $p + 1 );

    # determine the begin and end of the next block without delimiter
    $len = $p > 0 ? ($p - $pp) : ($maxlen - $pp);
    $pb  = $pp + length($delimeter);
    $pe  = $pb + $len - length($delimeter);

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

=cut

    my $total = 0;
sub size
{
    my ($self) = @_;
    my $rc = $self->{ content };
    my $pb = $self->{ offset_begin };
    my $pe = $self->{ offset_end };

    if ((defined $pe) && (defined $pb)) {
	if ($pe - $pb > 0) {
	    $total += ($pe - $pb);
	    return ($pe - $pb);
	}
    }
    else {
	defined $rc ? length($$rc) : 0;
    }
}


sub is_empty
{
    my ($self) = @_;
    my $size   = $self->size;
    my $rc     = $self->{ content };

    if ($size == 0) { return 1;}
    if ($size <= 8) {
	if ($$rc =~ /^\s*$/) { return 1;}
    }

    # false
    return 0;
}


sub get_content_type
{
    my ($self) = @_;
    $self->{ content_type };
}


=head2 C<get_content_header($size)>

get header in the content.

=head2 C<get_content_body($size)>

get body part in the content, 
which is the whole mail or a part of multipart.

=head2 C<get_first_plaintext_message($args)>

return the Messages object for the first "plain/text" message in a
chain. For example,

         $m    = $msg->get_first_plaintext_message();
         $body = $m->get_content_body();

where $body is the mail body (string).

=cut


sub get_content_header
{
    my ($self, $size) = @_;
    return defined $self->{ header } ? $self->{ header } : undef;
}


sub get_content_body
{
    my ($self, $size) = @_;
    my $content           = $self->{ content };
    my $base_content_type = $self->{ base_content_type };
    my ($pos, $pos_begin, $msglen);

    # if the content is undef, do nothing.
    return undef unless $content; 

    if ($base_content_type =~ /multipart/i) {
	$pos_begin = $self->{ offset_begin };
	$msglen    = $self->{ offset_end } - $pos_begin;
    }
    else {
	$pos_begin = 0;
	$msglen    = length($$content);
    }

    $size ||= 512;
    if ($msglen < $size) { $size = $msglen;}
    return substr($$content, $pos_begin, $size);
}


sub get_first_plaintext_message
{
    my ($self, $args) = @_;
    my $size = $args->{ size } || 512;

    my $mp;
    for ($mp = $self; 
	 defined $mp->{ content } || defined $mp->{ next }; 
	 $mp = $mp->{ next }) {
	my $type = $mp->get_content_type;

	if ($type eq 'text/plain') {
	    return $mp;
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
returns the reference to the content of the message.

=head2 C<set_log_function()>

internal use. set CODE REFERENCE to the log function

=cut

sub set_log_function
{
    my ($self, $fp) = @_;
    $self->{ _log_function } = $fp; # log function pointer
}


# XXX debug, remove here in the future
sub get_content_type_list
{
    my ($msg) = @_;
    my ($m, @buf, $i);

    for ($i = 0, $m = $msg; defined $m ; $m = $m->{ next }) {
	$i++;
	push(@buf, "type[$i]: $m->{'content_type'} | $m->{'base_content_type'}");
    }
    \@buf;
}


=head1 APPENDIX (RFC2046 Appendix A)

Appendix A -- Collected Grammar

   This appendix contains the complete BNF grammar for all the syntax
   specified by this document.

   By itself, however, this grammar is incomplete.  It refers by name to
   several syntax rules that are defined by RFC 822.  Rather than
   reproduce those definitions here, and risk unintentional differences
   between the two, this document simply refers the reader to RFC 822
   for the remaining definitions. Wherever a term is undefined, it
   refers to the RFC 822 definition.

     boundary := 0*69<bchars> bcharsnospace

     bchars := bcharsnospace / " "

     bcharsnospace := DIGIT / ALPHA / "'" / "(" / ")" /
                      "+" / "_" / "," / "-" / "." /
                      "/" / ":" / "=" / "?"

     body-part := <"message" as defined in RFC 822, with all
                   header fields optional, not starting with the
                   specified dash-boundary, and with the
                   delimiter not occurring anywhere in the
                   body part.  Note that the semantics of a
                   part differ from the semantics of a message,
                   as described in the text.>

     close-delimiter := delimiter "--"

     dash-boundary := "--" boundary
                      ; boundary taken from the value of
                      ; boundary parameter of the
                      ; Content-Type field.

     delimiter := CRLF dash-boundary

     discard-text := *(*text CRLF)
                     ; May be ignored or discarded.

     encapsulation := delimiter transport-padding
                      CRLF body-part

     epilogue := discard-text

     multipart-body := [preamble CRLF]
                       dash-boundary transport-padding CRLF
                       body-part *encapsulation
                       close-delimiter transport-padding
                       [CRLF epilogue]

     preamble := discard-text

     transport-padding := *LWSP-char
                          ; Composers MUST NOT generate
                          ; non-zero length transport
                          ; padding, but receivers MUST
                          ; be able to handle padding
                          ; added by message transports.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

MailingList::Messages appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
