#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Message.pm,v 1.56 2002/04/28 09:42:17 fukachan Exp $
#

package Mail::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $InComingMessage);
use Carp;

my $debug = 0;

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

To parse the stdin and print it,

    use Mail::Message;
    my $m = Mail::Message->parse({ fh => \*STDIN });
    $m1->print;

to parse file C<$filename>,

    use Mail::Message;
    my $m = Mail::Message->parse({ file => $filename });

to make a message of the body part,

    my $msg = new Mail::Message {
	boundary  => $mime_boundary,
	data_type => $data_type_defined_in_header_content_type,
	data      => \$message_body,
    };

Please specify SCALAR REFERENCE as C<data>.

To make a message of the header,

    my $msg = new Mail::Message {
	boundary  => $mime_boundary,
	data_type => 'text/rfc822-headers',
	data      => $header,
    };

Please specify C<Mail::Header> or C<FML::Header> object as C<data>.

   TODO:

    It is useful to C<parse()> the message but inconvenient to build a
    message from scratch.

=head1 DESCRIPTION

=head2 OVERVIEW

C<A mail message> has the data to send and some delivery information
in the header.
C<Mail::Message> objects construct a chain of header and data.
C<Mail::Message> object holds them and other control information such
as the reference to the next C<Mail::Message> object, et. al.

C<Mail::Message> provides useful functions to analyze a mail message.
such as to analyze MIME information,
to check and get information on message (part) size et. al.
It can handle MIME multipart.

C<Mail::Message> also can compose a multipart message in primitive
way.
It is useful for you to use C<Mail::Message::Compose> class to handle
MIME multipart in more clever way.
It is an adapter for C<MIME::Lite> class.

=head2 INTERNAL REPRESENTATION

One mail consists of a message or messages.
They are all plain text or a set of plain text, images, html and so on.
C<Mail::Message> is a chain which represents
a set of several kinds of messages.


Elements of one object chain are bi-directional among them.
For example, a MIME/multipart message is a chain of message objects
such as

    undef -> mesg1 -> mesg2 -> mesg3 -> undef
          <-       <-       <-       <-

To describe such a chain, a message object consists of
bi-directional object chains.

Described below, C<MIME delimiter> is also treated as a virtual
message for convenience.

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

If the message is just a plain/text, which is usual,
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


=head1 METHODS to create a message object

=head2 new($args)

constructor which makes C<one> message object.

In almost cases, new() is used to make a message object,
which is a part of one mail message.

We use this framework to make a header object by specifying

       data_type => text/rfc822-headers,
       data      => Mail::Header or FML::Header object,

in $args (HASH REFERENCE). Pay attention the type of C<data>.

C<WARNING:>

It is useful to treate the message header and body in separate
way when we compose the message by sequential attachments.

If you build a message by scratch, you must compose a header
object.
When you C<parse()> to a mail,
you will get the whole set of a chain and a body message.

=cut


# Descriptions: usual constructor
#               call $self->_build_message($args) if $args is given.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(Mail::Message object)
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    my $data   = '';

    # XXX alloc memory area to hold the whole message.
    # XXX (NOT NEEDED ? but only parse() needs $InComingMessage ?)
    # $InComingMessage = \$data;

    bless $me, $type;

    if ($args) { _build_message($me, $args);}

    return bless $me, $type;
}


# Descriptions: adapter to forward the request to make a message object.
#               It forwards each request by each content-type.
#               parse_and_build_mime_multipart_chain() is applied
#               for a multipart message
#               and __build_message() for a plain/* message.
#
#               This is a primitive method to build a template message object
#               to follow the given $args (a hash reference).
#
#               In almost cases, _build_message() is used to make a
#               message body part object. We use this to make a header object
#               by specifying {
#                           data_type => text/rfc822-headers,
#                           data      => Mail::Header or FML::Header object,
#               } in $args.
#
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a chain of OBJ
# Return Value: none
sub _build_message
{
    my ($self, $args) = @_;

    # set up template anyway
    $self->_set_up_template($args);

    # parse the non multipart mail and build a chain
    if (defined( $args->{ data_type } ) &&
	$args->{ data_type } =~ /multipart/i) {
	$self->parse_and_build_mime_multipart_chain($args);
    }
    # parse the mail data.
    else {
	$self->__build_message($args);
    }
}


# Descriptions: build a Mail::Message object template
#    Arguments: OBJ($self) HASH_REF($args)
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
    $self->{'header'  }   = $args->{'header'} || undef;

    # information on data and the type for the message.
    $self->{'mime_version'}   = $args->{'mime_version'}   || 1.0;
    $self->{'data_type'}      = $args->{'data_type'}      || 'text/plain';
    $self->{'base_data_type'} =
	$args->{'base_data_type'} || $self->{'data_type'} || undef;

    # default print out mode
    set_print_mode($self, 'raw');
}


