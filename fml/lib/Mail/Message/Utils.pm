#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.3 2002/09/11 23:18:28 fukachan Exp $
#

package Mail::Message::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Message::Utils - utility functions for Mail::Message

=head1 SYNOPSIS

   use Mail::Message::Utils;
   return Mail::Message::Utils::remove_subject_tag_like_string($str);

=head1 DESCRIPTION

utility function for message manipulation.
Currently only remove_subject_tag_like_string() is implemented.

=head1 METHODS

=head2 remove_subject_tag_like_string(str)

remove subject tag like string such as [elena 100].

=cut


# Descriptions: remove subject tag like string such as [elena 100].
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub remove_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/^\s*\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;
    $str;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
