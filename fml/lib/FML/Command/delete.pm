#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Command::delete;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::delete - add a new member

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut

sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub delete
{
    my ($self, $curproc, $address) = @_;
    my $config     = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use IO::MapAdapter;
    my $obj = new IO::MapAdapter $member_map;
    $obj->delete( $address );

    $obj = new IO::MapAdapter $recipient_map;
    $obj->delete( $address );
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::MemberControl appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