# Descriptions: simple plain/text builder
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: set up the default values if needed
# Return Value: none
sub __build_message
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
	    carp("__build_message: $filename not exist");
	}
    }
    else {
	carp("__build_message: neither data nor filename specified");
    }
}


=head2 dup_header()

duplicate a message chain.
Precisely speaking, it duplicates only the header object
but not duplicate body part.
So, the next object of the duplicated header,
C<dup_header0> in the following figure,
is the first body part C<part1> of the origianl chain.

    header0 ----> part1 -> part2 -> ...
                   A
                   |
    dup_header0 ---

=cut


# Descriptions: duplicate a message chain.
#    Arguments: OBJ($self)
# Side Effects: create new object
# Return Value: OBJ
sub dup_header
{
    my ($self) = @_;

    # if the head object is rfc822 header, dup the header.
    if ($self->{ data_type } eq 'text/rfc822-headers') {
	my $dupmsg  = new Mail::Message; # make a new object
	my $dupmsg2 = new Mail::Message; # make a new object
	my $body    = $self->{ next };

	# 1. copy header and the first body part
	for (keys %$self) { $dupmsg->{ $_ }  = $self->{ $_ };}
	for (keys %$body) { $dupmsg2->{ $_ } = $body->{ $_ };}

	# 2. overwrite only header data in $dupmsg
	my $header = $self->{ data };
	$dupmsg->{ data } = $header->dup();
	$dupmsg->_next_message_is( $body );
	$body->_prev_message_is( $dupmsg );

	# 3. return the new object.
	return $dupmsg;
    }
    else {
	undef;
    }
}


=head1 METHODS TO PARSE

=head2 parse($args)

read data from file descriptor C<$fd> and parse it to the mail header
and the body.

    parse({
	fd => $fd,
    });

You can specify file not file descriptor.

    parse({
	file => $file,
    });

=cut


# Descriptions: parse given file (file path or descriptor)
#               create header OBJ and body OBJ chain.
#               combine them into one chain of Mail::Message OBJ,
#               so that we get
#                  header -> body1 -> body2 -> ... body-end
#               object chain.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a chain of objects
# Return Value: OBJ
sub parse
{
    my ($self, $args) = @_;
    my $fd;

    if (defined($args->{ 'file' })) {
	use FileHandle;
	$fd = new FileHandle $args->{ 'file' };
    }
    else {
	$fd = $args->{ fd } || \*STDIN;
    }

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
    $me->_next_message_is( $ref_body );
    $ref_body->_prev_message_is( $me );

    # return information
    if (defined($InComingMessage)) {
	$result->{ body_size } = length($$InComingMessage);
    }
    else {
	$result->{ body_size } = 0;
    }
    $me->{ data_info }     = $result;

    # return the object
    $me;
}


# Descriptions: cut off content into header and body
#               and prepare buffer for further parsing
#    Arguments: OBJ($self) HANDLE($fd) HASH_REF($result)
# Side Effects: fill in $inComingMessage on memory
# Return Value: none
sub _parse
{
    my ($self, $fd, $result) = @_;
    my ($header, $header_size, $p, $buf, $data);
    my $total_buffer_size;

  DATA:
    while ($p = sysread($fd, $data, 1024)) {
	$total_buffer_size += $p;
	$buf               .= $data;

	if (($p = index($buf, "\n\n", 0)) > 0) {
	    $header      = substr($buf, 0, $p + 1);
	    $header_size = $p + 1;
	    $$InComingMessage = substr($buf, $p + 2);
	    last DATA;
	}
    }

    # extract mail body and put it to $$InComingMessage
  DATA:
    while ($p = sysread($fd, $data, 1024)) {
	$total_buffer_size += $p;
	$$InComingMessage  .= $data;
    }

    # read the message (mail body) from the incoming mail
    my $body_size = 0;
    if (defined($InComingMessage)) {
	$body_size = length($$InComingMessage);
    }

    if ($debug > 2) {
	print STDERR "  (debug) header_size: $header_size\n";
	print STDERR "  (debug)   body_size: $body_size\n";
    }

    # result to return
    $result->{ header }      = $header;
    $result->{ header_size } = $header_size;
    $result->{ body_size }   = $body_size;
    $result->{ total_read_size } = $total_buffer_size;
}


# Descriptions: return hash array for header for further parsing.
#               get reverse_path if possible.
#    Arguments: OBJ($self) HASH_REF($r)
# Side Effects: update $r
# Return Value: ARRAY_REF
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


