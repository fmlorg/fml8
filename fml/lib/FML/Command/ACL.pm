#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.1 2001/08/07 12:23:48 fukachan Exp $
#

package FML::Command::ACL;
use strict;
use vars qw(%FML_USER_COMMAND);

%FML_USER_COMMAND = 
    (
     '__default__' => {
	 'require_lock' => 1,	 
     },

     'newml' => { 
	 'require_lock' => 0,
     },


     
     );





=head1 NAME

FML::ACL - accecc control lists

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::ACL appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
