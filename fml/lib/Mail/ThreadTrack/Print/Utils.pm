#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.5 2002/09/22 14:57:07 fukachan Exp $
#

package Mail::ThreadTrack::Print::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(decode_mime_string STR2EUC);


=head1 NAME

Mail::ThreadTrack::Print::Utils - utility functions

=head1 SYNOPSIS

   use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);

=head1 DESCRIPTION

utility functions to manipulate Japanese string.

=head1 METHODS

=head2 decode_mime_string(string, [$options])

decode a base64/quoted-printable encoded string to a plain message.
The encoding method is automatically detected.

C<$options> is a HASH REFERENCE.
You can specify the charset of the string to return
by $options->{ charset }.

=head2 STR2EUC(str)

convert str to Japanese EUC.

=cut


# Descriptions: decode $str
#    Arguments: STR($str) HASH_REF($options)
# Side Effects: none
# Return Value: STR
sub decode_mime_string
{
    my ($str, $options) = @_;
    my $charset = $options->{ 'charset' } || 'euc-japan';

    # XXX-TODO: care for non Japanese.
    if ($charset eq 'euc-japan') {
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) {
	    eval q{ use MIME::Base64; };
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) {
	    eval q{ use MIME::QuotedPrint;};
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }
    }

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    $str;
}


# Descriptions: convert $str to Japanese EUC
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub STR2EUC
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    return $str;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::Print::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