# Descriptions: create header object (the head of OBJ chain)
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($r)
# Side Effects: create header OBJ, the head of OBJ chain
# Return Value: OBJ
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
    __build_message($self, {
	base_data_type => $data_type,
	data_type      => "text/rfc822-headers",
	data           => $header_obj,
    });

    # save header object
    $r->{ header } = $header_obj;
}


# Descriptions: create OBJ chain for message "only" body part.
#               XXX header OBJ is created at another part
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($result)
# Side Effects: create OBJ(s)
# Return Value: OBJ
sub _build_body_object
{
    my ($self, $args, $result) = @_;

    # XXX we use data_type (type defined in Content-Type: field) here.
    # XXX "base_data_type" is used only internally.
    return new Mail::Message {
	boundary  => $self->_header_mime_boundary($result->{ header }),
	data_type => $self->_header_data_type($result->{ header }),
	data      => $InComingMessage,
    };
}


=head2 whole_message_header()

return Mail::Header object corresponding to the header part for the
object C<$self>.

=head2 whole_message_body()

alias of C<whole_message_body_head()>.

=head2 whole_message_body_head()

return the first or the head Mail::Message object in a chain for the
body part of the message C<$self>.

=cut


# Descriptions: get header OBJ (Mail::Header not Mail::Message)
#               in the head of chain.
#               HEADER(THIS PART) -> body1 -> body2 -> ...
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ(Mail::Header)
sub whole_message_header
{
    my ($self) = @_;
    my $m = $self->find( { data_type => 'text/rfc822-headers' } );

    defined $m ? $m->{ data } : undef ;
}


# Descriptions: get the head OBJ of body part in the chain.
#               header -> body1 (HERE) -> body2 -> ...
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ(Mail::Message)
sub whole_message_body_head
{
    my ($self) = @_;
    my $type = $self->data_type();
    return ( ($type eq 'text/rfc822-headers') ? $self->{ next } : undef );
}


# Descriptions: get the head OBJ of body part in the chain.
#               header -> body1 (HERE) -> body2 -> ...
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ(Mail::Message)
sub whole_message_body
{
    my ($self) = @_;
    $self->whole_message_body_head();
}


# Descriptions: return the incoming message on memory as string reference
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR_REF
sub whole_message_as_string_ref
{
    my ($self) = @_;

    return $InComingMessage;
}


=head2 whole_message_header_data_type()

return the C<type> string. It is the whole message type which is
speculated from header C<Content-Type:>.

=cut


# Descriptions: type of the whole message, which is defined in
#               Content-Type: header field.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub whole_message_header_data_type
{
    my ($self) = @_;
    my $hdr = $self->whole_message_header();
    $self->_header_data_type($hdr);
}


