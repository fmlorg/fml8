#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package FML::MTAControl::Sendmail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTAControl::Sendmail - handle sendmail specific configurations

=head1 SYNOPSIS

set up aliases and virtual maps for sendmail.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: install new alias entries
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_install_alias($curproc, $params, $optargs);
}


# Descriptions: remove alias
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_remove_alias($curproc, $params, $optargs);
}


# Descriptions: regenerate aliases.db
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_sendmail };
    my $alias  = $config->{ mail_aliases_file };

    print STDERR "updating $alias database\n";
    system "$prog -bi -oA$alias";
}


# Descriptions: find key in aliases
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub sendmail_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_find_key_in_alias_maps($curproc, $params, $optargs);
}


# Descriptions: get { key => value } in aliases
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub sendmail_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_get_aliases_as_hash_ref($curproc, $params, $optargs);
}


# Descriptions: return alias_maps as ARRAY_REF
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub sendmail_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;

    # XXX-TODO: NOT IMPLEMENTED.

    return [];
}


# Descriptions: install configuration templates
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: create include*
# Return Value: none
sub sendmail_setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_setup($curproc, $params, $optargs);
}


# Descriptions: rewrite $params
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update $params
# Return Value: none
sub _sendmail_rewrite_virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;

    # XXX-TODO remove this.
}


# Descriptions: install sendmail virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: install/udpate sendmail virtual_maps and the .db
# Return Value: none
sub sendmail_install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $config       = $curproc->{ config };
    my $ml_name      = $config->{ ml_name };
    my $ml_domain    = $config->{ ml_domain };
    my $postmap      = $config->{ path_postmap };

    use File::Spec;
    my $virtual = $config->{ sendmail_virtual_map_file };
    my $src     = File::Spec->catfile($template_dir, 'postfix_virtual');
    my $dst     = $virtual . "." . $$;
    print STDERR "updating $virtual\n";

    # at the first time
    unless( -f $virtual) {
	use FileHandle;
	my $fh = new FileHandle ">> $virtual";
	if (defined $fh) {
	    print $fh "#\n";
	    print $fh "# you need to specify $ml_domain ";
	    print $fh "as a destination in sendmail.cf.\n";
	    print $fh "#\n";
	    $fh->close();
	}
    }

    $self->_install($src, $dst, $params);

    use File::Utils qw(append);
    append($dst, $virtual);
    unlink $dst;
}



# Descriptions: remove sendmail virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: remove/udpate sendmail virtual_maps and the .db
# Return Value: none
sub sendmail_remove_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->{ config };
    my $map     = $config->{ sendmail_virtual_map_file };
    my $key     = $params->{ ml_name };
    my $p       = {
	key => $key,
	map => $map,
    };
    $self->_remove_postfix_style_virtual($curproc, $params, $optargs, $p);
}


# Descriptions: regenerate virtual.db
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->{ config };
    my $makemap = $config->{ path_makemap };
    my $virtual = $config->{ sendmail_virtual_map_file };

    # XXX-TODO: NOT IMPLEMENTED
    if (-f $virtual) {
	print STDERR "updating $virtual database\n";
	system "$makemap hash $virtual < $virtual";
    }
}


=head1 UTILITIES

=head2 sendmail_supported_map_types

get map types supported by makemap.

=cut


# Descriptions: get map types supported by makemap
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub sendmail_supported_map_types
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->{ config };
    my $makemap = $config->{ path_makemap };

    if (-x $makemap) {
	my $buf = `$makemap -l`;
	chomp $buf;

	my @maps = split(/\s+/, $buf);
	return \@maps;
    }
    else {
	return [];
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTAControl first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
