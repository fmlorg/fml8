#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Header.pm,v 1.63 2003/08/23 14:37:58 fukachan Exp $
#

package FML::Header;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

use Mail::Header;
@ISA = qw(Mail::Header);

my $debug = 0;

=head1 NAME

FML::Header - header manipulators

=head1 SYNOPSIS

    $header = use FML::Header \@header;
    $header->add('X-ML-Info', "mailing list name");
    $header->delete('Return-Receipt-To');
    $header->replace(field, value);

=head1 DESCRIPTION

C<FML::Header> is an adapter for C<Mail::Header> class (See C<CPAN>
for more details). C<Mail::Header> is the base class.

=head1 METHODS

Methods defined in C<Mail::Header> are available.
For example,
C<modify()>, C<mail_from()>, C<fold()>, C<extract()>, C<read()>,
C<empty()>, C<header()>, C<header_hashref()>, C<add()>, C<replace()>,
C<combine()>, C<get()>, C<delete()>, C<count()>, C<print()>,
C<as_string()>, C<fold_length()>, C<tags()>, C<dup()>, C<cleanup()>,
C<unfold()>.

CAUTION: Pay attention!
C<FML::Header> overloads C<get()> to remove the trailing "\n".

=cut

#
# XXX-TODO: need to implement copy() and move() ?
#

=head2 new()

forward the request up to superclass C<Mail::header::new()>.

=cut


# Descriptions: forward new() request to the base class
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;

    # an adapter for Mail::Header::new()
    $self->SUPER::new($args);
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


=head2 get($key)

return the value of C<Mail::Header::get($key)> but without the trailing
"\n".

=head2 set($key, $value)

alias of C<Mail::Header::set($key, $value)>.

=cut


# Descriptions: get() wrapper to remove \n$
#    Arguments: OBJ($self) ARRAY(@x)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, @x) = @_;
    my $x = $self->SUPER::get(@x) || '';

    $x =~ s/\n$//;

    return $x;
}


# Descriptions: set() wrapper
#    Arguments: OBJ($self) ARRAY(@x)
# Side Effects: none
# Return Value: none
sub set
{
    my ($self, @x) = @_;
    $self->SUPER::set(@x);
}


=head2 address_clean_up(address)

clean up given C<address>. This method parses the given address by
C<Mail::Address::parse()>, remove < and > and return the result.

=cut

#
# XXX-TODO: address_clean_up() in this class is apporopriate ?
# XXX-TODO: is it in some other class such as FML::Address ?
#

# Descriptions: utility to remove ^\s*< and >\s*$
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub address_clean_up
{
    my ($self, $addr) = @_;

    use Mail::Address;
    my (@addrlist) = Mail::Address->parse($addr);

    # only the first element in the @addrlist array is effective.
    if (defined $addrlist[0]) {
	$addr = $addrlist[0]->address;
	$addr =~ s/^\s*<//;
	$addr =~ s/>\s*$//;

	# return the result.
	return $addr;
    }
    else {
	return undef;
    }
}


=head2 data_type()

return the C<type> defind in the header's Content-Type field.
For example, C<text/plain>, C<mime/multipart> and et. al.

=cut


# Descriptions: return the type defind in the header's Content-Type field.
#    Arguments: OBJ($header)
# Side Effects: extra spaces in the type to return is removed.
# Return Value: STR or UNDEF
sub data_type
{
    my ($header) = @_;
    my $content_type = $header->get('content-type');

    if (defined $content_type) {
	my ($type) = split(/;/, $content_type);
	if (defined $type) {
	    $type =~ s/\s*//g;
	    return $type;
	}
    }

    return undef;
}



###
### FML specific functions
###

=head1 FML SPECIFIC METHODS

=head2 add_fml_ml_name($config, $args)

add X-ML-Name:

=head2 add_fml_traditional_article_id($config, $args)

add X-Mail-Count:

=head2 add_fml_article_id($config, $args)

add X-ML-Count:

=cut

#
# XXX-TODO: "x-ml-name: unknown" or "x-ml-name: " if $config is undefined?
# XXX-TODO: which is better if we follow Principle of Least Surprise ?
#


# Descriptions: add "X-ML-Name: elena" to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_fml_ml_name
{
    my ($header, $config, $args) = @_;
    $header->add('X-ML-Name', $config->{ x_ml_name });
}


# Descriptions: add "X-Mail-Count: NUM" to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_fml_traditional_article_id
{
    my ($header, $config, $args) = @_;
    $header->add('X-Mail-Count', $args->{ id });
}


# Descriptions: add "X-ML-Count: NUM" to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_fml_article_id
{
    my ($header, $config, $args) = @_;
    $header->add('X-ML-Count', $args->{ id });
}


=head2 add_software_info($config, $args)

add X-MLServer: and List-Software:.

C<MIME::Lite> object as a $args->{ message } can be handled
when $args->{type} is 'MIME::Lite'.

=head2 add_rfc2369($config, $args)