# Descriptions: return boundary defined in Content-Type
#    Arguments: OBJ($self) OBJ($Header)
# Side Effects: none.
# Return Value: STR
sub _header_mime_boundary
{
    my ($self, $header) = @_;
    my $m = $header->get('content-type');

    if (defined($m) && ($m =~ /boundary\s*=\s*\"(.*)\"/i)) { # case insensitive
	return $1;
    }
    else {
	undef;
    }
}


# Descriptions: return the type defind in the header's Content-Type field.
#    Arguments: OBJ($self) OBJ($header)
# Side Effects: extra spaces in the type to return is removed.
# Return Value: STR
sub _header_data_type
{
    my ($self, $header) = @_;
    my $ctype = $header->get('content-type');

    if (defined($ctype) && $ctype) {
	my ($type) = split(/;/, $header->get('content-type'));
	if (defined($type) && $type) {
	    $type =~ s/\s*//g;
	    $type =~ tr/A-Z/a-z/;
	    return $type;
	}
    }

    return undef;
}


=head1 METHODS to manipulate a chain

=head2 find($args)

return the first C<Mail::Message> object with the specified attrribute.
You can specify C<data_type> in C<$args> HASH REFERENCE.
For example,

    $m = $msg->find( { data_type => 'text/plain' } );

C<$m> is the first "text/plain" object in a chain of C<$msg> object.
This method is used for the exact match.

    $m = $msg->find( { data_type_regexp => 'text' } );

C<$m> is the first "text/*" object in a chain of C<$msg> object.

=cut


# Descriptions: find the first OBJ with the specified data_type or
#               data_type_regexp.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(Mail::Message)
sub find
{
    my ($self, $args) = @_;

    if (defined $args->{ data_type } && $args->{ data_type }) {
	my $type = $args->{ data_type };
	my $mp   = $self;
	for ( ; $mp; $mp = $mp->{ next }) {
	    if ($debug) { print "   msg->find(", $type, " eq $type)\n";}
	    if ($type eq $mp->data_type()) {
		if ($debug) { print "   msg->find($type match) = $mp\n";}
		return $mp;
	    }
	}
    }
    elsif (defined $args->{ data_type_regexp } && 
	   $args->{ data_type_regexp }) {
	my $regexp = $args->{ data_type_regexp };
	my $mp     = $self;
	for ( ; $mp; $mp = $mp->{ next }) {
	    my $type = $mp->data_type();
	    if ($debug) { print "   msg->find(", $type, "=~ /$regexp/)\n";}
	    if ($type =~ /$regexp/i) {
		if ($debug) { print "   msg->find($type match) = $mp\n";}
		return $mp;
	    }
	}
    }

    return undef;
}


=head2 __head_message()

no argument.
It return the head object of a chain of C<Mail::Message> objects.
Usually it is the header part.

=head2 __last_message()

no argument.
It return the last object of a chain of C<Mail::Message> objects.
Usually it is the last message in the body part.

=cut


# Descriptions: get the head OBJ in the chain.
#               obj1 (HERE) -> obj2 -> ... -> obj_end
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub __head_message
{
    my ($self) = @_;
    my $m = $self;

  LINK:
    while (1) {
	if (defined $m->{ prev }) {
	    $m = $m->{ prev };
	}
	else {
	    last LINK;
	}
    }

    return $m;
}


# Descriptions: get the last OBJ in the chain.
#               obj1 -> obj2 -> ... -> obj_end(HERE)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub __last_message
{
    my ($self) = @_;
    my $m = $self;

  LINK:
    while (1) {
	if (defined $m->{ next }) {
	    $m = $m->{ next };
	}
	else {
	    last LINK;
	}
    }

    return $m;
}


=head2 _next_message_is( $obj )

The next part of C<$self> object is C<$obj>.

=head2 _prev_message_is( $obj )

The previous part of C<$self> object is C<$obj>.

=cut


# Descriptions: set next message in the chain
#    Arguments: OBJ($self) OBJ(ref_next_message)
# Side Effects: update next pointer in object
# Return Value: OBJ
sub _next_message_is
{
    my ($self, $ref_next_message) = @_;
    $self->{ 'next' } = $ref_next_message;
}


# Descriptions: set previous message in the chain
#    Arguments: OBJ($self) OBJ(ref_prev_message)
# Side Effects: update prev pointer in object
# Return Value: OBJ
sub _prev_message_is
{
    my ($self, $ref_prev_message) = @_;
    $self->{ 'prev' } = $ref_prev_message;
}



=head1 METHODS to print

=head2 print( $fd )

print out a chain of messages to the file descriptor $fd.
If $fd is not specified, STDOUT is used.

=head2 set_print_mode(mode)

set print mode to C<mode>.
The available <mode> is C<raw> or C<smtp>.

=head2 reset_print_mode()

reset print() mode.
It sets the mode to be C<raw>.

=cut


# Descriptions: print message into file descriptor $fd
#    Arguments: OBJ($self) HANDLE($fd)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $fd) = @_;
    $self->_print($fd);
}


# Descriptions: reset mode of print() to 'raw' (default)
#    Arguments: OBJ($self)
# Side Effects: update object
# Return Value: none
sub reset_print_mode
{
    my ($self) = @_;
    $self->{ _print_mode } = 'raw';
}


# Descriptions: set mode of print()
#               mode is either of 'raw' or 'smtp'.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: update object
# Return Value: none
sub set_print_mode
{
    my ($self, $mode) = @_;

    if (defined($mode) && $mode) {
    if ($mode eq 'raw') {
	$self->{ _print_mode } = 'raw';
    }
    elsif ($mode eq 'smtp') {
	$self->{ _print_mode } = 'smtp';
    }
    }
}


# Descriptions: print message, all messages in the current chain ($self).
#    Arguments: OBJ($self) HANDLE($fd)
# Side Effects: none
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


# Descriptions: $self is the head of chain or not ?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub _is_head_message
{
    my ($self) = @_;
    my $hm = $self->__head_message;
    ($hm eq $self) ? 1 : 0;
}


