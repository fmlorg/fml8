#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: deny.pm,v 1.11 2004/04/23 04:10:32 fukachan Exp $
#

package FML::Command::User::deny;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Command::SendFile;
@ISA = qw(FML::Command::SendFile);


=head1 NAME

FML::Command::User::deny - send back deny file

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: standard constructor
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
sub need_lock { 0;}


# Descriptions: send deny file by FML::Command::SendFile.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->send_user_xxx_message($curproc, $command_args, "deny");
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::deny first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