add List-* sereies defined in RFC2369 and RFC2919.

C<MIME::Lite> object as a $args->{ message } can be handled
when $args->{type} is 'MIME::Lite'.

=head2 add_x_sequence($config, $args)

add X-Sequence.

=head2 add_message_id($config, $args)

add Message-Id.

=cut


# Descriptions: add "X-ML-Server: fml .." and "List-Software: fml .." to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_software_info
{
    my ($header, $config, $args) = @_;
    my $fml_version = $config->{ fml_version };
    my $object_type = defined $args->{ type } ? $args->{ type } : '';

    if ($fml_version) {
	if ($object_type eq 'MIME::Lite') {
	    my $msg = $args->{ message };
	    $msg->attr('X-MLServer'    => $fml_version);
	    $msg->attr('List-Software' => $fml_version);
	}
	else {
	    $header->add('X-MLServer',    $fml_version);
	    $header->add('List-Software', $fml_version);
	}
    }
}


# Descriptions: add List-* to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_rfc2369
{
    my ($header, $config, $args) = @_;
    my $object_type = defined $args->{ type } ? $args->{ type } : '';

    # addresses
    my $post       = $config->{ address_for_post };
    my $command    = $config->{ address_for_command };
    my $maintainer = $config->{ maintainer };
    my $use_command_mail_program = $config->yes('use_command_mail_program');

    # information for list-id
    my $ml_name = $config->{ ml_name };
    my $id      = "$ml_name mailing list <$post>"; $id =~ s/\@/./g;

    # See RFC2369 for more details
    if ($object_type eq 'MIME::Lite') {
	my $msg = $args->{ message };
	$msg->attr('List-ID'    => $id) if $id;
	$msg->attr('List-Post'  => "<mailto:${post}>") if $post;
	$msg->attr('List-Owner' => "<mailto:${maintainer}>") if $maintainer;
	if ($command && $use_command_mail_program) {
	    $msg->attr('List-Help' =>  "<mailto:${command}?body=help>");
	    $msg->attr('List-Subscribe' =>
		       "<mailto:${command}?body=subscribe>");
	    $msg->attr('List-UnSubscribe' =>
		       "<mailto:${command}?body=unsubscribe>");
	}
    }
    else {
	$header->add('List-ID',    $id) if $id;
	$header->add('List-Post',  "<mailto:${post}>")       if $post;
	$header->add('List-Owner', "<mailto:${maintainer}>") if $maintainer;

	if ($command && $use_command_mail_program) {
	    $header->add('List-Help', "<mailto:${command}?body=help>");
	    $header->add('List-Subscribe',
			 "<mailto:${command}?body=subscribe>");
	    $header->add('List-UnSubscribe',
			 "<mailto:${command}?body=unsubscribe>");
	}
    }
}

# Descriptions: add "Message-ID if not define
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_message_id
{
    my ($header, $config, $args) = @_;
    my $object_type = defined $args->{ type } ? $args->{ type } : '';

    use FML::Header::MessageID;
    my $mid = FML::Header::MessageID->new->gen_id($config,$args);

    if ($object_type eq 'MIME::Lite') {
	my $msg = $args->{ message };
	$msg->attr('Message-Id' => $mid);
    }
    else {
	$header->add('Message-Id', $mid);
    }
}


# Descriptions: add "X-Sequence: elena NUM" to header
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub add_x_sequence
{
    my ($header, $config, $args) = @_;

    $header->add('X-Sequence',  "$config->{ x_ml_name } $args->{ id }");
}


=head2 rewrite_article_subject_tag($config, $args)

add subject tag like [elena:00010].
The actual function definitions exist in C<FML::Header::Subject>.

=head2 rewrite_reply_to

replace C<Reply-To:> with this ML's address for post.
add reply-to: if not specified.


=head2 rewrite_errors_to

replace C<Errors-To:> with this ML's address for post.
add errors-to: if not specified.

=head2 rewrite_date

replace original C<Date:> to C<X-Date:>.
and now fml process time add to C<Date:>.

=head2 rewrite_received

replace original C<Received:> to C<X-Received:>.

=cut


# Descriptions: rewrite subject if needed
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub rewrite_article_subject_tag
{
    my ($header, $config, $args) = @_;

    my $pkg = "FML::Header::Subject";
    eval qq{ use $pkg;};
    unless ($@) {
	$pkg->rewrite_article_subject_tag($header, $config, $args);
    }
    else {
	croak("cannot load $pkg");
    }
}


# Descriptions: rewrite Reply-To: to this ML's address.
#               add Reply-To: if not specified.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub rewrite_reply_to
{
    my ($header, $config, $args) = @_;
    my $reply_to = $header->get('reply-to') || '';

    unless ($reply_to) {
	$header->add('Reply-To', $config->{ address_for_post });
    }
}


# Descriptions: rewrite Errors-To: to the maintainer.
#               add Errors-To: if not specified.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub rewrite_errors_to
{
    my ($header, $config, $args) = @_;
    $header->add('Errors-To', $config->{ maintainer });
}