# Descriptions: send the body part of the message on memory to socket
#               replace "\n" in the end of line with "\r\n" on memory.
#               We should do it to use as less memory as possible.
#               So we use substr() to process each line.
#               XXX the message to send out is $self->{ data }.
#    Arguments: OBJ($self) HANDLE($fd) HASH_REF($args)
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
    my $header = undef;
    if ($type eq 'text/rfc822-headers' &&
	(ref($data) eq 'Mail::Header' || ref($data) eq 'FML::Header')) {
	$header = $data->as_string;
    }
    else {
	$header = $self->{header};
    }

    if (defined $header) {
	$header =~ s/\n/\r\n/g unless (defined $raw_print_mode);
	print $fd $header;
	print $fd ($raw_print_mode ? "\n" : "\r\n");
    }

    # skip the first rfc822 header (which is the real header for delivery).
    return if ($type eq 'text/rfc822-headers') && $self->_is_head_message();


    # 2. print content body: write each line in buffer
    my ($p, $len, $buf, $pbuf);
    my $maxlen = length($$data);
    if ($debug > 1) {
	my $r = substr($$data, $pp, $p_end - $pp);
	print STDERR "output($pp, $p_end) = {$r}\n";
    }
  SMTP_IO:
    while (1) {
	$p = index($$data, "\n", $pp);
	print STDERR "try to print(p=$p pp=$pp < $p_end)\n" if $debug > 1;

	# handle buffer (MIME part) without trailing "\n".
	# index("\n") can pick up both
	#     the last "\n" of the MIME part
	# and
	#     "\n" of MIME delimiter string "CRLF delimiter"
	# since index() searches the whole not a part of the mail.
	# We need to identify these two cases restrictly.
	last SMTP_IO if $p == $p_end && substr($$data, $p-1, 1) eq "\n";
	last SMTP_IO if $p > $p_end;

	$len = $p - $pp + 1;

	# handle buffer wihtout trailing "\n"
	if ($p == $p_end && substr($$data, $p-1, 1) ne "\n") {
	    $len = $p_end - $pp;
	}
	else {
	    $len = ($p < 0 ? ($maxlen - $pp) : $len);
	}
	$buf = substr($$data, $pp, $len);

	if ($debug > 1) {
	    print STDERR "	\$len = $p - $pp + 1;\n";
	    print STDERR "	$len = ($p < 0 ? ($maxlen - $pp) : $len);\n";
	    print STDERR "print($pp,$len){$buf}\n";
	}

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


# Descriptions: print out
#    Arguments: OBJ($self) HANDLE($fd) HASH_REF($args)
# Side Effects: none
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

=head2 build_mime_multipart_chain($args)

build a mime message by scratch.
This may be obsolete since
we use C<MIME::Lite> to build a mime message now.

=cut


# Descriptions: build a mime message by scratch.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a chain
# Return Value: OBJ
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
	if (defined $prev_m) { $prev_m->_next_message_is( $msg );}
	$msg->_next_message_is( $m );

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
    $prev_m->_next_message_is( $msg ); # ... -> data -> close-delimeter

    return $head; # return the pointer to the head of a chain
}


