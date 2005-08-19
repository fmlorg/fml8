#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Header.pm,v 1.84 2005/08/08 03:53:23 fukachan Exp $
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

FML::Header - header manipulators.

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


# Descriptions: forward new() request to the base class.
#    Arguments: OBJ($self) HASH_REF($rw_args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $rw_args) = @_;

    # an adapter for Mail::Header::new()
    $self->SUPER::new($rw_args);
}


# Descriptions: dummy.
#    Arguments: OBJ($self) HASH_REF($rw_args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


=head2 get($key)

return the value of C<Mail::Header::get($key)> but without the trailing
"\n".

=head2 set($key, $value)

alias of C<Mail::Header::set($key, $value)>.

=cut


# Descriptions: get() wrapper to remove \n$.
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


# Descriptions: set() wrapper.
#    Arguments: OBJ($self) ARRAY(@x)
# Side Effects: none
# Return Value: none
sub set
{
    my ($self, @x) = @_;
    $self->SUPER::set(@x);
}


=head2 address_cleanup(address)

clean up given C<address>. This method parses the given address by
C<Mail::Address::parse()>, remove < and > and return the result.

=cut


#
# XXX-TODO: address_cleanup() in this class is apporopriate ?
# XXX-TODO: is it in some other class such as FML::Address ?
#

# Descriptions: utility to remove ^\s*< and >\s*$ strings.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub address_cleanup
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

return the C<type> defined in the header's Content-Type field.
For example, C<text/plain>, C<mime/multipart> and et. al.

=cut


