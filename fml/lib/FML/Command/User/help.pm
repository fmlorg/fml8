#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: help.pm,v 1.2 2001/10/10 10:08:07 fukachan Exp $
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
    my $charset       = $config->{ reply_message_charset };
    my $help_file     = $config->{ help_file };

    # template substitution: kanji code, $varname expansion et. al.
    my $params = {
	src         => $help_file,
	charset_out => $charset,
    };
    my $help_template = $curproc->prepare_file_to_return( $params ); 

    if (-f $help_template) {
	$curproc->reply_message( {
	    type        => "text/plain; charset=$charset",
	    path        => $help_template,
	    filename    => "help",
	    disposition => "help",
	});
    }
    else {
	croak("no help file ($help_template)\n");
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
