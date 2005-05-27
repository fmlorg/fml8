#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Alias.pm,v 1.4 2004/07/23 13:16:44 fukachan Exp $
#

package FML::Sys::Alias;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Config;

my $debug = 0;


=head1 NAME

FML::Sys::Alias - get mail alias information on this system.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {
	_aliases => {},
    };

    return bless $me, $type;
}


# Descriptions: get entries in $file (e.g. /etc/mail/aliases).
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: HASH_REF
sub read_alias_file
{
    my ($self, $file) = @_;
    my $aliases = $self->{ _aliases };

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	my ($buf, $key, $addrs);

      LINE:
	while ($buf = <$fh>) {
	    next LINE if $buf =~ /^\#/o;
	    next LINE if $buf =~ /^\s*$/o;
	    chomp $buf;

	    ($key, $addrs) = split(/\s*:\s*/, $buf, 2);
	    $self->add_key($key, $addrs);
	}
	$fh->close();
    }
}


# Descriptions: add $key into aliases hash table.
#    Arguments: OBJ($self) STR($key) STR($addrs)
# Side Effects: update $self->{ _aliases }
# Return Value: none
sub add_key
{
    my ($self, $key, $addrs) = @_;
    my $aliases = $self->{ _aliases };

    $key   =~ s/\s*//g;
    $addrs =~ s/^\s*//;
    $addrs =~ s/\s*$//;
    my (@a) = split(/\s*,\s*/, $addrs);

    unless (defined $aliases->{ $key }) {
	$aliases->{ $key } = \@a;
    }
}


# Descriptions: expand $key.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: ARRAY_REF
sub expand
{
    my ($self, $key) = @_;
    my $aliases = $self->{ _aliases };

    return $self->_expand($key, $aliases->{ $key }, 0);
}


# Descriptions: expand $key and return the result as ARRAY_REF.
#    Arguments: OBJ($self) STR($key) ARRAY_REF($value) NUM($recursive)
# Side Effects: none
# Return Value: ARRAY_REF
sub _expand
{
    my ($self, $key, $value, $recursive) = @_;
    my $aliases = $self->{ _aliases };
    my @r     = ();
    my $r     = '';

    $recursive++;

    if ($debug) {
	print STDERR "    " x $recursive;
	print STDERR "INPUT { $key => $value }\n";
    }

    for my $v (@$value) {
	if ($debug) {
	    print STDERR "    " x $recursive;
	    print STDERR "expand $v =>\n";
	}
	$r = $self->_expand($v, $aliases->{ $v }, $recursive);

	if ($debug) {
	    print STDERR "    " x $recursive;
	    print STDERR "[ @$r ]\n";
	}
	push(@r, @$r);
    }

    @r = sort @r;

    return($#r >= 0 ?  \@r : [ $key ]);
}


#
# debug
#
if ($0 eq __FILE__) {
    my $alias_file = $ENV{ ALIASES } || croak("specify env ALIASES=\$FILE $0");
    my $alias      = new FML::Sys::Alias;
    $alias->read_alias_file( $alias_file );

    my $buf;
    while ($buf = <>) {
	if ($buf =~ /^\#/o) {
	    print $buf;
	}
	else {
	    chomp $buf;

	    my ($k, $v) = split(/\s+/, $buf);
	    my $a = $alias->expand($v);
	    printf "%-20s %s\n", $k, join(" ", @$a);
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Sys::Alias appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
