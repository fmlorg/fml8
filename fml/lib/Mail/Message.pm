#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Message.pm,v 1.10 2001/04/08 14:29:47 fukachan Exp $
#

package Mail::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $InComingMessage);
use Carp;

# virtual content-type
my %virtual_data_type = 
    (
     'preamble'        => 'multipart.preamble',
     'delimiter'       => 'multipart.delimiter',
     'close-delimiter' => 'multipart.close-delimiter',
     'trailer'         => 'multipart.trailer',
     );

=head1 NAME

Mail::Message -- manipulate mail messages (parse, analyze and compose)

=head1 SYNOPSIS

To make a message with one part of data and print it.

    # make a message
    my $m1 = new Mail::Message { data => \$body1 };

    # another method to make a message
    my $m2 = new Mail::Message;
    $m2->create(  { data => \$body2 } );

    # print the mail message.
    # If it is a chain of body-parts, print() shows $m1, $m2 ... 
    # in the chain order
    $m1->print;

To make a multipart message, do this.

    # make a multipart message. It consists of a chain of $m1, $m2, ...
    my $m1 = new Mail::Message { data => \$body1 };
    my $m2 = new Mail::Message { data => \$body2 };
    $m1->next_message( $m2 );


=head1 DESCRIPTION

=head2 OVERVIEW

C<A mail message> has the data and the MIME header if needed.
C<Mail::Message> object holds them and other control information such
as the reference to the next C<Mail::Message> object, et. al.

C<Mail::Message> provides useful functions to analyze a mail message.
It can handle MIME multipart. It provides the functions to check and
get information on message (part) size et. al.

C<Mail::Message> also can compose a multipart message in primitive
way.
It is useful for you to use C<Mail::Message::Compose> class to handle
MIME multipart in more clever way.  It is preapred as an adapter for
C<MIME::Lite> class.

=head2 INTERNAL REPRESENTATION

One mail consists of a message or a chain of message objects.
Elements of a chain are bi-directional among them.
Our idea to handle the chain is similar to IPv6.
For example, a MIME/multipart message is a chain of message objects
such as

  undef -> mesg1 -> mesg2 -> mesg3 -> undef

To describe such a chain, a message object consists of the following
structure.
Described below, C<MIME delimiter> is also treated as a virtual
message for convenience.
It is useful for other modules to consider what is a MIME delimiter
et. al.

   $message = {
                version        => 1.0

                next           => \$next_message
                prev           => \$prev_message

                base_data_type => "text/plain"

                mime_version   => 1.0
                header         => $header
                data_type      => "text/plain"
                data           => \$message_body

                data_info      => \$information
               }

   key                value
   -----------------------------------------------------
   version            Mail::Message object version
   next               pointer to the next message
   prev               pointer to the previous message
   base_data_type     type of the whole message
   mime_version       MIME version
   header             MIME header of the part
   data_type          type of each message (part)
   data               reference to the data (that is, memory area)
   data_info          reference to miscellaneous information.

Only rfc822/message type uses C<data_info> field.
C<header> holds MIME content header of the corresponding message.
                                       
The default value for each key follows:

   key              value
   -----------------------------------------------------
   version           1.0
   next              undef
   prev              undef
   base_data_type    text/plain
   mime_version      1.0
   header            undef
   data_type         text/plain
   data              ''
   data_info         ''


=head1 HOW TO PARSE

=head2 plain/text

If the message is just an plain/text, which is usual,
internal representation follows:

   i  base_data_type               data_type
   ----------------------------------------------------------
   0: text/plain                      text/plain

where the C<i> is the C<i>-th element of a chain.

=head2 multipart/...

Consider the following multipart message.

   Content-Type: multipart/mixed; boundary="boundary"

      ... preamble ...

   --boundary
   Content-Type: text/plain; charset="iso-2022-jp"

   --boundary
   Content-Type: image/gif;

   --boundary--
      ... trailor ...

