#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: ThreadTrack.pm,v 1.9 2001/05/30 04:03:21 fukachan Exp $
#

package FML::CGI::ThreadTrack;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::ThreadTrack - CGI details to control ticket system

=head1 SYNOPSIS

    $ticket = new FML::CGI::ThreadTrack;
    $ticket->new();
    $ticket->run();

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

C<NOT YET IMPLEMENTED>.

=head2 CLASS HIERARCHY

C<FML::CGI::ThreadTrack> is a subclass of C<FML::Process::CGI>.

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for CGI.
But ticket model specific routines exist within C<FML::Ticket::Model>.

=cut


sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $config->{ program_name };

    print STDERR "(debug) loading $0\n";
    print STDERR $curproc->safe_param_ml_name(), "\n";
    print STDERR $curproc->safe_param_method(), "\n";
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and 
L<FML::Process::Flow>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::CGI::ThreadTrack appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
