#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Filter.pm,v 1.12 2002/09/29 12:43:23 fukachan Exp $
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
Detail of rules is found in
L<FML::Filter::HeaderCheck> and L<FML::Filter::BodyCheck>.

=head1 METHODS

=head2 C<new()>

standard constructor.

=cut


# Descriptions: standard constructor.
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
	my $status = 0;

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
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: 0 (always ok, anyway)
sub _apply_article_non_mime_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    return 0;
}


# Descriptions: syntax check for text(/plain)
#    Arguments: OBJ($self) HASH_REF($args)
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
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _apply_article_mime_component_filter
{
    my ($self, $curproc, $args, $mesg) = @_;
    my $config = $curproc->config();

    if ($config->yes( 'use_article_mime_component_filter' )) {
	use FML::Filter::MimeComponent;
	my $obj = new FML::Filter::MimeComponent;

	# XXX DISABLED NOW ANYWAY
	return 0;

	# overwrite filter rules based on FML::Config
	my $rules = 
	    $config->get_as_array_ref('article_mime_component_filter_rules');
	if (defined $rules) {
	    $obj->rules( $rules );
	}

	# go check
	$obj->content_check($mesg);
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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
