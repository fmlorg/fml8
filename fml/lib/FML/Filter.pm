#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Filter.pm,v 1.7 2002/04/08 10:17:32 tmu Exp $
#

package FML::Filter;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter - entry point for FML::Filter::* modules

=head1 SYNOPSIS

   use FML::Filter;
   my $filter = new FML::Filter;

   $filter->check( $message );

   if ($filter->error()) {
       ... error handling ...
   }

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
sub check
{
    my ($self, $curproc, $args) = @_;
    my $message = $curproc->{ 'incoming_message' }->{ message };
    my $config  = $curproc->{ 'config' };

    if (defined $message) {
	if ($config->yes( 'use_header_filter' )) {
	    use FML::Filter::HeaderCheck;
	    my $obj = new FML::Filter::HeaderCheck;

	    # overwrite filter rules based on FML::Config
	    if (defined $config->{ header_filter_rules }) {
		my (@rules) = split(/\s+/, $config->{ header_filter_rules });
		$obj->rules( \@rules );
	    }

	    # go check
	    $obj->header_check($message);
	    if ($obj->error()) {
		my $x = $obj->error();
		$x =~ s/\s*at .*$//;
		$x =~ s/[\n\s]*$//m;
		$self->error_set($x);
		return $x;
	    }
	}

	if ($config->yes( 'use_body_filter' )) {
	    use FML::Filter::BodyCheck;
	    my $obj = new FML::Filter::BodyCheck;

	    # overwrite filter rules based on FML::Config
	    if (defined $config->{ body_filter_rules }) {
		my (@rules) = split(/\s+/, $config->{ body_filter_rules });
		$obj->rules( \@rules );
	    }

	    # go check
	    $obj->body_check($message);
	    if ($obj->error()) {
		my $x = $obj->error();
		$x =~ s/\s*at .*$//;
		$x =~ s/[\n\s]*$//m;
		$self->error_set($x);
		return $x;
	    }
	}

	if ($config->yes( 'use_content_filter' )) {
	    use FML::Filter::ContentCheck;
	    my $obj = new FML::Filter::ContentCheck;

	    # overwrite filter rules based on FML::Config
	    if (defined $config->{ content_filter_rules }) {
		my (@rules) = split(/\s+/, $config->{ content_filter_rules });
		$obj->rules( \@rules );
	    }

	    # go check
	    $obj->content_check($message);
	    if ($obj->error()) {
		my $x = $obj->error();
		$x =~ s/\s*at .*$//;
		$x =~ s/[\n\s]*$//m;
		$self->error_set($x);
		return $x;
	    }
	}
    }

    return undef; # O.K.
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
