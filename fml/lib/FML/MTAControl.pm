#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MTAControl.pm,v 1.17 2003/01/11 16:05:13 fukachan Exp $
#

package FML::MTAControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::MTAControl::Postfix;
use FML::MTAControl::Qmail;
use FML::MTAControl::Procmail;
use FML::MTAControl::Sendmail;
use FML::MTAControl::Utils;
@ISA = qw(FML::MTAControl::Postfix
	  FML::MTAControl::Qmail
	  FML::MTAControl::Procmail
	  FML::MTAControl::Sendmail
	  FML::MTAControl::Utils
	  );

my $debug = 0;


=head1 NAME

FML::MTAControl - utilities to handle MTA specific configurations

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

    $args = {
	mta_type => 'postfix',
    };

C<mta_type> is one of
    C<postfix>,
    C<qmail>
and
    C<procmail>.

=cut


my $default_mta = 'postfix';


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # default mta is postfix.
    $me->{ mta_type } = $args->{ mta_type } || $default_mta;

    return bless $me, $type;
}


# Descriptions: $mta_type is valid or not.
#    Arguments: OBJ($self) STR($mta_type)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_valid_mta_type
{
    my ($self, $mta_type) = @_;

    if ($mta_type eq 'postfix'  ||
	$mta_type eq 'qmail'    ||
	$mta_type eq 'sendmail' ||
	$mta_type eq 'procmail') {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: install configuration template files
#    Arguments: OBJ($self)
#               HASH_REF($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_setup";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: update alias.db from alias file
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_update_alias";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: find key in alias maps
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };
    my $key      = $optargs->{ key };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_find_key_in_alias_maps";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: return aliases as HASH_REF
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_get_aliases_as_hash_ref";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: install alias file
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_install_alias";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: remove entry in alias maps
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_remove_alias";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: install/update virtual map file
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_install_virtual_map";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: remove entry in virtual maps
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub remove_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_remove_virtual_map";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: update virtual_map
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update virtual_map
# Return Value: none
sub update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $mta_type = $optargs->{ mta_type } || $self->{ mta_type };

    if ($self->is_valid_mta_type($mta_type)) {
	my $method = "${mta_type}_update_virtual_map";
	$self->$method($curproc, $params, $optargs);
    }
    else {
	croak("unknown MTA");
    }
}


# Descriptions: install file $to dst with variable expansion of $src
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


# Descriptions: remove the specified entry in the postfix style map
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
#               HASH_REF($p)
# Side Effects: update virtual_map
# Return Value: none
sub _remove_postfix_style_virtual
{
    my ($self, $curproc, $params, $optargs, $p) = @_;
    my $removed = 0;
    my $key     = $p->{ key };

    use File::Spec;
    my $virtual     = $p->{ map };
    my $virtual_new = $virtual . 'new'. $$;

    if (-f $virtual) {
	print STDERR "removing $key in $virtual\n";
    }
    else {
	return;
    }

    use FileHandle;
    my $rh = new FileHandle $virtual;
    my $wh = new FileHandle "> $virtual_new";
    if (defined $rh && defined $wh) {
      LINE:
	while (<$rh>) {
	    if (/\<VIRTUAL\s+$key\@/ .. /\<\/VIRTUAL\s+$key\@/) {
		$removed++;
		next LINE;
	    }

	    print $wh $_;
	}
	$wh->close;
	$rh->close;

	if ($removed > 3) {
	    if (rename($virtual_new, $virtual)) {
		print STDERR "\tremoved.\n";
	    }
	    else {
		print STDERR "\twarning: fail to rename virtual files.\n";
	    }
	}
    }
    else {
	warn("cannot open $virtual")     unless defined $rh;
	warn("cannot open $virtual_new") unless defined $wh;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTAControl first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
