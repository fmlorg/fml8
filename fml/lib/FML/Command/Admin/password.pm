#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: password.pm,v 1.4 2002/09/22 14:56:46 fukachan Exp $
#

package FML::Command::Admin::password;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::password - change password (dummy in fact :-)

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

password a new address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: dummy.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    # this module is dummy.
    # The code exists in FML::Command::Auth due to ambivalence.
    # Though this module should be called after authentication,
    # this module is a module of authentication.

    # XXX-TODO: NOT IMPLEMNETED.

    # dummy
    return 1;
}


# Descriptions: rewrite buffer to hide the password phrase in $rbuf
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;

    if (defined $rbuf) {
	$$rbuf =~ s/^(.*(password|pass)\s+).*/$1 ********/;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::password first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
