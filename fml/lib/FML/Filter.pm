#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Filter.pm,v 1.20 2003/02/18 15:55:33 fukachan Exp $
#

package FML::Filter;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter - entry point for FML::Filter::* modules

=head1 SYNOPSIS

    ... under reconstruction now. synopsis disabled once ...

where C<$message> is C<Mail::Message> object.

=head1 DESCRIPTION

top level dispatcher for FML filtering engine.
It consists of two types, header and body filtering engines.
The detail of rules is found in
L<FML::Filter::Header>,
L<FML::Filter::TextPlain>,
and
L<FML::Filter::MimeComponent>.

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: entry point for FML::Filter::* modules
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: STR or UNDEF, error reason (string). return undef if ok.
sub article_filter
{
    my ($self, $curproc, $args) = @_;
    my $message = $curproc->incoming_message();
    my $config  = $curproc->config();

    if (defined $message) {
	my $functions = $config->get_as_array_ref('article_filter_functions');
	my $status    = 0;

      FUNCTION:
	for my $function (@$functions) {
	    if ($config->yes( "use_${function}" )) {
		Log("filter(debug): check by $function");
		my $fp = "_apply_$function";
		$status = $self->$fp($curproc, $args, $message);
	    }
	    else {
		Log("filter(debug): not check by $function");
	    }

	    last FUNCTION if $status;
	}

	return $status if $status;
    }

    return undef;
}


# Descriptions: header based filter
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) OBJ($mesg)
# Side Effects: none
# Return Value: STR(reason) or 0 (not trapped, ok)
sub _apply_article_header_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    use FML::Filter::Header;
    my $obj = new FML::Filter::Header;

    if (defined $obj) {
	# overwrite filter rules based on FML::Config
	my $rules = $config->get_as_array_ref('article_header_filter_rules');

	# overwrite rules
	if (defined $rules) {
	    $obj->rules( $rules );
	}

	# go check
	$obj->header_check($mesg);
	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    $x =~ s/[\n\s]*$//m;
	    $self->error_set($x);
	    return $x;
	}
    }

    return 0;
}


# Descriptions: filter non MIME format message
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) OBJ($mesg)
# Side Effects: none
# Return Value: 0 (always ok, anyway)
sub _apply_article_non_mime_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    if ($config->yes( 'use_article_non_mime_filter' )) {
	my $rules =
	    $config->get_as_array_ref('article_none_mime_filter_rules');

      RULE:
	for my $rule (@$rules) {
	    if ($rule eq 'permit') {
		return 0;
	    }

	    # XXX-TODO: implement this!
	    if ($rule eq 'reject') {
		;
	    }
	}
    }

    return 0;
}


# Descriptions: syntax check for text(/plain)
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) OBJ($mesg)
# Side Effects: none
# Return Value: none
sub _apply_article_text_plain_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    if ($config->yes( 'use_article_text_plain_filter' )) {
	use FML::Filter::TextPlain;
	my $obj = new FML::Filter::TextPlain;

	# overwrite filter rules based on FML::Config
	my $rules =
	    $config->get_as_array_ref('article_text_plain_filter_rules');
	if (defined $rules) {
	    $obj->rules( $rules );
	}

	# go check
	$obj->body_check($mesg);
	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    $x =~ s/[\n\s]*$//m;
	    $self->error_set($x);
	    return $x;
	}
    }

    return 0;
}


# Descriptions: analyze MIME structure and filter it if matched.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) OBJ($mesg)
# Side Effects: none
# Return Value: none
sub _apply_article_mime_component_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    if ($config->yes( 'use_article_mime_component_filter' )) {
	use FML::Filter::MimeComponent3;
	my $obj  = new FML::Filter::MimeComponent;
	my $file = $config->get('article_mime_component_filter_rules');

	if (-f $file) {
	    $obj->read_filter_rule_from_file($file);
	    $obj->mime_component_check($mesg);
	}
	else {
	    Log("(debug) disabled since rule file not found");
	    return 0;
	}

	if ($obj->error()) {
	    my $x = $obj->error();
	    $x =~ s/\s*at .*$//;
	    $x =~ s/[\n\s]*$//m;
	    $self->error_set($x);
	    return $x;
	}
    }

    return 0;
}


=head1 REJECT NOTIFICATION

=head2 article_filter_reject_notice($curproc, $msg_args)

send back message on rejection, with reason if could.

=cut


# Descriptions: 
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($msg_args)
# Side Effects: update reply message queue
# Return Value: none
sub article_filter_reject_notice
{
    my ($obj, $curproc, $msg_args) = @_;
    my $msg = $curproc->incoming_message();
    my $r   = $msg_args->{ _arg_reason } || 'unknown';

    $curproc->reply_message_nl("error.reject_post",
			       "your post is rejected.",
			       $msg_args);
    $curproc->reply_message_nl("error.reject_post_reason",
			       "reason(s) for rejection: $r",
			       $msg_args);

    # add header info
    my $tag     = '   ';
    my $hdr     = $curproc->incoming_message_header();
    my $hdr_str = sprintf("\n%s\n", $hdr->as_string());
    $hdr_str    =~ s/\n/\n$tag/g;
    $curproc->reply_message($hdr_str);

    $curproc->reply_message($msg, $msg_args);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
