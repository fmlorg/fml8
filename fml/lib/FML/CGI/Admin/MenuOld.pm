#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MenuOld.pm,v 1.30 2004/07/23 13:16:34 fukachan Exp $
#

package FML::CGI::Admin::MenuOld;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::CGI::Skin::OldFashion;
@ISA = qw(FML::CGI::Skin::OldFashion);


=head1 NAME

FML::CGI::Admin::MenuOld - provides CGI control function for the specific domain.

=head1 SYNOPSIS

    $obj = new FML::CGI::Admin::MenuOld;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Admin::MenuOld> is a subclass of C<FML::Process::CGI>.

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
     FML::CGI::MenuOld          FML::CGI::MenuOld
           |                       |
           A                       A
 FML::CGI::Admin::MenuOld    FML::CGI::MLAdmin::MenuOld

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

FML::CGI::Admin::MenuOld first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