=head2 parse_and_build_mime_multipart_chain($args)

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
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
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

    # fix the end of multipart block against broken MIME/multipart
    my $broken_close_delimiter = 1 if $mpb_end < 0;
    {
	# oops, no delimiter is not found !!!
	if ($mpb_begin < 0) {
	    print "   *** broken multipart message.\n" if $debug;
	    my $args = {
		offset_begin => 0,
		offset_end   => $data_end,
		data         => $data,
	    };
	    my $m = $self->_alloc_new_part($args);
	    return _next_message_is($self, $m);
	}
	# close-delimiter is not found.
	elsif ($mpb_end < 0) {
	    print "   * broken close-delimiter multipart message.\n" if $debug;
	    $mpb_end = $data_end;
	}
    }

    # XXX We should check the first string is delimiter or not.
    # XXX We need Content-Type: in each block. This may be a bug ?
    # XXX To avoid the first part without no content-type, we check
    # XXX the first string in the body data.
    my $preamble = "\n".substr($$data, 0, length($delimeter) - 1);
    my $no_preamble = 1 if $preamble eq $delimeter;

    #
    # HERE WE GO but debug firstly :)
    #
    print "\tmpb($mpb_begin, $mpb_end)\n\t----------\n\n" if $debug;
    print "\tno preamble\n" if $debug && $no_preamble;


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
	    print "   new block ($pb, $pe) " if $debug;

	    my ($header, $pb) = _get_mime_header($data, $pb, $pe);
	    if ($debug) {
		my $type; $header =~ /(\w+\/\w+)/ && ($type = $1);
		print "type=$type ";
		print "\n   *new block ($pb, $pe) header={$header}\n";
	    }

	    my $args = {
		boundary       => $boundary,
		offset_begin   => $pb,
		offset_end     => $pe,
		header         => $header || undef,
		data           => $data,
		base_data_type => $base_data_type,
	    };

	    my $default;
	    if ($i == 0) {
		$default = $no_preamble ? 'text/plain':
		    $virtual_data_type{'preamble'};
	    }

	    $args->{ data_type } = _data_type($args, $default);

	    if ($debug) {
		my $r = substr($$data, $pb, $pe - $pb);
		print "[ data_type=$args->{ data_type } ]\n";
		print "{$r}\n" if $debug > 1;
	    }

	    $m[ $i++ ] = $self->_alloc_new_part($args);
	}

	# 3. where is the region for the next part?
	($pb, $pe) = $self->_next_part_pos($data, $delimeter);
	if ($debug) {
	    print "\tnext block:";
	    print "   ($pb, $pe)\t$mpb_begin<->$mpb_end/$data_end\n";
	    print "   {", substr($$data, $pb, $pe-$pb), "}\n" if 0;
	    print "\n";
	}

	# 4. insert a multipart delimiter
	#    XXX we malloc(), "my $tmpbuf", to store the delimeter string.
	if ($pe > $mpb_end) { # check the closing of the blocks or not
	    if ($broken_close_delimiter) {
		; # not close multipart ;)
	    }
	    else {
		print "   close-delimiter\n" if $debug;

		my $buf = $close_delimeter."\n";
		$m[ $i++ ] = $self->_alloc_new_part({
		    data           => \$buf,
		    data_type      => $virtual_data_type{'close-delimiter'},
		    base_data_type => $base_data_type,
		});
	    }
	}
	else {
	    if ($pb == $pe) {
		print "   *** broken condition pb=$pb pe=$pe ***\n" if $debug;
	    }
	    else {
		print "   delimiter\n" if $debug;

		my $buf = $delimeter."\n";
		$m[ $i++ ] = $self->_alloc_new_part({
		    data           => \$buf,
		    data_type      => $virtual_data_type{'delimiter'},
		    base_data_type => $base_data_type,
		});
	    }
	}

    } while ($pe <= $mpb_end && ( abs($pe - $pb) > 0));

    # check the trailor after multipart blocks exists or not.
    if ($broken_close_delimiter) {
	; # not close multipart ;)
    }
    else {
	my $p = index($$data, "\n", $mpb_end + length($close_delimeter)) +1;
	if (($data_end - $p) > 0) {
	    print "   trailor\n" if $debug;

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
	    _next_message_is( $m[ $j ], $m[ $j + 1 ] );
	}
	if (($j > 1) && defined $m[ $j - 1 ]) {
	    _prev_message_is( $m[ $j ], $m[ $j - 1 ] );
	}
    }

    # chain $self and our chains built here.
    _next_message_is($self, $m[0]);
}


# Descriptions: get content type in $args->{ header }
#    Arguments: HASH_REF($args) STR($default)
# Side Effects: none
# Return Value: STR
sub _data_type
{
    my ($args, $default) = @_;
    my $buf = $args->{ header } || '';

    if ($buf =~ /Content-Type:\s*(\S+\w+)(\n|\;|\s*$)/) {
	return "\L$1";
    }
    else {
	$default
    }
}


# Descriptions: get header part in $data, which is data in Mail::Message.
#               this header is not header for the whole message but
#               each header in Mail::Message.
#               each message has each mime header, e.g. for MIME/multipart.
#    Arguments: REF_STR($data) NUM($pos_begin) NUM($pos_end)
# Side Effects: none
# Return Value: (STR, NUM)
sub _get_mime_header
{
    my ($data, $pos_begin, $pos_end) = @_;
    my $pos = index($$data, "\n\n", $pos_begin) + 1;
    my $buf = substr($$data, $pos_begin, $pos - $pos_begin);

    print "\t_get_mime_header pos=$pos should be < end=$pos_end\n" if $debug;

    if ($pos > $pos_end) {
	return ('', $pos_begin);
    }
    elsif ($buf =~ /Content-Type:\s*(\S+)\;/i) {
	return ($buf, $pos + 1);
    }
    elsif ($buf =~ /Content-Type:\s*(\S+)\s*$/i) {
	return ($buf, $pos + 1);
    }
    elsif ($buf =~ /Content-Type:\s*(\S+)\s*/i) {
	return ($buf, $pos + 1);
    }
    else {
	return ('', $pos_begin);
    }
}


=head2 build_mime_header($args)

make a fundamental mime header fields and return it.

=cut


