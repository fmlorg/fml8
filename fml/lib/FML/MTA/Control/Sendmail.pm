#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Sendmail.pm,v 1.7 2005/08/17 10:44:47 fukachan Exp $
#

package FML::MTA::Control::Sendmail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTA::Control::Sendmail - handle sendmail specific configurations.

=head1 SYNOPSIS

set up aliases and virtual maps for sendmail.

=head1 DESCRIPTION

=head1 METHODS

=cut

# BUGS
#XXX-TODO: We should check "Tfml" in sendmail.cf in installation.


# Descriptions: install new alias entries.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_install_alias($curproc, $params, $optargs);
}


# Descriptions: remove alias.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_delete_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_delete_alias($curproc, $params, $optargs);
}


# Descriptions: regenerate aliases.db.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $prog   = $config->{ path_sendmail };
    my $alias  = $config->{ mail_aliases_file };

    $curproc->ui_message("updating $alias database");
    if (-x $prog) {
	system "$prog -bi -oA$alias";
    }
    else {
	warn("sendmail='$prog' not found");
    }
}


# Descriptions: find key in aliases.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub sendmail_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_find_key_in_alias_maps($curproc, $params, $optargs);
}


# Descriptions: get { key => value } in aliases.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub sendmail_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_get_aliases_as_hash_ref($curproc, $params, $optargs);
}


# Descriptions: return alias_maps as ARRAY_REF.
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


# Descriptions: install configuration templates.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: create include*
# Return Value: none
sub sendmail_setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    $self->postfix_setup($curproc, $params, $optargs);
}


# Descriptions: rewrite $params.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update $params
# Return Value: none
sub _sendmail_rewrite_virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;

    # XXX-TODO remove this.
}


# Descriptions: install sendmail virtual_maps.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: install/udpate sendmail virtual_maps and the .db
# Return Value: none
sub sendmail_install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $config       = $curproc->config();
    my $ml_name      = $config->{ ml_name };
    my $ml_domain    = $config->{ ml_domain };

    use File::Spec;
    my $virtual = $config->{ sendmail_virtual_map_file };
    my $src     = File::Spec->catfile($template_dir, 'postfix_virtual');
    my $dst     = sprintf("%s.%s", $virtual, $$);
    $curproc->ui_message("updating $virtual");

    # at the first time
    unless( -f $virtual) {
	use FileHandle;
	my $fh = new FileHandle ">> $virtual";
	if (defined $fh) {
	    print $fh "#\n";
	    print $fh "# you need to specify $ml_domain ";
	    print $fh "as a destination (Class w) in sendmail.cf.\n";
	    print $fh "# For example, Cwlocalhost $ml_domain ...\n";
	    print $fh "#\n";
	    $fh->close();
	}
    }

    $self->_install($src, $dst, $params);

    $curproc->append($dst, $virtual);
    unlink $dst;
}



# Descriptions: remove sendmail virtual_maps.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: remove/udpate sendmail virtual_maps and the .db
# Return Value: none
sub sendmail_delete_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $map    = $config->{ sendmail_virtual_map_file };
    my $key    = $params->{ ml_name };
    my $p      = {
	key => $key,
	map => $map,
    };
    $self->delete_postfix_style_virtual($curproc, $params, $optargs, $p);
}


# Descriptions: regenerate virtual.db.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub sendmail_update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->config();
    my $makemap = $config->{ path_makemap };
    my $virtual = $config->{ sendmail_virtual_map_file };

    if (-f $virtual) {
	$curproc->ui_message("updating $virtual database");

	# XXX-TODO: oops, hash HARD CODED.
	if (-x $makemap) {
	    system "$makemap hash $virtual < $virtual";
	}
	else {
	    warn("makemap='$makemap' not found");
	}
    }
}


=head1 UTILITIES

=head2 sendmail_supported_map_types

get map types supported by makemap.

=cut


# Descriptions: get map types supported by makemap.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub sendmail_supported_map_types
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->config();
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

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTA::Control first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
