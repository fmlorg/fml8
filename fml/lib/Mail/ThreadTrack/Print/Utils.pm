#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Print.pm,v 1.9 2001/11/08 14:17:39 fukachan Exp $
#

package Mail::ThreadTrack::Print::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(decode_mime_string STR2EUC);


=head2 C<decode_mime_string(string, [$options])>

decode a base64/quoted-printable encoded string to a plain message.
The encoding method is automatically detected.

C<$options> is a HASH REFERENCE.
You can specify the charset of the string to return 
by $options->{ charset }. 

=cut


sub decode_mime_string
{
    my ($str, $options) = @_;
    my $charset = $options->{ 'charset' } || 'euc-japan';

    if ($charset eq 'euc-japan') {
        use MIME::Base64;
        if ($str =~ /=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?B\?(\S+\=*)\?=/decode_base64($1)/gie;
        }

        use MIME::QuotedPrint;
        if ($str =~ /=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/i) { 
            $str =~ s/=\?ISO\-2022\-JP\?Q\?(\S+\=*)\?=/decode_qp($1)/gie;
        }
    }

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    $str;
}


sub STR2EUC
{
    my ($str) = @_;

    use Jcode;
    &Jcode::convert(\$str, 'euc');
    return $str;
}


1;
