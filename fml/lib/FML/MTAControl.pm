#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MTAControl.pm,v 1.5 2002/05/24 06:39:38 fukachan Exp $
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

    _update_isa($me);

    return bless $me, $type;
}


sub _update_isa
{
    my ($self, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };

    if ($mta_type eq 'postfix') {
	eval q{ 
	    use FML::MTAControl::Postfix;
	    push(@ISA, qw(FML::MTAControl::Postfix));
	};
	croak($@) if $@;
    }
    elsif ($mta_type eq 'qmail') {
	eval q{ 
	    use FML::MTAControl::Qmail;
	    push(@ISA, qw(FML::MTAControl::Qmail));
	};
	croak($@) if $@;
    }
}


# Descriptions: install configuration temaplate alias
#    Arguments: OBJ($self) 
#               HASH_REF($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };

    if ($mta_type eq 'postfix' || $mta_type eq 'qmail') {
	my $method = "${mta_type}_setup";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
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

    if ($mta_type eq 'postfix' || $mta_type eq 'qmail') {
	my $method = "${mta_type}_update_alias";
	$self->$method($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
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

    if ($mta_type eq 'postfix' || $mta_type eq 'qmail') {
	my $method = "${mta_type}_find_key_in_alias";
	$self->$method($curproc, $optargs);
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

    if ($mta_type eq 'postfix' || $mta_type eq 'qmail') {
	my $method = "${mta_type}_get_aliases_as_hash_ref";
	$self->$method($curproc, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: install configuration temaplate alias
#    Arguments: OBJ($self) 
#               HASH_REF($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type =
	defined $optargs->{ mta_type } ? $optargs->{ mta_type } :
	    $self->{ mta_type };

    if ($mta_type eq 'postfix' || $mta_type eq 'qmail') {
	my $method = "${mta_type}_virtual_params";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: install file $dst with variable expansion of $src
#    Arguments: OBJ($self) STR($src) STR($dst) HASH_REF($config)
# Side Effects: create $dst
# Return Value: none
sub _install
{
    my ($self, $src, $dst, $config) = @_;

    eval q{
	use FML::Config::Convert;
	&FML::Config::Convert::convert_file($src, $dst, $config);
    };
    croak($@) if $@;
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
