#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: help.pm,v 1.1 2001/10/08 15:54:42 fukachan Exp $
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
    my $charset       = $config->{ template_file_charset };
    my $help_file     = $config->{ help_file };
    my $options       = $optargs->{ options };
    my $address       = $optargs->{ address } || $options->[ 0 ];

    # *** template substitution ***
    # 1. in Japanese case, convert kanji code: iso-2022-jp -> euc
    # 2. expand variables: $ml_name -> elena
    # 3. back kanji code: euc -> iso-2022-jp
    # 4. return the new created template
    my $help_template = $curproc->expand_variables_in_file( $help_file );

    if (-f $help_file) {
	$curproc->reply_message( {
	    type        => "text/plain; charset=$charset",
	    path        => $help_template,
	    filename    => "help",
	    disposition => "help",
	});
    }
    else {
	croak("no help file ($help_file)\n");
    }
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
