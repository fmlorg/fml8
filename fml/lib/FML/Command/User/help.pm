#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: help.pm,v 1.2 2001/08/26 07:58:39 fukachan Exp $
#

package FML::Command::User::help;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::User::help - send back help file

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 C<process($curproc, $optargs)>

=cut


sub process
{
    my ($self, $curproc, $optargs) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $optargs->{ options };
    my $address       = $optargs->{ address } || $options->[ 0 ];

    $curproc->reply_message("help message (dummy ;-)");
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::help appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
