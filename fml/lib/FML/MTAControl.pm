#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MTAControl.pm,v 1.3 2002/04/25 04:40:03 fukachan Exp $
#

package FML::MTAControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTAControl - postfix utilities

=head1 SYNOPSIS

   nothing implemented yet.

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

    $args = {
	mta_type => 'postfix',
    };

C<postfix> as C<mta_type> is available now.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # default values
    $me->{ mta_type } =
	defined $args->{ mta_type } ? $args->{ mta_type } : 'postfix';

    return bless $me, $type;
}


# Descriptions: update alias
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub update_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };

    if ($mta_type eq 'postfix') {
	$self->postfix_update_alias($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: update alias
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_update_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_postalias };
    my $maps   = $optargs->{ alias_maps };

    for my $alias (@$maps) {
	system "$prog $alias";
    }
}


# Descriptions: find key
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub find_key_in_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };
    my $key      = $optargs->{ key };

    if ($mta_type eq 'postfix') {
	$self->postfix_find_key_in_alias($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: find key
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub get_aliases_as_hash_ref
{
    my ($self, $curproc, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };

    if ($mta_type eq 'postfix') {
	$self->postfix_get_aliases_as_hash_ref($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: find key in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub postfix_find_key_in_alias
{
    my ($self, $curproc, $optargs) = @_;
    my $key  = $optargs->{ key };
    my $maps = $self->postfix_alias_maps($curproc, $optargs);

    for my $map (@$maps) {
	print STDERR "scan key = $key, map = $map\n" if $debug;

	use FileHandle;
	my $fh = new FileHandle $map;
	if (defined $fh) {
	    while (<$fh>) {
		return 1 if /^$key:/;
	    }
	}
	else {
	    warn("cannot open $map");
	}
	$fh->close;
    }

    return 0;
}


# Descriptions: get { key => value } in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub postfix_get_aliases_as_hash_ref
{
    my ($self, $curproc, $optargs) = @_;
    my $config     = $curproc->{ config };
    my $alias_file = $config->{ mail_aliases_file };
    my $key        = $optargs->{ key };
    my $mode       = $optargs->{ mode };
    my $maps       = $self->postfix_alias_maps($curproc, $optargs);
    my $aliases    = {};

    # $0 -n shows fml only aliases
    if ($mode eq 'fmlonly') {
	$maps = [ $alias_file ];
    }

    for my $map (@$maps) {
	print STDERR "scan key = $key, map = $map\n" if $debug;

	use FileHandle;
	my $fh = new FileHandle $map;
	if (defined $fh) {
	    my ($key, $value);

	  LINE:
	    while (<$fh>) {
		next LINE if /^#/;
		next LINE if /^\s*$/;

		chomp;
		($key, $value)   = split(/:/, $_, 2);
		$value =~ s/^\s*//;
		$value =~ s/s*$//;
		$aliases->{ $key } = $value;
	    }
	}
	else {
	    warn("cannot open $map");
	}
	$fh->close;
    }

    return $aliases;
}


# Descriptions: return alias_maps as ARRAY_REF
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub postfix_alias_maps
{
    my ($self, $curproc, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_postconf };


    my $maps   = `$prog alias_maps`;
    $maps      =~ s/\s+\w+:/ /g;
    $maps      =~ s/^.*=\s*//;
    chomp $maps;

    my (@maps) = split(/\s+/, $maps);
    return \@maps;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTAControl appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