# Descriptions: rewrite Date: to X-Date: if needed
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub rewrite_date
{
    my ($header, $config, $args) = @_;
    my $orgdate = $header->get('date') || '';

    use Mail::Message::Date;
    my $nowdate = new Mail::Message::Date time;
    my $newdate = $nowdate->{ mail_header_style };

    $header->add('X-Date', $orgdate) if ($orgdate);
    $header->replace('Date', $newdate);
}


# Descriptions: rewrite Received: to X-Received: if needed
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub rewrite_received
{
    my ($header, $config, $args) = @_;
    my($i,$data);
    my $org = "Received";
    my $new = "X-Received";
    my $num = $header->count($org);

    for ($i = 0; $i < $num; $i++) {
	$data = $header->get($org, $i);
	$header->add($new, $data);
    }
    $header->delete($org);
}


=head2 delete_unsafe_header_fields($config, $args)

remove header fields defiend in C<$unsafe_header_fields>.
C<$unsafe_header_fields> is a list of keys.
The keys are space separeted.

   unsafe_header_fields		=	Return-Receipt-To

=cut


# Descriptions: remove some header fields defined in $config
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update $header
# Return Value: none
sub delete_unsafe_header_fields
{
    my ($header, $config, $args) = @_;
    my ($fields) = $config->get_as_array_ref('unsafe_header_fields');

    for my $field (@$fields) { $header->delete($field);}
}


=head1 MISCELLANEOUS UTILITIES

=head2 delete_subject_tag_like_string($string)

remove subject tag like the string given as C<$string>.

=head2 extract_message_id_references()

return message-id list (ARRAY REFERENCE) extracted from the header
(C<$self>).  It extracts message-id(s) from In-Reply-To: and
References: fields.

=cut


# Descriptions: remove tag like string in $str
#    Arguments: OBJ($header) STR($str)
# Side Effects: none
# Return Value: STR
sub delete_subject_tag_like_string
{
    my ($header, $str) = @_;

    $str =~ s/\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;

    return $str;
}


# Descriptions: extract Message-ID:'s in $header from
#               In-Reply-To: and References: fields.
#    Arguments: OBJ($header)
# Side Effects: none
# Return Value: ARRAY_REF
sub extract_message_id_references
{
    my ($header) = @_;
    my $buf =
	$header->get('in-reply-to') ."\n". $header->get('references');

    use Mail::Address;
    my @addrs = Mail::Address->parse($buf);

    my @r    = ();
    my %uniq = ();
    foreach my $addr (@addrs) {
	my $a = $addr->address;
	unless (defined($uniq{ $a }) && $uniq{ $a }) {
	    push(@r, $addr->address);
	    $uniq{ $a } = 1;
	}
    }

    return \@r;
}


=head1 FILTERING FUNCTIONS

=head2 check_message_id($config, $args)

check whether message-id is unique or not. If the message-id is found
in the past message-id cache, the injected message must causes a mail
loop.

=head2 check_x_ml_info($config, $args)

The injected message loops if x-ml-info: has our own
C<address_for_post> address.

=head2 check_list_post($config, $args)

The injected message loops if list-post: has our own
C<address_for_post> address.

=cut


# Descriptions: check whether message-id is duplicated or not
#                against mail loop.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: update cache
# Return Value: STR or 0
sub check_message_id
{
    my ($header, $config, $args) = @_;
    my $dir = $config->{ 'message_id_cache_dir' },
    my $mid = $header->get('message-id');
    my $dup = 0;

    $mid = $header->address_clean_up($mid);
    if ($mid) {
	use FML::Header::MessageID;
	my $xargs = { directory => $dir };
	my $db    = FML::Header::MessageID->new->db_open($xargs);

	if (defined $db) {
	    # we can tind the $mid in the past message-id cache ?
	    $dup = $db->{ $mid };
	    Log( "message-id duplicated" ) if $dup;

	    # save the current id
	    $db->{ $mid } = 1;
	}
    }

    return $dup;
}


# Descriptions: check X-ML-Info: duplication against mail loop
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub check_x_ml_info
{
    my ($header, $config, $args) = @_;
    my $buf  = $header->get('x-ml-info')  || undef;
    my $addr = $config->{ addr_for_post } || undef;

    if ($addr && $buf) {
	return ($buf =~ /$addr/) ? 1 : 0;
    }
    else {
	0;
    }
}


# Descriptions: check mail loop by List-Post: field
#    Arguments: OBJ($header) OBJ($config) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub check_list_post
{
    my ($header, $config, $args) = @_;
    my $buf  = $header->get('list-post')  || undef;
    my $addr = $config->{ addr_for_post } || undef;

    if ($addr && $buf) {
	return ($buf =~ /$addr/) ? 1 : 0;
    }
    else {
	0;
    }

    0;
}


=head1 SEE ALSO

L<Mail::Header>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Header first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
