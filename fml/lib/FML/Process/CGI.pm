#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: CGI.pm,v 1.24 2004/01/02 14:42:43 fukachan Exp $
#

package FML::Process::CGI;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Process::CGI::Kernel;
use FML::Process::CGI::Param;
@ISA = qw(FML::Process::CGI::Kernel FML::Process::CGI::Param);

=head1 NAME

FML::Process::CGI - CGI basic functions.

=head1 SYNOPSIS

   use FML::Process::CGI;
   my $obj = new FML::Process::CGI;
   $obj->prepare($args);
      ... snip ...

This new() creates CGI object which wraps C<FML::Process::Kernel>.

=head1 DESCRIPTION

the base class of CGI programs.
It provides basic functions and flow.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
