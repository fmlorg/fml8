#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::CGI::TicketSystem;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::CGI::TicketSystem - CGI details to control ticket system

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::TicketSystem> is a subclass of C<FML::Process::CGI>.

=head1 METHODS

=head2 C<new()>

=cut

use CGI qw/:standard/; # load standard CGI routines
use FML::Process::CGI;

@ISA = qw(FML::Process::CGI Exporter);


# See CGI.pm for more details
sub run
{
    my ($curproc) = @_;

    print start_html('hello world'), "\n";
    print "<PRE>\n";
    print " hen hen hen \n";
    print "</PRE>\n";
    print "\n";
    print end_html;
    print "\n";
}



=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::CGI::TicketSystem appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