C<Mail::Message> parser interpetes it as follows:

      base_data_type                 data_type
   ----------------------------------------------------------
   0: multipart/mixed                multipart.preamble
   1: multipart/mixed                multipart.delimiter
   2: multipart/mixed                text/plain
   3: multipart/mixed                multipart.delimiter
   4: multipart/mixed                image/gif
   5: multipart/mixed                multipart.close-delimiter
   6: multipart/mixed                multipart.trailer

C<multipart.something> is a faked type to treat both real content,
MIME delimiters and others in the same Mail::Message framework.


=head1 METHODS to create an object

=head2 C<new($args)>

constructor. 
If $args is given, C<create($args)> method is called.

=head2 C<create($args)>

build a template message object to follow the given $args (a hash
reference).

=cut


# Descriptions: usual constructor
#               call $self->create($args) if $args is given.
#    Arguments: $self $args
# Side Effects: none
# Return Value: Mail::Message object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    bless $me, $type;

    if ($args) { create($me, $args);}

    return bless $me, $type;
}


# Descriptions: adapter to forward the request to make a message object.
#               It forwards each request by each content-type.
#               parse_and_build_mime_multipart_chain() works for a multipart message
#               and _create() for a plain message.
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub create
{
    my ($self, $args) = @_;

    # set up template anyway
    $self->_set_up_template($args);

    # parse the non multipart mail and build a chain
    if ($args->{ data_type } =~ /multipart/i) {
	$self->parse_and_build_mime_multipart_chain($args);
    }
    else {
	$self->_create($args);
    }
}


# Descriptions: build a Mail::Message object template
#    Arguments: $self $args
# Side Effects: set up default values within $self if needed
# Return Value: none
sub _set_up_template
{
    my ($self, $args) = @_;

    # basic content information
    $self->{'version'}    = $args->{'version'} || 1.0;

    # information to make a chain.
    # a chain is "undef -> message -> undef" by default.
    $self->{'next'}       = $args->{'next'} || undef;
    $self->{'prev'}       = $args->{'prev'} || undef;

    # MIME-header information
    $self->{'header'  }    = $args->{'header'} || undef;

    # information on data and the type for the message.
    $self->{'mime_version'}   = $args->{'mime_version'}   || 1.0;
    $self->{'data_type'}      = $args->{'data_type'  }    || 'text/plain';
    $self->{'base_data_type'} = $args->{'base_data_type'} || $self->{'data_type'} || undef;

    # default print out mode
    set_print_mode($self, 'raw');
}


# Descriptions: simple plain/text builder
#    Arguments: $self $args
# Side Effects: set up the default values if needed
# Return Value: none
sub _create
{
    my ($self, $args) = @_;

    _set_up_template($self, $args); # build an object template

    # try to get data on both memory and disk
    my $r_data   = $args->{ data }     || undef;
    my $filename = $args->{ filename } || undef;

    # set up object for data on memory
    if (defined $r_data) {
	if (ref($r_data) eq 'Mail::Header' || ref($r_data) eq 'FML::Header') {
	    ; # do nothing
	}
	else {
	    my $len = length( $$r_data );
	    $self->{ offset_begin } = $args->{ offset_begin } || 0;
	    $self->{ offset_end }   = $args->{ offset_end   } || $len;
	}

	$self->{ data }         = $args->{ data } || '';
	$self->{ _on_memory }   = 1; # flag to indicate data is on memory
    }
    # set up object for data on disk
    elsif (defined $filename) {
	if (-f $filename) {
	    undef $self->{ data };
	    $self->{ header }     = build_mime_header($self, $args);
	    $self->{ filename }   = $filename;
	    $self->{ _on_memory } = 0; # flag to indicate data is not on memory
	}
	else {
	    carp("_create: $filename not exist");
	}
    }
    else {
	carp("_create: neither data nor filename specified");
    }
}


