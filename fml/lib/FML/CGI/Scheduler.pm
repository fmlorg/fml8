#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Scheduler.pm,v 1.2 2001/04/03 09:45:41 fukachan Exp $
#

package FML::CGI::Scheduler;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Scheduler - CGI details to control ticket system

=head1 SYNOPSIS

    $ticket = new FML::CGI::Scheduler;
    $ticket->new();
    $ticket->run();

See L<FML::Process::Flow> for flow methods details.

=head1 DESCRIPTION

C<NOT YET IMPLEMENTED>.

=head2 CLASS HIERARCHY

C<FML::CGI::Scheduler> is a subclass of C<FML::Process::CGI>.

             FML::Process::Kernel
                       |
                       A
             FML::Process::CGI
                       |
                       A
            -----------------------
           |                       |
           A                       A
 FML::CGI::Scheduler

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for CGI.

=cut


sub run
{
    my ($curproc, $args) = @_;

    use FileHandle;
    use TinyScheduler;

    my $schedule = new TinyScheduler { user => param('user') };
    $schedule->parse;
    $schedule->print;
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

FML::CGI::Scheduler appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
