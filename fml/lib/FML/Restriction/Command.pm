#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.8 2002/12/15 15:17:18 fukachan Exp $
#

package FML::Restriction::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Restriction::Command - safe regexp allowed as a command

=head1 SYNOPSIS

collection of utility functions used in command routines.

=head1 DESCRIPTION

=head1 METHODS

=head2 is_secure_command_string($str)

check if $str string looks secure ?
return 1 if secure.

=cut


# Descriptions: $s looks secure ?
#    Arguments: STR($s)
# Side Effects: none
#      History: fml 4.0's SecureP()
# Return Value: NUM(1 or 0)
sub is_secure_command_string
{
   my ($s) = @_;

   # 0. clean up
   $s =~ s/^\s*\#\s*//o; # remove ^#

   # 1. trivial case
   # 1.1. empty
   if ($s =~ /^\s*$/o) {
       return 1;
   }

   # 2. allow
   #           command = [-\d\w]+
   #      mail address = [-_\w]+@[\w\-\.]+
   #   command options = last:30
   #
   # XXX sync w/ mailaddress regexp in FML::Restriction::Base ?
   # XXX hmm, it is difficult.
   #
   if ($s =~/^[-\d\w]+\s*$/o) {
       return 1;
   }
   elsif ($s =~/^[-\d\w]+\s+[\s\w\_\-\.\,\@\:]+$/o) {
       return 1;
   }

   return 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Restriction::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