# Descriptions: make a fundamental mime header fields and return it.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub build_mime_header
{
    my ($self, $args) = @_;
    my ($buf, $charset);
    my $data_type = $args->{ data_type };

    if ($data_type =~ /^text/i) {
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
# Descriptions: make a new Mail::Message object.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a new Mail::Message object.
# Return Value: OBJ
sub _alloc_new_part
{
    my ($self, $args) = @_;
    my $me = {};

    __build_message($me, $args);
    return bless $me, ref($self);
}

# Descriptions: delete message part link
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: null
sub delete_message_part_link
{
    my ($self) = @_;
    my $mp   = $self;
    my $prevmp = $mp->{ prev };
    my $nextmp = $mp->{ next };
    my $data_type = $mp->data_type();

    return if($data_type eq "text/rfc822-headers");

    _prev_message_is($nextmp,$prevmp);
    _next_message_is($prevmp,$nextmp);
}


# Descriptions: search the next MIME boundary
#    Arguments: OBJ($self) HASH_STR($data) STR($delimeter)
# Side Effects: none
# Return Value: (NUM, NUM)
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
    print "\t_next_part_pos( p=$p pp=$pp maxlen=$maxlen )\n" if $debug;

    $len = $p > 0 ? ($p - $pp) : ($maxlen - $pp);
    $pb  = $pp + length($delimeter);
    $pe  = $pb + $len - length($delimeter);

    # but broken if $p == $pp == 0 !!!
    if ($pp == 0) { $pb = $pe = $maxlen;}

    print "\t_next_part_pos(* len=$len, $pb, $pe)\n" if $debug && ($p<=0);
    return ($pb, $pe);
}


# Descriptions: get the current position
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub _get_pos
{
    my ($self) = @_;
    defined $self->{ _current_pos } ? $self->{ _current_pos } : 0;
}


# Descriptions: set the postion
#    Arguments: OBJ($self) NUM($pos)
# Side Effects: update object
# Return Value: NUM
sub _set_pos
{
    my ($self, $pos) = @_;
    $self->{ _current_pos } = $pos;
}


=head1 METHODS (UTILITY FUNCTIONS)

=head2 size()

return the message size of this object.

=head2 is_empty()

return this message has empty content or not.

=cut


my $total = 0;

# Descriptions: return the message size of this object
#               XXX not size for the whole message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub size
{
    my ($self) = @_;
    my $rc = $self->{ data } || undef;
    my $pb = $self->{ offset_begin };
    my $pe = $self->{ offset_end };

    # fundamental check
    unless (defined($rc) && ref($rc) eq 'SCALAR') {
	# XXX simple check (needed ?)
	# confess("Mail::Message->size() is given invalid object ($self)\n");
	return 0;
    }

    if ((defined $pe) && (defined $pb)) {
	if ($pe - $pb > 0) {
	    $total += ($pe - $pb);
	    return ($pe - $pb);
	}
    }
    else {
	length($$rc);
    }
}


# Descriptions: content of this object is empty ?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
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


=head2 encoding_mechanism()

return encoding type for specified Mail::Message not whole mail.
The return value is one of base64, quoted-printable or undef.

=cut


# Descriptions: return encoding type for specified Mail::Message not
#               whole mail.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub encoding_mechanism
{
    my ($self) = @_;
    my $buf = $self->message_fields();

    if (defined($buf) &&
	($buf =~ /Content-Transfer-Encoding:\s*(\S+)/mi)) {
	my $mechanism = $1;
	$mechanism =~ tr/A-Z/a-z/;
	return $mechanism;
    }
    else {
	return undef;
    }
}


=head2 offset_pair()

return offset information in the data.
return value is ARRAY

   ($offset_begin, $offset_end)

on the Mail::Message object.

=cut


# Descriptions: return offset information in the data.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub offset_pair
{
    my ($self) = @_;
    return( $self->{ offset_begin }, $self->{ offset_end });
}


=head2 header_size()

get whole header size for this object ($self)

=head2 body_size()

get whole body size for this object ($self)

=cut


# Descriptions: get whole header size for this object ($self)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub whole_message_header_size
{
    my ($self) = @_;
    $self->{ data_info }->{ header_size };
}


# Descriptions: get whole body size for this object ($self)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub whole_message_body_size
{
    my ($self) = @_;
    $self->{ data_info }->{ body_size };
}


=head2 envelope_sender()

return reverse_path for this object ($self)

=cut


# Descriptions: return reverse_path for this object ($self)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub envelope_sender
{
    my ($self) = @_;
    $self->{ data_info }->{ envelope_sender };
}


=head2 data_type()

return the data type of the given message object ($self) not the whole
mail message.

=cut


# Descriptions: return the data type.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub data_type
{
    my ($self) = @_;
    my $type = $self->{ data_type };
    $type =~ s/;//;
    $type =~ tr/A-Z/a-z/;
    $type;
}


=head2 num_paragraph()

return the number of paragraphs in the message ($self).

=head2 nth_paragraph($n)

return the string of C<$n>-th paragraph.
For example, C<nth_paragraph(1)> returns the 1st paragraph.
The syntax is usual not C language flabour.

=cut


# Descriptions: return number of paragraphs in this object
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub num_paragraph
{
    my ($self) = @_;

    # exit ASAP if the message is empty.
    return 0 if $self->is_empty();

    my $pmap = $self->_evaluate_pmap();

    # number of paratrah == the max element
    $#$pmap;
}


# Descriptions: return content in $i-th paragraph in this object
#    Arguments: OBJ($self) NUM($i)
# Side Effects: none
# Return Value: STR
sub nth_paragraph
{
    my ($self, $i) = @_;
    my $data = $self->{ data };
    my $pmap = $self->_evaluate_pmap();

    if (defined($$data) && $$data) {
	$i--; # shift $i: 1 => 0, 2 =>1, et. al.
	my ($pb, $pe) = ($pmap->[ $i ], $pmap->[ $i + 1 ]);
	return substr($$data, $pb, $pe - $pb);
    }
    else {
	return undef;
    }
}


# Descriptions: analyze paragraph position map in this object
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub _evaluate_pmap
{
    my ($self) = @_;

    my $pb      = $self->{ offset_begin };
    my $pe      = $self->{ offset_end };
    my $bodylen = $self->size;
    my $data    = $self->{ data };

    unless (defined $data) {
	return [];
    }

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

    return \@pmap;
}


=head2 message_fields()

return header string in the message content.
It is mie header for whole mail or each message of MIME/multipart.

=head2 message_text($size)

get body string in the message content, which is the whole mail (plain
text) or body part of a block of multipart.

If C<$size> is specified, return the first $size bytes in the body.

=cut


# Descriptions: return header in the message content.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub message_fields
{
    my ($self) = @_;
    return defined $self->{ header } ? $self->{ header } : undef;
}


# Descriptions: get body string in message
#    Arguments: OBJ($self) NUM($size)
# Side Effects: none
# Return Value: STR
sub message_text
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

    if (defined $size) {
	return substr($$data, $pos_begin, $size);
    }
    else {
	return substr($$data, $pos_begin, $msglen);
    }
}


