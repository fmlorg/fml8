#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Checksum.pm,v 1.11 2001/04/03 09:45:40 fukachan Exp $
#

package FML::Checksum;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Checksum - utilities for check sum

=head1 SYNOPSIS

   use FML::Checksum;
   $cksum  = new FML::Checksum;
   $md5sum = $cksum->md5( \$string );

=head1 METHODS

=head2 C<new()>

the constructor. 
It checks we can use MD5 perl module or we need to use external programs
such as C<md5>, C<cksum>, et.al.

=cut


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _init($me, $args);

    return bless $me, $type;
}


sub _init
{
    my ($self, $args) = @_;

    if (defined $args->{ program }) {
	$self->{ _program } = $args->{ program };
    }

    my $pkg = 'MD5';
    eval qq{ require $pkg; $pkg->import();};

    unless ($@) {
	$self->{ _type } = 'native';
    }
    else {
	eval qq{ require File::Utils; import File::Utils qw(search_program);};
	my $prog = search_program('md5') || search_program('md5sum');
	if (defined $prog) {
	    $self->{ _program } = $prog;
	} 
    }
}



=head2 C<md5(\$string)>

return the md5 checksum of the given string C<$string>.

=cut


sub md5
{
    my ($self, $r_data) = @_;

    if ($self->{ _type } eq 'native') {
	$self->_md5_native($r_data);
    }
    else {
	$self->_md5_by_program($r_data);
    }

}


sub _md5_native
{
    my ($self, $r_data) = @_;
    my ($buf, $p, $pe);

    $pe = length($$r_data);

    my $md5;
    eval q{ $md5 = new MD5;};
    $md5->reset();

    $p = 0;
    while (1) {
	last if $p > $pe;
	$_  = substr($$r_data, $p, 128);
	$p += 128;
	$md5->add($_);
    }

    $md5->hexdigest();
}


sub _md5_by_program
{
    my ($self, $r_data) = @_;

    if (defined $self->{ _program }) {
	my $program = $self->{ _program };
	
	use FileHandle;
	my ($rh, $wh) = FileHandle::pipe;

	eval qq{ require IPC::Open2; IPC::Open2->import();};
	my $pid = open2($rh, $wh, $self->{ _program });
	if (defined $pid) {
	    print $wh $$r_data;
	    close($wh);
	    my $cksum = 0;
	    sysread($rh, $cksum, 1024);
	    $cksum =~ s/[\s\n]*$//;
	    close($rh);
	    return $cksum if $cksum;
	}
    }

    undef;
}


=head2 C<cksum1($file)>

C<not implemented>.

This is a 16-bit checksum. The algorithm used by historic BSD systems
as the sum(1) algorithm and by historic AT&T System V UNIX systems as
the sum algorithm when using the C<-r> option.

=head2 C<cksum2($file)>

return the traditional checksum of the given C<$file>.

This is a 32-bit checksum. The algorithm used by historic AT&T System
V UNIX systems as the default sum algorithm.

See POSIX 1003.2 for more details.

=cut


sub cksum2
{
    my ($self, $f) = @_;
    my ($crc, $total, $nr, $buf, $r);

    $crc = $total = 0;
    if (open($f, $f)) {
        while (($nr = sysread($f, $buf, 1024)) > 0) {
            my ($i) = 0;
            $total += $nr;

            for ($i = 0; $i < $nr; $i++) {
                $r = substr($buf, $i, 1);
                $crc += ord($r);
            }
        }
        close($f);
        $crc = ($crc & 0xffff) + ($crc >> 16);
        $crc = ($crc & 0xffff) + ($crc >> 16);
    }
    else {
        Log("ERROR: no such file $f");
    }

    ($crc, $total);
}


=head2 C<crc($file)>

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

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Checksum appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

Algorithm used here is based on NetBSD cksum library (C program).

=cut

1;
