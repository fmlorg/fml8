#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Postfix.pm,v 1.14 2002/12/22 14:22:24 fukachan Exp $
#

package FML::MTAControl::Postfix;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTAControl::Postfix - handle postfix specific configurations

=head1 SYNOPSIS

set up aliases and virtual maps for postfix.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: install new alias entries
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();

    use File::Spec;
    my $alias = $config->{ mail_aliases_file };
    my $src   = File::Spec->catfile($template_dir, 'aliases');
    my $dst   = $alias . "." . $$;

    # update params with considering virtual domain support if needed.
    my $xparams = {};
    for my $k (keys %$params) { $xparams->{ $k } = $params->{ $k };}
    $self->_postfix_rewrite_virtual_params($curproc, $xparams);
    $self->_install($src, $dst, $xparams);

    print STDERR "updating $alias\n";

    # XXX-TODO: we should prepare methods such as $curproc->util->append() ?
    use File::Utils qw(append);
    append($dst, $alias);
    unlink $dst;
}


# Descriptions: remove alias
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config    = $curproc->{ config };
    my $alias     = $config->{ mail_aliases_file };
    my $alias_new = $alias."new.$$";
    my $ml_name   = $params->{ ml_name  };
    my $ml_domain = $params->{ ml_domain };
    my $removed   = 0;

    # update params
    my $xparams = {};
    for my $k (keys %$params) { $xparams->{ $k } = $params->{ $k };}
    $self->_postfix_rewrite_virtual_params($curproc, $xparams);

    my $key = $xparams->{ ml_name };

    print STDERR "removing $key in $alias\n";

    use FileHandle;
    my $rh = new FileHandle $alias;
    my $wh = new FileHandle "> $alias_new";
    if (defined $rh && defined $wh) {
      LINE:
	while (<$rh>) {
	    if (/\<ALIASES\s+$key\@/ .. /\<\/ALIASES\s+$key\@/) {
		$removed++;
		next LINE;
	    }

	    print $wh $_;
	}
	$wh->close;
	$rh->close;

	if ($removed > 3) {
	    if (rename($alias_new, $alias)) {
		print STDERR "\tremoved.\n";
	    }
	    else {
		print STDERR "\twarning: fail to rename alias files.\n";
	    }
	}
    }
    else {
	warn("cannot open $alias")     unless defined $rh;
	warn("cannot open $alias_new") unless defined $wh;
    }
}


# Descriptions: regenerate aliases.db
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_postalias };
    my $alias  = $config->{ mail_aliases_file };

    print STDERR "updating $alias database\n";
    system "$prog $alias";
}


# Descriptions: find key in aliases
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub postfix_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
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
	    $fh->close;
	}
	else {
	    warn("cannot open $map");
	}
    }

    return 0;
}


# Descriptions: get { key => value } in aliases
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub postfix_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
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

  MAP:
    for my $map (@$maps) {
	print STDERR "scan key = $key, map = $map\n" if $debug;

	if ($map =~ /^\w+:/) {
	    print STDERR "* ignored $map\n";
	    next MAP;
	}

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
	    $fh->close;
	}
	else {
	    warn("cannot open $map");
	}
    }

    return $aliases;
}


# Descriptions: return alias_maps as ARRAY_REF
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub postfix_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->{ config };
    my $prog   = $config->{ path_postconf };

    # XXX-TODO: postconf returns $xxx in some cases. we need to expand it.
    my $maps   = `$prog alias_maps`;
    $maps      =~ s/,/ /g;
    $maps      =~ s/\s+hash:/ /g;
    $maps      =~ s/\s+dbm:/ /g;
    $maps      =~ s/^.*=\s*//;
    $maps      =~ s/[\s\n]*$//;

    my (@maps) = split(/\s+/, $maps);
    return \@maps;
}


# Descriptions: install configuration templates
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: create include*
# Return Value: none
sub postfix_setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $ml_home_dir  = $params->{ ml_home_dir };

    use File::Spec;

    my $newml_template_files =
	$config->get_as_array_ref('newml_command_postfix_template_files');
    for my $file (@$newml_template_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir, $file);

	print STDERR "creating $dst\n";
	$self->_install($src, $dst, $params);
    }
}


# Descriptions: rewrite $params
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update $params
# Return Value: none
sub _postfix_rewrite_virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name  };
    my $ml_domain = $config->{ ml_domain };

    unless ($curproc->is_default_domain($ml_domain)) {
	$params->{ ml_name } = "${ml_name}=${ml_domain}";
    }
}


# Descriptions: install postfix virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: install/udpate postfix virtual_maps and the .db
# Return Value: none
sub postfix_install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $config       = $curproc->{ config };
    my $ml_name      = $config->{ ml_name };
    my $ml_domain    = $config->{ ml_domain };
    my $postmap      = $config->{ path_postmap };

    use File::Spec;
    my $virtual = $config->{ postfix_virtual_map_file };
    my $src     = File::Spec->catfile($template_dir, 'postfix_virtual');
    my $dst     = $virtual . "." . $$;
    print STDERR "updating $virtual\n";

    # at the first time
    unless( -f $virtual) {
	use FileHandle;
	my $fh = new FileHandle ">> $virtual";
	if (defined $fh) {
	    print $fh "# $ml_domain is one of \$mydestination\n";
	    print $fh "# CAUTION: DO NOT REMOVE THE FOLLOWING LINE.\n";
	    print $fh "$ml_domain\t$ml_domain\n\n";
	    $fh->close();
	}
    }

    $self->_install($src, $dst, $params);

    use File::Utils qw(append);
    append($dst, $virtual);
    unlink $dst;
}



# Descriptions: remove postfix virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: remove/udpate postfix virtual_maps and the .db
# Return Value: none
sub postfix_remove_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->{ config };
    my $postmap = $config->{ path_postmap };
    my $key     = $params->{ ml_name };
    my $removed = 0;

    use File::Spec;
    my $virtual     = $config->{ postfix_virtual_map_file };
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


# Descriptions: regenerate virtual.db
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->{ config };
    my $postmap = $config->{ path_postmap };
    my $virtual = $config->{ postfix_virtual_map_file };

    if (-f $virtual) {
	print STDERR "updating $virtual database\n";
	system "$postmap $virtual";
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