=head2 find_first_plaintext_message($args)

return the Messages object for the first "plain/text" message in a
chain. For example,

         $m    = $msg->find_first_plaintext_message();
         $body = $m->message_text();

where $body is the mail body (string).

=cut


# Descriptions: get first text/plain OBJ, return undef if search fails.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ or UNDEF
sub find_first_plaintext_message
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
	my $type = $mp->data_type;

	if ($type eq 'text/plain') {
	    return $mp;
	}
    }

    return undef;
}


=head2 set_log_function()

internal use. set CODE REFERENCE to the log function

=cut


# Descriptions: set log function pointer (CODE REFERNCE)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: set log function pointer to $self object
# Return Value: REF_CODE
sub set_log_function
{
    my ($self, $fp) = @_;
    $self->{ _log_function } = $fp;
}


=head2 data_type_list()

show the list of data_types in the chain order.
This is defined for debug and removed in the future.

=cut


# Descriptions: XXX debug, remove this in the future
#    Arguments: OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: REF_ARRAY
sub data_type_list
{
    my ($msg, $args) = @_;
    my ($m, @buf, $i);
    my $debug = defined $args->{ debug } ? 1 : 0;

    for ($i = 0, $m = $msg; defined $m ; $m = $m->{ 'next' }) {
	$i++;
	my $data = $m->{'data'};
	if ($debug) {
	    push(@buf, sprintf("type[%2d]: %-25s | %s",
			       $i, $m->{'data_type'}, $m->{'base_data_type'}));
	}
	else {
	    push(@buf, $m->{'data_type'});
	}
    }
    \@buf;
}


=head1 METHODS to make a whole mail message

Please use C<Mail::Message::Compose> class.
This is an adapter for C<MIME::Lite>, so
your request is forwarded to C<MIME::Lite> class :-)

    use Mail::Message::Compose;
    $msg = Mail::Message::Compose->new(
       From     => 'fukachan@fml.org',
       To       => 'rudo@nuinui.net',
       Cc       => 'kenken@nuinui.net',
       Subject  => 'help',
       Type     => 'text/plain',
       Path     => 'help',
    );
    $msg->attr('content-type.charset' => 'us-ascii');

    # show message;
    print $msg->as_string;


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

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
