#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package Mail::Message::Address;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Mail::Address;


=head1 NAME

Mail::Message::Address - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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

    my $me   = {
	_addrs     => \@addrs,
	_addr_head => $addrs[0],
	_orig_str  => $str,
    };

    return bless $me, $type;
}


=head1 CLEAN UP

=head2 clean_up()

clean up address and return it.

=cut


# Descriptions: utility to remove ^\s*< and >\s*$.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _str }.
# Return Value: none
sub clean_up
{
    my ($self) = @_;
    my $addr   = $self->address();

    # 1. remove ^\s*< and >\s*$.
    $addr =~ s/^\s*<//o;
    $addr =~ s/>\s*$//o;

    # return the result.
    $self->{ _str } = $addr || '';
}


=head1 Mail::Address FORWARDING.

=head2 address()

return address by string.

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
