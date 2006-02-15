#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.14 2005/08/19 11:15:24 fukachan Exp $
#

package Mail::Message::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Message::Utils - utility functions for Mail::Message.

=head1 SYNOPSIS

   use Mail::Message::Utils;
   return Mail::Message::Utils::delete_subject_tag_like_string($str);

=head1 DESCRIPTION

utility function for message manipulation.
Currently only delete_subject_tag_like_string() is implemented.

=head1 METHODS

=head2 delete_subject_tag_like_string(str)

remove subject tag like string such as [elena 100].

=cut


# Descriptions: remove subject tag like string such as [elena 100].
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub delete_subject_tag_like_string
{
    my ($str) = @_;

    $str =~ s/^\s*\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;

    return $str;
}


=head2 from_address_to_name($address)

extract gecos field in $address with shielding the real address.

=cut


# Descriptions: extract gecos field in $address.
#    Arguments: STR($address)
# Side Effects: none
# Return Value: STR
sub from_address_to_name
{
    my ($address) = @_;
    my ($user);

    use Mail::Address;
    my (@addrs) = Mail::Address->parse($address);

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;

    for my $addr (@addrs) {
	if (defined( $addr->phrase() )) {
	    my $phrase = $encode->decode_mime_string( $addr->phrase() );

	    if ($phrase) {
		return($phrase);
	    }
	}

	$user = $addr->user();
    }

    return( $user ? "$user\@xxx.xxx.xxx.xxx" : $address );
}



=head2 get_time_from_header

return formated time of message Date:.

=cut


# Descriptions: return formated time of message Date:
#    Arguments: OBJ($hdr) STR($type)
# Side Effects: none
# Return Value: STR
sub get_time_from_header
{
    my ($hdr, $type) = @_;

    if (defined($hdr) && $hdr->get('date')) {
	use Time::ParseDate;
	my $unixtime = parsedate( $hdr->get('date') );
	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime( $unixtime );

	if ($type eq 'yyyymm') {
	    return sprintf("%04d%02d", 1900 + $year, $mon + 1);
	}
	elsif ($type eq 'yyyy/mm') {
	    return sprintf("%04d/%02d", 1900 + $year, $mon + 1);
	}
    }
    else {
	warn("cannot pick up Date: field");
	return '';
    }
}


=head2 search_program($file [, $path_list ])

search C<$file>.
C<$path_list> is the ARRAY_REF.
It searches it among C<$path_list> if specified.

The default search path list is

  ('/usr/bin', '/bin', '/sbin', ' /usr/local/bin',
   '/usr/gnu/bin', '/usr/pkg/bin')

=cut


# Descriptions: search executable named as $file
#               The "path_list" is an ARRAY_REFERENCE.
#               For example,
#               search_program('md5');
#               search_program('md5', [ '/bin', '/sbin' ]);
#    Arguments: STR($file) ARRAY_REF($path_list)
# Side Effects: none
# Return Value: STR
sub search_program
{
    my ($file, $path_list) = @_;

    my $default_path_list = [
			     '/usr/bin',
			     '/bin',
			     '/sbin',
			     '/usr/local/bin',
			     '/usr/gnu/bin',
			     '/usr/pkg/bin'
			     ];

    $path_list ||= $default_path_list;

    use File::Spec;
    my $path;
    for $path (@$path_list) {
	my $prog = File::Spec->catfile($path, $file);
	if (-x $prog) {
	    return $prog;
	}
    }

    return wantarray ? () : undef;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
