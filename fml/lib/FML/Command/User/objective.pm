#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: objective.pm,v 1.13 2004/06/26 11:47:58 fukachan Exp $
#

package FML::Command::User::objective;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Command::SendFile;
@ISA = qw(FML::Command::SendFile);


=head1 NAME

FML::Command::User::objective - send back ML's objective message.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 process($curproc, $command_context)

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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: send back objective message via FML::Command::SendFile.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

    $self->send_user_xxx_message($curproc, $command_context, "objective");
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::objective first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
