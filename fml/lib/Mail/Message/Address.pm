#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Address.pm,v 1.4 2004/06/29 10:03:48 fukachan Exp $
#

package Mail::Message::Address;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Address;


=head1 NAME

Mail::Message::Address - manipulate address type string.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is an adapter for Mail::Address for convenience.

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) STR($str)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $str) = @_;
    my ($type) = ref($self) || $self;

    # parse it by Mail::Address.
    my (@addrs) = Mail::Address->parse($str);
    my $addr    = $addrs[0]->address;

    # XXX in-core data area.
    # XXX if we manipulate Mail::Address object, it is dangerous. So
    # XXX not use @ISA to Mail::Address class but use it via AUTOLOAD()
    # XXX as object composition.
    my $me = {
	_addrs       => \@addrs,
	_addr_head   => $addrs[0] || '',
	_string      => $addr     || '',
	_orig_string => $str      || '',
    };

    return bless $me, $type;
}


# Descriptions: return date as string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub as_str
{
    my ($self) = @_;

    return $self->{ _string };
}


=head1 CLEAN UP

=head2 clean_up()

clean up address. no return value.

=cut


# Descriptions: utility to remove ^\s*< and >\s*$.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _string }.
# Return Value: none
sub clean_up
{
    my ($self) = @_;
    my $addr   = $self->{ _string } || '';

    # 1. remove ^\s*< and >\s*$.
    $addr =~ s/^\s*<//o;
    $addr =~ s/>\s*$//o;

    # return the result.
    $self->{ _string } = $addr || '';
}


=head1 UTILITIES

=head2 substr($offset, $len)

return $len byte of data from $offset.

=cut


# Descriptions: return substr()-fied data.
#    Arguments: OBJ($self) NUM($offset) NUM($len)
# Side Effects: none
# Return Value: STR
sub substr
{
    my ($self, $offset, $len) = @_;
    my $addr = $self->{ _string } || '';

    return substr($addr, $offset, $len);
}


=head1 Mail::Address FORWARDING.

forward request to Mail::Address class. Forwarded requests follow:
phrase, address, comment, format, name, host, user, path, canon.

=cut


# Descriptions: return address by string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub AUTOLOAD
{
    my ($self) = @_;
    my $addr   = $self->{ _addr_head } || undef;

    # we need to ignore DESTROY()
    return if $AUTOLOAD =~ /DESTROY/o;

    my $function = $AUTOLOAD;
    $function =~ s/.*:://o;

    if ($function =~
	/^(phrase|address|comment|format|name|host|user|path|canon)$/o) {
	if (defined $addr) {
	    return $addr->$function();
	}
	else {
	    return '';
	}
    }
    else {
	croak("$function method undefined.");
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $format = "%7s %s\n";

    for my $file (@ARGV) {
	use FileHandle;
	my $fh = new FileHandle $file;
	if (defined $fh) {
	    my ($buf, @buf);
	    while (<$fh>) { $buf .= $_ if 1 .. /^$/;}

	    use Mail::Header;
	    my (@hdr) = split(/\n/, $buf);
	    my $hdr   = new Mail::Header \@hdr;
	    my $str   = $hdr->get('from'); $str =~ s/\n$//o;

	    print "\n";
	    printf $format, "FILE", $file;
	    printf $format, "STR",  $str;
	    if ($str) {
		my $m_addr = new Mail::Message::Address $str;
		printf $format, "ADDRESS", $m_addr->address();
		printf $format, "substr",  $m_addr->substr(0, 15);
	    }
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Address appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
