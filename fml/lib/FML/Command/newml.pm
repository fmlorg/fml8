#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Command::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::newml - make a new mailing list

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


=head2 C<newml( $ml_name )>

=cut


sub newml
{
    my ($self, $curproc, $ml_name) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };

    # fundamental check
    croak("\$ml_name is not specified")    unless $ml_name;

    my $ml_home_prefix = $curproc->{ ml_home_prefix };
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
