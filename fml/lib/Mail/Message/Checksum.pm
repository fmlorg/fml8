#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Checksum.pm,v 1.14 2006/05/11 14:27:03 fukachan Exp $
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

    bless $me, $type;
    $me->set_mode("unknown");
    $me->_init($args);

    return bless $me, $type;
}


# Descriptions: initialization routine called at new().
#               load class or search a md5 module or program.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _init
{
    my ($self, $args) = @_;

    # 1. try internal module loading.
    my $is_loaded = $self->_load_class('Digest::MD5');
    unless ($is_loaded) {
	$is_loaded = $self->_load_class('MD5');
    }

    # 2. try external programs.
    unless ($is_loaded) {
	$self->_init_external($args);
    }
}


# Descriptions: initialization routine called at new().
#               search a md5 module or program.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: update $self
# Return Value: none
sub _init_external
{
    my ($self, $args) = @_;

    return if defined $self->{ _program };

    if (defined $args->{ program }) {
	$self->{ _program } = $args->{ program };
	$self->set_mode("external");
    }
    else {
	# XXX-TODO: method-ify
	eval q{
	    use Mail::Message::Utils;
	    my $prog = Mail::Message::Utils::search_program('md5') ||
	      Mail::Message::Utils::search_program('md5sum');
	    
	    if (defined $prog) {
		$self->{ _program } = $prog;
		$self->set_mode("external");
	    }
	    else {
		croak("external program md5/md5sum not found");
	    }
	};
	croak($@) if $@;
    }
}


# Descriptions: load $class object.
#    Arguments: OBJ($self) STR($class)
# Side Effects: load $class module.
# Return Value: NUM
sub _load_class
{
    my ($self, $class) = @_;

    my $obj = undef;
    eval qq{ require $class; $class->import(); \$obj = new $class; };
    unless ($@) {
	$self->set_mode("internal");
	$self->{ _class } = $class;
	$self->{ _obj   } = $obj;
	return 1;
    }
    else {
	return 0;
    }
}


=head2 md5(\$string)

same as md5_str_ref().

=head2 md5_str_ref(\$string)

return the md5 checksum of the specified string C<$string>.

=cut


# Descriptions: return the md5 checksum of the specified STR_REF.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub md5
{
    my ($self, $r_data) = @_;
    $self->md5_str_ref($r_data);
}


# Descriptions: return the md5 checksum of the specified STR_REF.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub md5_str_ref
{
    my ($self, $r_data) = @_;
    my $type = $self->get_mode() || 'unknown';

    if ($type eq 'internal' || $type eq 'external') {
	my $fp = sprintf("_%s_%s", $type, "md5_str_ref");
	$self->$fp($r_data);
    }
    else {
	croak("no md5 definition");
    }
}


# Descriptions: calculate the md5 checksum by MD5 module.
#    Arguments: OBJ($self) STR_REF($r_data)
# Side Effects: none
# Return Value: STR(md5 sum)
sub _internal_md5_str_ref
{
    my ($self, $r_data) = @_;

    my $md5 = $self->{ _obj };
    croak("no md5 object") unless defined $md5;

    my $buf;
    my $p  = 0;
    my $pe = length($$r_data);
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
sub _external_md5_str_ref
{
    my ($self, $r_data) = @_;

    $self->_init_external();
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

	    my $cksum = $self->_read_cksum_from_handle($rh);
	    close($rh);

	    return $cksum if $cksum;
	}
    }

    return undef;
}


# Descriptions: read checksum from the specified handle. 
#    Arguments: OBJ($self) HANDLE($rh)
# Side Effects: none
# Return Value: STR
sub _read_cksum_from_handle
{
    my ($self, $rh) = @_;
    my $cksum = 0;

    sysread($rh, $cksum, 1024);
    $cksum =~ s/[\s\n]*$//o;
    if ($cksum =~ /^(\S+)/) { $cksum = $1;}

    return $cksum;
}


=head2 md5_file($file)

return the md5 checksum of the specified file.

=cut