# Descriptions: return the type defind in the header's Content-Type field.
#    Arguments: OBJ($header)
# Side Effects: extra spaces in the type to return is removed.
# Return Value: STR or UNDEF
sub data_type
{
    my ($header)     = @_;
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

=head2 add_fml_ml_name($config, $rw_args)

add X-ML-Name: field.

=head2 add_fml_traditional_article_id($config, $rw_args)

add X-Mail-Count: field.

=head2 add_fml_article_id($config, $rw_args)

add X-ML-Count: field.

=cut


#
# XXX-TODO: "x-ml-name: unknown" or "x-ml-name: " if $config is undefined?
# XXX-TODO: which is better if we follow Principle of Least Surprise ?
#


# Descriptions: add "X-ML-Name: elena" to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_fml_ml_name
{
    my ($header, $config, $rw_args) = @_;
    $header->add('X-ML-Name', $config->{ outgoing_mail_header_x_ml_name });
}


# Descriptions: add "X-Mail-Count: NUM" to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_fml_traditional_article_id
{
    my ($header, $config, $rw_args) = @_;
    $header->add('X-Mail-Count', $rw_args->{ id });
}


# Descriptions: add "X-ML-Count: NUM" to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_fml_article_id
{
    my ($header, $config, $rw_args) = @_;
    $header->add('X-ML-Count', $rw_args->{ id });
}


=head2 add_software_info($config, $rw_args)

add X-MLServer: and List-Software: field.

C<MIME::Lite> object as a $rw_args->{ message } can be handled
when $rw_args->{type} is 'MIME::Lite'.

=head2 add_rfc2369($config, $rw_args)

add List-* series defined in RFC2369 and RFC2919.

C<MIME::Lite> object as a $rw_args->{ message } can be handled
when $rw_args->{type} is 'MIME::Lite'.

=head2 add_x_sequence($config, $rw_args)

add X-Sequence field.

=head2 add_message_id($config, $rw_args)

add Message-Id field.

=cut


# Descriptions: add "X-ML-Server: fml .." and "List-Software: fml .."
#               to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_software_info
{
    my ($header, $config, $rw_args) = @_;
    my $fml_version = $config->{ fml_version } || '';
    my $object_type = defined $rw_args->{ type } ? $rw_args->{ type } : '';

    if ($fml_version) {
	if ($object_type eq 'MIME::Lite') {
	    my $msg = $rw_args->{ message };
	    $msg->attr('X-MLServer'    => $fml_version);
	    $msg->attr('List-Software' => $fml_version);
	}
	else {
	    $header->add('X-MLServer',    $fml_version);
	    $header->add('List-Software', $fml_version);
	}
    }
}


# Descriptions: add List-* to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_rfc2369
{
    my ($header, $config, $rw_args) = @_;
    my $object_type = defined $rw_args->{ type } ? $rw_args->{ type } : '';

    # addresses
    my $use_command_mail_function = $config->yes('use_command_mail_function');
    my $command      = $config->{ command_mail_address } || '';
    my $use_command  = 0;
    if ($command && $use_command_mail_function) {
	$use_command = 1;
    }

    # information for list-*
    my $ml_name     = $config->{ ml_name };
    my $maintainer  = $config->{ maintainer } || '';
    my $default     =
	$maintainer ? "contact maintainer <$maintainer>" : 'unavailable';
    my $post        = $config->{ article_post_address } || '';
    my $base_url    = "mailto:${command}?body=";
    my $list_id     = "$ml_name mailing list <$post>"; $list_id =~ s/\@/./g;
    my $list_owner  = $maintainer ? "<mailto:${maintainer}>" : 'maintainer';
    my $list_post   = $post ? "<mailto:${post}>" : 'unavailable';
    my $list_help   = $use_command ? "<${base_url}help>"        : $default;
    my $list_subs   = $use_command ? "<${base_url}subscribe>"   : $default;
    my $list_unsub  = $use_command ? "<${base_url}unsubscribe>" : $default;

    # See RFC2369 for more details
    if ($object_type eq 'MIME::Lite') {
	my $msg = $rw_args->{ message };
	$msg->attr('List-ID'          => $list_id);
	$msg->attr('List-Owner'       => $list_owner);
	$msg->attr('List-Post'        => $list_post);
	$msg->attr('List-Help'        => $list_help);
	$msg->attr('List-Subscribe'   => $list_subs);
	$msg->attr('List-UnSubscribe' => $list_unsub);
    }
    else {
	$header->add('List-ID',          $list_id);
	$header->add('List-Owner',       $list_owner);
	$header->add('List-Post',        $list_post);
	$header->add('List-Help',        $list_help);
	$header->add('List-Subscribe',   $list_subs);
	$header->add('List-UnSubscribe', $list_unsub);
    }
}

# Descriptions: add "Message-ID if not defined.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_message_id
{
    my ($header, $config, $rw_args) = @_;
    my $object_type = defined $rw_args->{ type } ? $rw_args->{ type } : '';

    use FML::Header::MessageID;
    my $mid = FML::Header::MessageID->new->gen_id($config);

    if ($object_type eq 'MIME::Lite') {
	my $msg = $rw_args->{ message };
	$msg->attr('Message-Id' => $mid);
    }
    else {
	$header->add('Message-Id', $mid);
    }
}


# Descriptions: add "X-Sequence: elena NUM" to header.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub add_x_sequence
{
    my ($header, $config, $rw_args) = @_;
    my $name = $config->{ outgoing_mail_header_x_ml_name };
    my $id   = $rw_args->{ id };
    my $seq  = sprintf("%s %s", $name, $id);

    $header->add('X-Sequence', $seq);
}


=head2 rewrite_article_subject_tag($config, $rw_args)

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


# Descriptions: rewrite subject if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_article_subject_tag
{
    my ($header, $config, $rw_args) = @_;
    my $tag = $config->{ article_subject_tag };

    # for example, ml_name = elena
    # if $tag has special regexp such as \U$ml_name\E or \L$ml_name\E
    if (defined $tag) {
	if ($tag =~ /\\E/o && $tag =~ /\\U|\\L/o) {
	    eval qq{ \$tag = "$tag";};
	    Log($@) if $@;
	}
    }

    # XXX-TODO: $article_subject_tag e.g. "\Lmlname\E" is expanded already.
    # XXX-TODO: we should include this exapansion method within this module?
    use Mail::Message::Subject;
    my $str = $header->get('subject');
    my $sbj = new Mail::Message::Subject $str;

    # mime decode
    $sbj->mime_decode();

    # de-tag and cut off Re: Re: Re: ... (duplicated reply tag).
    $sbj->delete_dup_reply_tag() if $sbj->has_reply_tag();
    $sbj->delete_tag($tag);
    $sbj->delete_dup_reply_tag() if $sbj->has_reply_tag();

    # add(prepend) the rewrited tag with mime encoding.
    my $new_tag = sprintf($tag, $rw_args->{ id });
    my $new_sbj = sprintf("%s %s", $new_tag, $sbj->as_str());

    # update object.
    $sbj->set($new_sbj);

    # mime encode and replace subject field.
    $sbj->mime_encode();
    $header->replace('Subject', $sbj->as_str());
}


# Descriptions: rewrite subject if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_article_subject_tag_orig
{
    my ($header, $config, $rw_args) = @_;

    my $pkg = "FML::Header::Subject";
    eval qq{ use $pkg;};
    unless ($@) {
	$pkg->rewrite_article_subject_tag($header, $config, $rw_args);
    }
    else {
	croak("cannot load $pkg");
    }
}


# Descriptions: rewrite Reply-To: to this ML's address.
#               add Reply-To: if not specified.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_reply_to
{
    my ($header, $config, $rw_args) = @_;
    my $reply_to = $header->get('reply-to') || '';

    unless ($reply_to) {
	$header->add('Reply-To', $config->{ article_post_address });
    }
}


# Descriptions: rewrite Errors-To: to the maintainer.
#               add Errors-To: if not specified.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_errors_to
{
    my ($header, $config, $rw_args) = @_;
    my $value = $config->{ outgoing_mail_header_errors_to };
 
    $header->add('Errors-To', $value);
}


# Descriptions: rewrite Date: to X-Date: if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_date
{
    my ($header, $config, $rw_args) = @_;
    my $orgdate = $header->get('date') || '';

    use Mail::Message::Date;
    my $nowdate = new Mail::Message::Date time;
    my $newdate = $nowdate->{ mail_header_style };

    $header->add('X-Date', $orgdate) if ($orgdate);
    $header->replace('Date', $newdate);
}


# Descriptions: add/rewrite startrek stardate if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_stardate
{
    my ($header, $config, $rw_args) = @_;

    use Mail::Message::Date;
    my $nowdate  = new Mail::Message::Date time;
    my $stardate = $nowdate->stardate();
    if ($header->get('X-Stardate')) {
	$header->replace('X-Stardate', $stardate);
    }
    else {
	$header->add('X-Stardate', $stardate);
    }
}


# Descriptions: add/rewrite Precedence: field if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_precedence
{
    my ($header, $config, $rw_args) = @_;
    my $precedence = $config->{ outgoing_mail_header_precedence } || 'bulk';

    if ($header->get('Precedence')) {
	$header->replace('Precedence', $precedence);
    }
    else {
	$header->add('Precedence', $precedence);
    }
}


# Descriptions: rewrite Received: to X-Received: if needed.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub rewrite_received
{
    my ($header, $config, $rw_args) = @_;
    my $org = "Received";
    my $new = "X-Received";
    my $num = $header->count($org);
    my ($i, $data);

    for ($i = 0; $i < $num; $i++) {
	$data = $header->get($org, $i);
	$header->add($new, $data);
    }
    $header->delete($org);
}


=head2 delete_unsafe_header_fields($config, $rw_args)

remove header fields defiend in C<$unsafe_header_fields>.
C<$unsafe_header_fields> is a list of keys.
The keys are space separeted.

   unsafe_header_fields		=	Return-Receipt-To

=cut


# Descriptions: remove some header fields defined in $config.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update $header
# Return Value: none
sub delete_unsafe_header_fields
{
    my ($header, $config, $rw_args) = @_;
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


# Descriptions: remove tag like string in $str.
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
    my $buf0 = $header->get('in-reply-to') || '';
    my $buf1 = $header->get('references')  || ''; $buf1 =~ s/\s+/,/g;
    my $buf  = join(",", $buf0, $buf1);

    use Mail::Address;
    my @addrs = Mail::Address->parse($buf);

    my @r    = ();
    my %uniq = ();
    foreach my $addr (@addrs) {
	if (defined $addr) {
	    my $a = $addr->address;
	    unless (defined($uniq{ $a }) && $uniq{ $a }) {
		push(@r, $addr->address);
		$uniq{ $a } = 1;
	    }
	}
    }

    return \@r;
}


=head1 FILTERING FUNCTIONS

=head2 check_message_id($config, $rw_args)

check whether message-id is unique or not. If the message-id is found
in the past message-id cache, the injected message must causes a mail
loop.

=cut


# Descriptions: check whether message-id is duplicated or not
#               against mail loop.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update cache
# Return Value: STR or 0
sub check_message_id
{
    my ($header, $config, $rw_args) = @_;
    my $mode = 'message_id_cache_dir';
    my $mid  = $header->get('message-id');
    $header->_check_xxx_message_id($config, $mode, $mid);
}


# Descriptions: find message-id in article database.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update cache
# Return Value: STR or 0
sub check_article_message_id
{
    my ($header, $config, $rw_args) = @_;
    my $mode = 'article_message_id_cache_dir';
    my $mid  = $rw_args->{ message_id } || '';
    if ($mid) {
	$header->_check_xxx_message_id($config, $mode, $mid);
    }
}


# Descriptions: check whether message-id is duplicated or not
#               against mail loop.
#    Arguments: OBJ($header) OBJ($config) STR($mode) STR($mid)
# Side Effects: update cache
# Return Value: STR or 0
sub _check_xxx_message_id
{
    my ($header, $config, $mode, $mid) = @_;
    my $dir = $config->{ $mode };
    my $dup = 0;

    $mid = $header->address_cleanup($mid);
    if ($mid) {
	use FML::Header::MessageID;
	my $xargs = { directory => $dir };
	my $db    = FML::Header::MessageID->new->db_open($xargs);

	if (defined $db) {
	    # we can find the $mid in the past message-id cache ?
	    $dup = $db->{ $mid };
	    if ($dup && $mode eq 'message_id_cache_dir') {
		Log( "message-id duplicated" );
	    }
	}
    }

    return $dup;
}


# Descriptions: store message-id into the cache.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update cache
# Return Value: STR or 0
sub update_message_id_cache
{
    my ($header, $config, $rw_args) = @_;
    my $mode = 'message_id_cache_dir';
    $header->_update_xxx_message_id_cache($mode, $config, $rw_args);
}


# Descriptions: store article message-id into the cache.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: update cache
# Return Value: STR or 0
sub update_article_message_id_cache
{
    my ($header, $config, $rw_args) = @_;
    my $mode = 'article_message_id_cache_dir';
    $header->_update_xxx_message_id_cache($mode, $config, $rw_args);
}


# Descriptions: store article message-id into the cache.
#    Arguments: OBJ($header) STR($mode) OBJ($config) HASH_REF($rw_args)
# Side Effects: update cache
# Return Value: STR or 0
sub _update_xxx_message_id_cache
{
    my ($header, $mode, $config, $rw_args) = @_;
    my $dir = $config->{ $mode };
    my $mid = $header->get('message-id');

    $mid = $header->address_cleanup($mid);
    if ($mid) {
	use FML::Header::MessageID;
	my $xargs = { directory => $dir };
	my $db    = FML::Header::MessageID->new->db_open($xargs);

	if (defined $db) {
	    # save the current id and time (unix time).
	    $db->{ $mid } = time;
	}
    }
}


=head2 check_x_ml_info($config, $rw_args)

The injected message loops if x-ml-info: has our own
C<article_post_address> address.

=head2 check_list_post($config, $rw_args)

The injected message loops if list-post: has our own
C<article_post_address> address.

=cut


# Descriptions: check X-ML-Info: duplication against mail loop.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: none
# Return Value: 1 or 0
sub check_x_ml_info
{
    my ($header, $config, $rw_args) = @_;
    my $buf  = $header->get('x-ml-info') || undef;
    my $addr = $config->{ article_post_address } || undef;

    if ($addr && $buf) {
	return ($buf =~ /$addr/) ? 1 : 0;
    }
    else {
	return 0;
    }
}


# Descriptions: check mail loop by List-Post: field.
#    Arguments: OBJ($header) OBJ($config) HASH_REF($rw_args)
# Side Effects: none
# Return Value: 1 or 0
sub check_list_post
{
    my ($header, $config, $rw_args) = @_;
    my $buf  = $header->get('list-post') || undef;
    my $addr = $config->{ article_post_address } || undef;

    if ($addr && $buf) {
	return ($buf =~ /$addr/) ? 1 : 0;
    }
    else {
	return 0;
    }

    return 0;
}


=head1 SEE ALSO

L<Mail::Header>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Header first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
