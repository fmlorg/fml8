#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Checksum.pm,v 1.12 2004/07/23 13:16:44 fukachan Exp $
#

package Mail::Message::Checksum;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Message::Checksum - utilities for checksum.

=head1 SYNOPSIS

   use Mail::Message::Checksum;
   $cksum  = new Mail::Message::Checksum;
   $md5sum = $cksum->md5( \$string );

=head1 METHODS

=head2 new()

constructor.
It checks we can use MD5 perl module or we need to use external programs
such as C<md5>, C<cksum>, et.al.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _init($me, $args);

    return bless $me, $type;
}


# Descriptions: initialization routine called at new().
#               search a md5 module or program.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _init
{
    my ($self, $args) = @_;

    if (defined $args->{ program }) {
	$self->{ _program } = $args->{ program };
    }

    # XXX-TODO: Digest::MD5
    my $pkg = 'MD5';
    eval qq{ require $pkg; $pkg->import();};

    unless ($@) {
	$self->{ _type } = 'native';
    }
    else {
	# XXX-TODO: method-ify
	eval q{
	    use Mail::Message::Utils;
	    my $prog = Mail::Message::Utils::search_program('md5') ||
	      Mail::Message::Utils::search_program('md5sum');

	    if (defined $prog) {
		$self->{ _program } = $prog;
	    }
	};
	carp($@) if $@;
    }
}


=head2 md5(\$string)

return the md5 checksum of the given string C<$string>.

=cut


# Descriptions: dispatcher to calculate the md5 checksum.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub md5
{
    my ($self, $r_data) = @_;

    if (defined($self->{ _type }) && ($self->{ _type } eq 'native')) {
	$self->_md5_native($r_data);
    }
    else {
	$self->_md5_by_program($r_data);
    }

}


# Descriptions: calculate the md5 checksum by MD5 module.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub _md5_native
{
    my ($self, $r_data) = @_;
    my ($buf, $p, $pe);

    $pe = length($$r_data);

    my $md5;
    eval q{ $md5 = new MD5;};
    $md5->reset();

    $p = 0;
  BUF:
    while (1) {
	last BUF if $p > $pe;

	$buf = substr($$r_data, $p, 128);
	$p  += 128;
	$md5->add($buf);
    }

    $md5->hexdigest();
}


# Descriptions: calculate the md5 checksum by md5 (external) program.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub _md5_by_program
{
    my ($self, $r_data) = @_;

    if (defined $self->{ _program }) {
	my $program = $self->{ _program };

	use FileHandle;
	my ($rh, $wh) = FileHandle::pipe;

	# XXX UNIX only o.k. MD5 and Digest::MD5 are available on M$.
	eval qq{ require IPC::Open2; IPC::Open2->import();};
	my $pid = open2($rh, $wh, $self->{ _program });
	if (defined $pid) {
	    print $wh $$r_data;
	    close($wh);

	    my $cksum = 0;
	    sysread($rh, $cksum, 1024);
	    $cksum =~ s/[\s\n]*$//o;
	    if ($cksum =~ /^(\S+)/) { $cksum = $1;}
	    close($rh);
	    return $cksum if $cksum;
	}
    }

    return undef;
}


=head2 cksum1($file)

C<not implemented>.

This is a 16-bit checksum. The algorithm used by historic BSD systems
as the sum(1) algorithm and by historic AT&T System V UNIX systems as
the sum algorithm when using the C<-r> option.

=head2 cksum2($file)

return the traditional checksum of the given C<$file>.

This is a 32-bit checksum. The algorithm used by historic AT&T System
V UNIX systems as the default sum algorithm.

See POSIX 1003.2 for more details.

=cut


# Descriptions: return the traditional checksum of the given $file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub cksum2
{
    my ($self, $file) = @_;
    my ($crc, $total, $nr, $buf, $r);

    # XXX-TODO: style
    $crc = $total = 0;
    if (open($file, $file)) {
        while (($nr = sysread($file, $buf, 1024)) > 0) {
            my ($i) = 0;
            $total += $nr;

            for ($i = 0; $i < $nr; $i++) {
                $r = substr($buf, $i, 1);
                $crc += ord($r);
            }
        }
        close($file);
        $crc = ($crc & 0xffff) + ($crc >> 16);
        $crc = ($crc & 0xffff) + ($crc >> 16);
    }
    else {
        croak("ERROR: no such file $file");
    }

    return ($crc, $total);
}


=head2 crc($file)

C<not implemented>.

The default CRC used is based on the polynomial used for CRC error
checking in the networking standard ISO 8802-3:1989 The CRC checksum
encoding is defined by the generating polynomial:

  G(x) = x^32 + x^26 + x^23 + x^22 + x^16 + x^12 +
         x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1

Mathematically, the CRC value corresponding to a given file is defined
by the following procedure:

The n bits to be evaluated are considered to be the coefficients of
a mod 2 polynomial M(x) of degree n-1.  These n bits are the bits
from the file, with the most significant bit being the most signif-
icant bit of the first octet of the file and the last bit being the
least significant bit of the last octet, padded with zero bits (if
necessary) to achieve an integral number of octets, followed by one
or more octets representing the length of the file as a binary val-
ue, least significant octet first.  The smallest number of octets
capable of representing this integer are used.

M(x) is multiplied by x^32 (i.e., shifted left 32 bits) and divided
by G(x) using mod 2 division, producing a remainder R(x) of degree
<= 31.

The coefficients of R(x) are considered to be a 32-bit sequence.

The bit sequence is complemented and the result is the CRC.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Checksum first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

Algorithm used here is based on NetBSD cksum library (C program).

=cut

1;