sub dup_header
{
    my ($self) = @_;

    # if the head object is rfc822 header, dup the header. 
    if ($self->{ data_type } eq 'rfc822/message.header') {
	my $dupmsg  = new Mail::Message; # make a new object
	my $dupmsg2 = new Mail::Message; # make a new object
	my $body    = $self->{ next };

	# 1. copy header and the first body part
	for (keys %$self) { $dupmsg->{ $_ }  = $self->{ $_ };}
	for (keys %$body) { $dupmsg2->{ $_ } = $body->{ $_ };}

	# 2. overwrite only header data in $dupmsg
	my $header = $self->{ data };
	$dupmsg->{ data } = $header->dup();
	$dupmsg->next_message( $body );
	$body->prev_message( $dupmsg );

	# 3. return the new object.
	return $dupmsg;
    }
    else {
	undef;
    }
}


=head1 METHODS to parse

=head2 C<parse($fd)>

read data from file descriptor C<$fd> and parse it to the mail header
and the body.

=cut

sub parse
{
    my ($self, $args) = @_;
    my $fd  = $args->{ fd }  || \*STDIN;

    # make an object
    my ($type) = ref($self) || $self;
    my $me     = {};
    bless $me, $type;

    # parse the header and the body
    my $result = {};
    $me->_parse($fd, $result);

    # make a Mail::Messsage object for the (whole) mail header 
    # $me becomes a Mail::Message;
    $me->_parse_header($result);
    $me->_build_header_object($args, $result);

    # make a Mail::Messsage object for the mail body
    my $ref_body = $me->_build_body_object($args, $result);

    # make a chain such as "undef -> header -> body -> undef"
    $me->next_message( $ref_body );
    $ref_body->prev_message( $me );

    # return information
    $result->{ body_size } = length($InComingMessage);
    $me->{ data_info }     = $result;

    # return the object
    $me;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _parse
{
    my ($self, $fd, $result) = @_;
    my ($header, $header_size, $p, $buf);
    my $total_buffer_size;

    while ($p = sysread($fd, $_, 1024)) {
	$total_buffer_size += $p;
	$buf .= $_; 
	if (($p = index($buf, "\n\n", 0)) > 0) {
	    $header      = substr($buf, 0, $p + 1);
	    $header_size = $p + 1;
	    $InComingMessage = substr($buf, $p + 2);
	    last;
	}
    }

    # extract mail body and put it to $InComingMessage
    while ($p = sysread($fd, $_, 1024)) {
	$total_buffer_size += $p;
	$InComingMessage   .= $_;
    }

    # read the message (mail body) from the incoming mail
    my $body_size = length($InComingMessage);

    # result to return
    $result->{ header }      = $header;
    $result->{ header_size } = $header_size;
    $result->{ body_size }   = $body_size;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _parse_header
{
    my ($self, $r) = @_;

    # parse the header
    my (@h) = split(/\n/, $r->{ header });
    for my $x (@h) { $x .= "\n";}

    # save unix-from (mail-from) in PCB and remove it in the header
    if ($h[0] =~ /^From\s/o) {
	$r->{ envelope_sender } = (split(/\s+/, $h[0]))[1];
	shift @h;
    }

    $r->{ header_array } = \@h;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _build_header_object
{
    my ($self, $args, $r) = @_;
    my $pkg = $args->{ header_class } || 'Mail::Header';
    my $ha  = $r->{ header_array };
    my $header_obj;

    eval qq{ require $pkg; $pkg->import();
	     \$header_obj = new $pkg \$ha, Modify => 0; 
	 };
    croak($@) if $@;

    my $data_type = $self->_header_data_type($header_obj);
    _create($self, {
	base_data_type => $data_type,
	data_type      => "rfc822/message.header",
	data           => $header_obj,
    });

    # save header object
    $r->{ header } = $header_obj;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _build_body_object
{
    my ($self, $args, $result) = @_;

    return new Mail::Message {
	boundary  => $self->_header_mime_boundary($result->{ header }),
	data_type => $self->_header_data_type($result->{ header }),
	data      => \$InComingMessage,
    };
}


=head2 C<rfc822_message_header()>

return Mail::Header object for the message header.

=head2 C<rfc822_message_body()>

return a Mail::Message object or a chain of objects for the message body.

=cut


sub rfc822_message_header
{
    my ($self) = @_;
    ($self->{ data_type } eq 'rfc822/message.header') ? $self->{ data } : undef;
}


sub rfc822_message_body
{
    my ($self) = @_;

    if ($self->{ data_type } eq 'rfc822/message.header') {
	$self->{ next } || undef;
    }
    else {
	$self;
    }
}


=head2 C<find($args)>

return the first C<Mail::Message> object with specified attrribute.
You can specify C<data_type> in C<$args> HASH REFERENCE.
For example, 

    $m = $msg->find( { data_type => 'text/plain' } );

C<$m> is the first "text/plain" object in a chain of C<$msg> object.

=cut

sub find
{
    my ($self, $args) = @_;

    if (defined $args->{ data_type }) {
	my $type = $args->{ data_type };
	my $mp   = $self;
	for ( ; $mp; $mp = $mp->{ next }) {
	    if ($type eq $mp->data_type()) {
		return $mp;
	    }
	}
    }

    undef;
}


=head2 C<data_type(header)>

return the C<type> string.
It is extracted from C<header> object.

=cut


sub data_type
{
    my ($self) = @_;
    $self->{ data_type } || undef;
}


# Descriptions: return boundary defined in Content-Type
#    Arguments: $self $args
# Side Effects: none.
# Return Value: none
sub _header_mime_boundary
{
    my ($self, $header) = @_;
    my $m = $header->get('content-type');

    if ($m =~ /boundary=\"(.*)\"/) {
	return $1;
    }
    else {
	undef;
    }
}


# Descriptions: return the type defind in the header's Content-Type field.
#    Arguments: $self
# Side Effects: extra spaces in the type to return is removed.
# Return Value: none
sub _header_data_type
{
    my ($self, $header) = @_;
    my ($type) = split(/;/, $header->get('content-type'));
    if (defined $type) {
	$type =~ s/\s*//g;
	return $type;
    }
    undef;
}


=head1 METHODS to manipulate a chain

=head2 C<head_message()>

no argument. 
It return the head object of a chain of C<Mail::Message> objects.

=head2 C<last_message()>

no argument. 
It return the last object of a chain of C<Mail::Message> objects.

=cut


sub head_message
{
    my ($self) = @_;
    my $m = $self;

    while (1) {
	if (defined $m->{ prev }) { 
	    $m = $m->{ prev };
	}
	else {
	    last;
	}
    }

    $m;
}


sub last_message
{
    my ($self) = @_;
    my $m = $self;

    while (1) {
	if (defined $m->{ next }) {
	    $m = $m->{ next };
	}
	else {
	    last;
	}
    }

    $m;
}


=head2 C<next_message( $obj )>

The next part of C<$self> object is C<$obj>.

=head2 C<prev_message( $obj )>

The previous part of C<$self> object is C<$obj>.

=cut


sub next_message
{
    my ($self, $ref_next_message) = @_;
    $self->{ 'next' } = $ref_next_message;
}


sub prev_message
{
    my ($self, $ref_prev_message) = @_;
    $self->{ 'prev' } = $ref_prev_message;
}



=head1 METHODS to print

=head2 C<print( $fd )>

print out a chain of messages to the file descriptor $fd.
If $fd is not specified, STDOUT is used.

=head2 C<set_print_mode(mode)>

set print mode to C<mode>.

=head2 C<reset_print_mode()>

reset print() mode.

=cut


sub print
{
    my ($self, $fd) = @_;
    $self->_print($fd);
}


sub reset_print_mode
{
    my ($self, $mode) = @_;
    $self->{ _print_mode } = 'raw';
}


sub set_print_mode
{
    my ($self, $mode) = @_;

    if ($mode eq 'raw') {
	$self->{ _print_mode } = 'raw';
    }
    elsif ($mode eq 'smtp') {
	$self->{ _print_mode } = 'smtp';
    }
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print
{
    my ($self, $fd) = @_;
    my $msg  = $self;
    my $args = $self; # e.g. pass _raw_print flag among functions

    # if $fd is not given, we use STDOUT.
    unless (defined $fd) { $fd = \*STDOUT;}

  MSG:
    while (1) {
	# on memory
	if (defined $msg->{ data }) {
	    $msg->_print_messsage_on_memory($fd, $args);
	}
	# not on memory, may be on disk
	elsif (defined $msg->{ filename } &&
	    -f $msg->{ filename }) {
	    $msg->_print_messsage_on_disk($fd, $args);
	}

	last MSG unless $msg->{ 'next' };
	$msg = $msg->{ 'next' };
    }
}


# Descriptions: send the body part of the message on memory to socket
#               replace "\n" in the end of line with "\r\n" on memory.
#               We should do it to use as less memory as possible.
#               So we use substr() to process each line.
#               XXX the message to send out is $self->{ data }.
#    Arguments: $self $socket
# Side Effects: none
# Return Value: none
sub _print_messsage_on_memory
{
    my ($self, $fd, $args) = @_;

    # \n -> \r\n
    my $raw_print_mode = 1 if $self->{ _print_mode } eq 'raw';
    
    # set up offset for the buffer
    my $data  = $self->{ data };
    my $type  = $self->{ data_type } || croak("no data_type");
    my $pp    = $self->{ offset_begin };
    my $p_end = $self->{ offset_end };
    my $logfp = $self->{ _log_function };
    $logfp    = ref($logfp) eq 'CODE' ? $logfp : undef;

    # 1. print content header if exists
    my $header = ($type eq 'rfc822/message.header') ? $data->as_string : $self->{header};
    if (defined $header) {
	$header =~ s/\n/\r\n/g unless (defined $raw_print_mode);
	print $fd $header;
	print $fd ($raw_print_mode ? "\n" : "\r\n");
    }
    return if ($type eq 'rfc822/message.header');
    

    # 2. print content body: write each line in buffer
    my ($p, $len, $buf, $pbuf);
    my $maxlen = length($$data);
  SMTP_IO:
    while (1) {
	$p = index($$data, "\n", $pp);
	last SMTP_IO if $p >= $p_end;

	$len = $p - $pp + 1;
	$len = ($p < 0 ? ($maxlen - $pp) : $len);
	$buf = substr($$data, $pp, $len);

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



# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _print_messsage_on_disk
{
    my ($self, $fd, $args) = @_;

    # \n -> \r\n
    my $raw_print_mode = 1 if $self->{ _print_mode } eq 'raw';
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


=head1 METHODS to manipulate a multipart message

=head2 C<build_mime_multipart_chain($args)>

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub build_mime_multipart_chain
{
    my ($self, $args) = @_;
    my ($head, $prev_m);

    my $base_data_type = $args->{ base_data_type };
    my $msglist        = $args->{ message_list };
    my $boundary       = $args->{ boundary } || "--". time ."-$$-";
    my $dash_boundary  = "--". $boundary;
    my $delbuf         = "\n". $dash_boundary."\n";
    my $delbuf_end     = "\n". $dash_boundary . "--\n";

    for my $m (@$msglist) {
	# delimeter: --boundary
	my $msg = new Mail::Message {
	    boundary       => $boundary,
	    base_data_type => $base_data_type,
	    data_type      => $virtual_data_type{'delimeter'},
	    data           => \$delbuf,
	};

	$head = $msg unless $head; # save the head $msg

	# boundary -> data -> boundary ...
	if (defined $prev_m) { $prev_m->next_message( $msg );}
	$msg->next_message( $m );

	# for the next loop
	$prev_m = $m;
    }

    # close delimeter: --boundary--
    my $msg = new Mail::Message {
	boundary       => $boundary,
	base_data_type => $base_data_type,
	data_type      => $virtual_data_type{'close-delimeter'},
	data           => \$delbuf_end,
    };
    $prev_m->next_message( $msg ); # ... -> data -> close-delimeter

    return $head; # return the pointer to the head of a chain
}


=head2 C<parse_and_build_mime_multipart_chain($args)>

parse the multipart mail. Actually it calculates the begin and end
offset for each part of content, not split() and so on.
C<new()> calls this routine if the message looks MIME multipart.

=cut


# Descriptions: 
#              CAUTION: $args must be the same as it of new().
#
#                      ... preamble ...
#                   V $mpb_begin
#                   ---boundary
#                      ... message 1 ...
#                   ---boundary
#                      ... message 2 ...
#                   V $mpb_end  (V here is not $buf_end)
#                   ---boundary--
#                      ... trailor ...
#
#              RFC2046 Appendix say,
#                        multipart-body := [preamble CRLF]
#                                           dash-boundary transport-padding CRLF
#                                           body-part *encapsulation
#                                           close-delimiter transport-padding
#                                           [CRLF epilogue]
#
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub parse_and_build_mime_multipart_chain
{
    my ($self, $args) = @_;

    # check input parameters
    return undef unless $args->{ boundary };
    return undef unless $args->{ data  };

    # base content-type
    my $base_data_type = $args->{ data_type };

    # boundaries of the continuous multipart blocks
    my $data            = $args->{ data };  # reference to data
    my $data_end        = length($$data);   # end position of the data
    my $boundary        = $args->{ boundary }; # MIME boundary string
    my $dash_boundary   = "--".$boundary;
    my $delimeter       = "\n". $dash_boundary;
    my $close_delimeter = $delimeter ."--";

    # 1. check the preamble before multipart blocks
    #    XXX mpb = multipart-body
    my $mpb_begin       = index($$data, $delimeter, 0);
    my $mpb_end         = index($$data, $close_delimeter, 0);
    my $pb              = 0; # pb = position of the beginning in $data
    my $pe              = $mpb_begin; # pe = position of the end in $data
    $self->_set_pos( $pe + 1 );

    # prepare lexical variables
    my ($msg, $next_part, $prev_part, @m);
    my $i = 0; # counter to indicate the $i-th message
    do {
	# 2. analyze the region for the next part in $data
	#     we should check the condition "$pe > $pb" here
	#     to avoid the empty preamble case.
	# XXX this function is not called
	# XXX if there is not the prededing preamble.
	if ($pe > $pb) { # XXX not effective region if $pe <= $pb
	    my ($header, $pb) = _get_mime_header($data, $pb);

	    my $args = {
		boundary       => $boundary,
		offset_begin   => $pb,
		offset_end     => $pe,
		header         => $header || undef,
		data           => $data,
		base_data_type => $base_data_type,
	    };
	    my $default = ($i == 0) ? $virtual_data_type{'preamble'} : undef;
	    $args->{ data_type } = _get_data_type($args, $default);

	    $m[ $i++ ] = $self->_alloc_new_part($args);
	}

	# 3. where is the region for the next part?
	($pb, $pe) = $self->_next_part_pos($data, $delimeter);

	# 4. insert a multipart delimiter
	#    XXX we malloc(), "my $tmpbuf", to store the delimeter string.
	if ($pe > $mpb_end) { # check the closing of the blocks or not
	    my $buf = $close_delimeter."\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		data           => \$buf,
		data_type      => $virtual_data_type{'close-delimiter'},
		base_data_type => $base_data_type,
	    });

	}
	else {
	    my $buf = $delimeter."\n";
	    $m[ $i++ ] = $self->_alloc_new_part({
		data           => \$buf,
		data_type      => $virtual_data_type{'delimiter'},
		base_data_type => $base_data_type,
	    });
	}

    } while ($pe <= $mpb_end);

    # check the trailor after multipart blocks exists or not.
    {
	my $p = index($$data, "\n", $mpb_end + length($close_delimeter)) +1;
	if (($data_end - $p) > 0) {
	    $m[ $i++ ] = $self->_alloc_new_part({
		boundary       => $boundary,
		offset_begin   => $p,
		offset_end     => $data_end,
		data           => $data,
		data_type      => $virtual_data_type{'trailor'},
		base_data_type => $base_data_type,
	    });
	}
    }

    # build a chain of multipart blocks and delimeters
    my $j = 0;
    for ($j = 0; $j < $i; $j++) {
	if (defined $m[ $j + 1 ]) {
	    next_message( $m[ $j ], $m[ $j + 1 ] );
	}
	if (($j > 1) && defined $m[ $j - 1 ]) {
	    prev_message( $m[ $j ], $m[ $j - 1 ] );
	}

	if (0) { # debug
	    printf STDERR "%d: %-30s %-30s\n", $j,
		$m[ $j]->{ base_data_type },
		$m[ $j]->{ data_type };
	}
    }

    # chain $self and our chains built here.
    next_message($self, $m[0]);
}


sub _get_data_type
{
    my ($args, $default) = @_;
    my $buf = $args->{ header } || '';

    if ($buf =~ /Content-Type:\s*(\S+)(\;|\s*$)/) {
	return $1;
    }
    else {
	$default
    }
}


sub _get_mime_header
{
    my ($data, $pos_begin) = @_;
    my $pos = index($$data, "\n\n", $pos_begin) + 1;
    my $buf = substr($$data, $pos_begin, $pos - $pos_begin);

    if ($buf =~ /Content-Type:\s*(\S+)\;/) {
	return ($buf, $pos + 1);
    }
    elsif ($buf =~ /Content-Type:\s*(\S+)\s*$/) {
	return ($buf, $pos + 1);
    }
    else {
	return ('', $pos_begin);
    }
}


=head2 C<build_mime_header($args)>

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub build_mime_header
{
    my ($self, $args) = @_;
    my ($buf, $charset);
    my $data_type = $args->{ data_type };

    if ($data_type =~ /^text/) {
	$charset = $args->{ charset } || 'us-ascii';
    }

    $buf .= "Content-Type: $data_type" if defined $data_type;
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
# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _alloc_new_part
{
    my ($self, $args) = @_;
    my $me = {};

    _create($me, $args);
    return bless $me, ref($self);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _next_part_pos
{
    my ($self, $data, $delimeter) = @_;
    my ($len, $p, $pb, $pe, $pp);
    my $maxlen = length($$data);

    # get the next deliemter position
    $pp  = $self->_get_pos();
    $p   = index($$data, $delimeter, $pp);
    $self->_set_pos( $p + 1 );

    # determine the begin and end of the next block without delimiter
    $len = $p > 0 ? ($p - $pp) : ($maxlen - $pp);
    $pb  = $pp + length($delimeter);
    $pe  = $pb + $len - length($delimeter);

    return ($pb, $pe);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _get_pos
{
    my ($self) = @_;
    defined $self->{ _current_pos } ? $self->{ _current_pos } : 0;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub _set_pos
{
    my ($self, $pos) = @_;
    $self->{ _current_pos } = $pos;
}


=head1 METHODS (UTILITY FUNCTIONS)

=head2 C<size()>

return the message size.

=head2 C<is_empty()>

return this message has empty content or not.

=cut


my $total = 0;

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub size
{
    my ($self) = @_;
    my $rc = $self->{ data };
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


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub is_empty
{
    my ($self) = @_;
    my $size   = $self->size;
    my $rc     = $self->{ data };

    if ($size == 0) { return 1;}
    if ($size <= 8) {
	if ($$rc =~ /^\s*$/) { return 1;}
    }

    # false
    return 0;
}


=head2 C<header_size()>

=head2 C<body_size()>

=cut

sub header_size
{
    my ($self) = @_;
    $self->{ data_info }->{ header_size };
}


sub body_size
{
    my ($self) = @_;
    $self->{ data_info }->{ body_size };
}


sub envelope_sender
{
    my ($self) = @_;
    $self->{ data_info }->{ envelope_sender };
}


=head2 C<get_data_type()>

return the data type of the message object. 

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub get_data_type
{
    my ($self) = @_;
    my $type = $self->{ data_type };
    $type =~ s/;//;
    $type;
}


=head2 C<num_paragraph()>

return the number of paragraphs in the message ($self).

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub num_paragraph
{
    my ($self) = @_;

    # exit ASAP if the message is empty. 
    return 0 if $self->is_empty();

    my $pb      = $self->{ offset_begin };
    my $pe      = $self->{ offset_end };
    my $bodylen = $self->size;
    my $data    = $self->{ data };

    my $i  = 0; # the number of paragraphs
    my $p  = $pb;
    my $pp = $p;

    # skip "\n" in the first and end of the buffer
    while (substr($$data, $p, 1) eq "\n") { $p++;}
    while (substr($$data, $pe -1, 1) eq "\n") { $pe--;} 

    my (@pmap) = ($pb);
  LINE:
    while ($p < $pe) {
	$pp = index($$data, "\n\n", $p);
	if ($pp < $p ||    # not found
	    $pp >= $pe ) { # over the end of buffer boundary

	    push(@pmap, $pe); # the end of the last paragraph
	    last LINE; 
	}
	else {
	    # skip trailing "\n" after "\n\n"
	    while (substr($$data, $pp, 1) eq "\n") { $pp++;}

	    push(@pmap, $pp) if $pp > 0;

	    $p = $pp;
	}
    }

    # XXX debug
    if (0) {
	for (my $i = 0; $i < $#pmap; $i++ ) {
	    my $p  = $pmap[ $i ];
	    my $pp = $pmap[ $i + 1 ];
	    print STDERR "($p,$pp)<", substr($$data, $p, $pp - $p) , ">\n";
	}
	print STDERR "( @pmap )\n"; 
    }

    $#pmap;
}


=head2 C<header_in_body_part($size)>

get header in the content.

=head2 C<data_in_body_part($size)>

get body part in the content, 
which is the whole mail or a part of multipart.

=cut


sub header
{
    my ($self) = @_;
    $self->header_in_body_part(@_[1 .. $#_]);
}


sub data
{
    my ($self) = @_;
    $self->data_in_body_part(@_[1 .. $#_]);
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub header_in_body_part
{
    my ($self, $size) = @_;
    return defined $self->{ header } ? $self->{ header } : undef;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub data_in_body_part
{
    my ($self, $size) = @_;
    my $data           = $self->{ data };
    my $base_data_type = $self->{ base_data_type };
    my ($pos, $pos_begin, $msglen);

    # if the content is undef, do nothing.
    return undef unless $data; 

    if ($base_data_type =~ /multipart/i) {
	$pos_begin = $self->{ offset_begin };
	$msglen    = $self->{ offset_end } - $pos_begin;
    }
    else {
	$pos_begin = 0;
	$msglen    = length($$data);
    }

    $size ||= 512;
    if ($msglen < $size) { $size = $msglen;}
    return substr($$data, $pos_begin, $size);
}


=head2 C<get_first_plaintext_message($args)>

return the Messages object for the first "plain/text" message in a
chain. For example,

         $m    = $msg->get_first_plaintext_message();
         $body = $m->data_in_body_part();

where $body is the mail body (string).

=cut

# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub get_first_plaintext_message
{
    my ($self, $args) = @_;
    my $size = $args->{ 'size' } || 512;
    my $mp ; # mp = message pointer

    # Let's go along the chain of message objects.
    # This routine return the first reference to the message with the
    # type = ' plain/text'
    for ($mp = $self; 
	 defined $mp->{ data } || defined $mp->{ 'next' }; 
	 $mp = $mp->{ 'next' }) {
	my $type = $mp->get_data_type;

	if ($type eq 'text/plain') {
	    return $mp;
	}
    }

    return undef;
}


=head2 C<set_log_function()>

internal use. set CODE REFERENCE to the log function

=cut

# Descriptions: set log function pointer (CODE REFERNCE)
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub set_log_function
{
    my ($self, $fp) = @_;
    $self->{ _log_function } = $fp;
}


=head2 C<get_data_type_list()>

show the list of data_types in the chain order.
This is defined for debug and removed in the future.

=cut

# Descriptions: XXX debug, remove this in the future
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub get_data_type_list
{
    my ($msg) = @_;
    my ($m, @buf, $i);

    for ($i = 0, $m = $msg; defined $m ; $m = $m->{ 'next' }) {
	$i++;
	my $data = $m->{'data'};
	push(@buf, sprintf("type[%2d]: %-25s | %s", 
			   $i, $m->{'data_type'}, $m->{'base_data_type'}));
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

Mail::Message appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