# Descriptions: return the md5 checksum of the specified file.
#    Arguments: OBJ($self) STR_REF($file)
# Side Effects: none
# Return Value: STR(md5 sum)
sub md5_file
{
    my ($self, $file) = @_;
    my $type = $self->get_mode() || 'unknown';

    if ($type eq 'internal' || $type eq 'external') {
	my $fp = sprintf("_%s_%s", $type, "md5_file");
	$self->$fp($file);
    }
    else {
	croak("no md5 definition");
    }
}


# Descriptions: calculate the md5 checksum by MD5 module.
#    Arguments: OBJ($self) STR_REF($file)
# Side Effects: none
# Return Value: STR(md5 sum)
sub _internal_md5_file
{
    my ($self, $file) = @_;

    my $md5 = $self->{ _obj };
    croak("no md5 object") unless defined $md5;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $buf;
      BUF:
	while (sysread($rh, $buf, 8192)) {
	    $md5->add($buf);
	}
    }
    else {
	croak("cannot open $file");
    }

    $md5->hexdigest();
}


# Descriptions: calculate the md5 checksum by md5 (external) program.
#    Arguments: OBJ($self) STR_REF($file)
# Side Effects: none
# Return Value: STR(md5 sum)
sub _external_md5_file
{
    my ($self, $file) = @_;

    $self->_init_external();
    if (defined $self->{ _program }) {
	my $program = $self->{ _program };

	use FileHandle;
	my ($rh, $wh) = FileHandle::pipe;

	# XXX UNIX only o.k. MD5 and Digest::MD5 are available on M$.
	eval qq{ require IPC::Open2; IPC::Open2->import();};
	my $pid = open2($rh, $wh, $self->{ _program });
	if (defined $pid) {
	    $self->_external_md5_file_inject_data($file, $wh);
	    close($wh);

	    my $cksum = $self->_read_cksum_from_handle($rh);
	    close($rh);

	    return $cksum if $cksum;
	}
    }

    return undef;
}


# Descriptions: inject $file into $wh handle.
#    Arguments: OBJ($self) STR($file) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub _external_md5_file_inject_data
{
    my ($self, $file, $wh) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $buf;
      BUF:
	while (sysread($rh, $buf, 8192)) {
	    print $wh $buf;
	}
    }
    else {
	croak("cannot open $file");
    }
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


=head1 ACCESS METHODS

=head2 set_mode($mode)

set mode.

=head2 get_mode()

get current mode. return unknown if not set.

=cut


# Descriptions: set mode.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: update $self
# Return Value: none
sub set_mode
{
    my ($self, $mode) = @_;
    $self->{ _mode } = $mode || 'unknown';
}


# Descriptions: get current mode.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_mode
{
    my ($self) = @_;
    return( $self->{ _mode } || 'unknown' );
}



#
# DEBUG
#
if ($0 eq __FILE__) {
   # 1. call with string reference.
   for my $mode (qw(internal external)) {
       my $cksum = new Mail::Message::Checksum;
       print STDERR "1. STR REF ($mode) ... ";
       $cksum->set_mode($mode);
       my $sys_md5 = `head -1 /etc/passwd | md5`;
       my $string  = `head -1 /etc/passwd`;
       my $our_md5 = $cksum->md5( \$string );
       $sys_md5 =~ s/\s*$//;
       $our_md5 =~ s/\s*$//;
       print STDERR (($sys_md5 eq $our_md5) ? "ok\n" : "fail\n");
   }

   # 2. file or stream.
   for my $mode (qw(internal external)) {
       my $cksum = new Mail::Message::Checksum;
       print STDERR "2. FILE    ($mode) ... ";
       $cksum->set_mode($mode);
       my $sys_md5 = `cat /etc/passwd | md5`;
       my $our_md5 = $cksum->md5_file("/etc/passwd");
       $sys_md5 =~ s/\s*$//;
       $our_md5 =~ s/\s*$//;
       print STDERR (($sys_md5 eq $our_md5) ? "ok\n" : "fail\n");
   }

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

Mail::Message::Checksum first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

Algorithm used here is based on NetBSD cksum library (C program).

=cut

1;
