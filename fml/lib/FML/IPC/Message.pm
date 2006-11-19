#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Message.pm,v 1.8 2006/11/12 14:39:14 fukachan Exp $
#

package FML::IPC::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::IPC::Message - basic message abstaction for IPC.

=head1 SYNOPSIS

    my $msg = new FML::IPC::Message;

=head1 DESCRIPTION

FML::IPC::Message provides basic message abstraction suitable for
message queue library.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create an object
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: set value for key.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: none
sub set
{
    my ($self, $key, $value) = @_;
    $self->{ $key } = $value;
}


# Descriptions: get value for key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, $key) = @_;
    return $self->{ $key } || '';
}


# Descriptions: dump data into handle $wh.
#    Arguments: OBJ($self) HANDLE($wh)
# Side Effects: none
# Return Value: none
sub dump
{
    my ($self, $wh) = @_;
    my ($k, $v);

    while (($k, $v) = each %$self) {
	if ($k =~ /\s+/o) {
	    croak("invalid key: contains space");
	}
	else {
	    print $wh "$k\t$v\n";
	}
    }
}


# Descriptions: restore data from handle $rh.
#    Arguments: OBJ($self) HANDLE($rh)
# Side Effects: none
# Return Value: none
sub restore
{
    my ($self, $rh) = @_;
    my ($k, $v);
    my $buf;

  LINE:
    while ($buf = <$rh>) {
	next LINE if $buf =~ /^\s*$/o;

	($k, $v) = split(/\s+/, $buf, 2);
	$self->set($k, $v) if defined $k && defined $v;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::IPC::Message appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
