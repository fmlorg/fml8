#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Filter.pm,v 1.1 2001/10/14 23:06:38 fukachan Exp $
#

package FML::Filter;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter - entry pointer for FML::Filter::* modules

=head1 SYNOPSIS

   use FML::Filter;
   my $filter = new FML::Filter;

   $filter->check( $message );

   if ($filter->error()) {
       ... error handling ...
   }

where C<$message> is C<Mail::Message> object.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

standard constructor.

=cut

sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: entry point for FML::Filter::* modules
#    Arguments: $self $m
#               $m = Mail::Message object
# Side Effects: none
# Return Value: error reason (string). return undef if ok.
sub check
{
    my ($self, $curproc, $args) = @_;
    my $message = $curproc->{ 'incoming_message' };
    my $config  = $curproc->{ 'config' };

    if (defined $message) {
	if ($config->yes( 'use_header_filter' )) {
	    use FML::Filter::HeaderCheck;
	    my $obj = new FML::Filter::HeaderCheck;

	    # overwrite filter rules based on FML::Config
	    if (defined $config->{ header_filter_rles }) {
		my (@rules) = split(/\s+/, $config->{ header_filter_rles });
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
	    if (defined $config->{ header_filter_rles }) {
		my (@rules) = split(/\s+/, $config->{ body_filter_rles });
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
    }

    return undef; # O.K.
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
