#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Menu.pm,v 1.1 2003/09/25 11:40:57 fukachan Exp $
#

package FML::CGI::MLAdmin::Menu;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::CGI::Menu;
@ISA = qw(FML::CGI::Menu);


=head1 NAME

FML::CGI::MLAdmin::Menu - provides CGI controll for the specific domain

=head1 SYNOPSIS

    $obj = new FML::CGI::MLAdmin::Menu;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::MLAdmin::Menu> is a subclass of C<FML::Process::CGI>.

             FML::Process::Kernel
                       |
                       A
             FML::Process::CGI::Kernel
                       |
                       A
             FML::Process::CGI
                       |
                       A
            -----------------------
           |                       |
           A                       A
     FML::CGI::Menu          FML::CGI::Menu
           |                       |
           A                       A
 FML::CGI::MLAdmin::Menu    FML::CGI::MLMLAdmin::Menu

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for the admin CGI.

=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and
L<FML::Process::Flow>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::MLAdmin::Menu first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
