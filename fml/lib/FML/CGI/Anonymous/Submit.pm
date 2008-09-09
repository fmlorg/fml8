#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::CGI::Anonymous::Submit;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::CGI::Skin::Anonymous;
@ISA = qw(FML::CGI::Skin::Anonymous);


=head1 NAME

FML::CGI::Anonymous::Submit - submit a request from an anonymous user.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Anonymous::Submit appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
