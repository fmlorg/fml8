#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Postfix.pm,v 1.7 2005/05/26 12:22:33 fukachan Exp $
#

package FML::MTA::Control::Postfix;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTA::Control::Postfix - handle postfix specific configurations.

=head1 SYNOPSIS

set up aliases and virtual maps for postfix.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: install new alias entries.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->config();
    my $template_dir = $curproc->newml_command_template_files_dir();

    use File::Spec;
    my $alias = $config->{ mail_aliases_file };
    my $src   = File::Spec->catfile($template_dir, 'aliases');
    my $dst   = sprintf("%s.%s", $alias, $$);

    # update params with considering virtual domain support if needed.
    my $xparams = {};
    for my $k (keys %$params) { $xparams->{ $k } = $params->{ $k };}
    $self->_postfix_rewrite_virtual_params($curproc, $xparams);
    $self->_install($src, $dst, $xparams);

    $curproc->ui_message("updating $alias");
    $curproc->append($dst, $alias);
    unlink $dst;
}


# Descriptions: remove alias.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config    = $curproc->config();
    my $alias     = $config->{ mail_aliases_file };
    my $alias_new = sprint("%s.%s.%s", $alias, "new", $$);
    my $ml_name   = $params->{ ml_name  };
    my $ml_domain = $params->{ ml_domain };
    my $removed   = 0;

    # update params
    my $xparams = {};
    for my $k (keys %$params) { $xparams->{ $k } = $params->{ $k };}
    $self->_postfix_rewrite_virtual_params($curproc, $xparams);

    my $key = $xparams->{ ml_name };

    $curproc->ui_message("removing $key in $alias");

    use FileHandle;
    my $rh = new FileHandle $alias;
    my $wh = new FileHandle "> $alias_new";
    if (defined $rh && defined $wh) {
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    if ($buf =~ /\<ALIASES\s+$key\@/
		   ..
		$buf =~ /\<\/ALIASES\s+$key\@/) {
		$removed++;
		next LINE;
	    }

	    print $wh $buf;
	}
	$wh->close;
	$rh->close;

	if ($removed > 3) {
	    if (rename($alias_new, $alias)) {
		$curproc->ui_message("removed");
	    }
	    else {
		my $s = "fail to rename alias files";
		$curproc->ui_message("error: $s");
		$curproc->logerror($s);
	    }
	}
    }
    else {
	warn("cannot open $alias")     unless defined $rh;
	warn("cannot open $alias_new") unless defined $wh;
    }
}


# Descriptions: regenerate aliases.db.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $prog   = $config->{ path_postalias };
    my $alias  = $config->{ mail_aliases_file };

    $curproc->ui_message("updating $alias database");
    if (-x $prog) {
	system "$prog $alias";
    }
    else {
	warn("postalias='$prog' not found");
    }
}


# Descriptions: find key in aliases.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub postfix_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $map    = $config->{ mail_aliases_file };
    my $maps   = $self->postfix_alias_maps($curproc, $optargs);

    # default domain
    my $key    = $optargs->{ key };
    my $domain = $params->{ ml_domain };

    # virtual domain
    my $xparams = {};
    for my $k (keys %$params) { $xparams->{ $k } = $params->{ $k };}
    $self->_postfix_rewrite_virtual_params($curproc, $xparams);
    my $key_virtual = $xparams->{ ml_name };

    # search
    for my $map (@$maps, $map) {
	if ($debug) {
	    $curproc->ui_message("scan key = $key/$key_virtual, map = $map");
	}

	# default domain case
	if ($curproc->is_default_domain($domain)) {
	    $curproc->ui_message("search $key (default domain)") if $debug;
	    if ($self->_find_key_in_file($map, $key)) {
		$curproc->ui_message("\tkey=$key found") if $debug;
		return 1;
	    }
	}
	# virtual domain case
	else {
	    if ($debug) {
		$curproc->ui_message("search $key_virtual (virtual domain)");
	    }
	    if ($self->_find_key_in_file($map, $key_virtual)) {
		$curproc->ui_message("key=$key_virtual found") if $debug;
		return 1;
	    }
	}
    }

    return 0;
}


# Descriptions: search key in the specifiled file.
#    Arguments: OBJ($self) STR($map) STR($key)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _find_key_in_file
{
    my ($self, $map, $key) = @_;
    my $found = 0;

    unless (-f $map) { return 0;}

    use FileHandle;
    my $fh = new FileHandle $map;

    if (defined $fh) {
	my $buf;

      LINE:
	while ($buf = <$fh>) {
	    if ($buf =~ /^$key:/) {
		$found = 1;
		last LINE;
	    }
	}
	$fh->close;
    }
    else {
	warn("cannot open $map");
    }

    return $found;
}



# Descriptions: get aliases info as HASH_REF.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub postfix_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config     = $curproc->config();
    my $alias_file = $config->{ mail_aliases_file };
    my $key        = $optargs->{ key };
    my $mode       = $optargs->{ mode };
    my $maps       = $self->postfix_alias_maps($curproc, $optargs);
    my $aliases    = {};

    # $0 -n shows fml only aliases
    if ($mode eq 'fmlonly') {
	my $_alias_file = $alias_file;
	$_alias_file =~ s/^\s*\w+://;
	$_alias_file =~ s/\s*$//;
	$maps = [ $_alias_file ];
    }

  MAP:
    for my $map (@$maps) {
	$curproc->ui_message("scan key = $key, map = $map") if $debug;

	# XXX this map has no prefix such as file:, hash:, dbm:, ... 
	if ($map =~ /^\w+:/) {
	    $curproc->ui_message("* ignored $map");
	    next MAP;
	}

	use FileHandle;
	my $fh = new FileHandle $map;
	if (defined $fh) {
	    my ($key, $value, $buf);

	  LINE:
	    while ($buf = <$fh>) {
		next LINE if $buf =~ /^#/o;
		next LINE if $buf =~ /^\s*$/o;

		chomp $buf;
		($key, $value) = split(/:/, $buf, 2);
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


# Descriptions: return alias_maps as ARRAY_REF.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub postfix_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $prog   = $config->{ path_postconf };
    my $maps   = '';

    # XXX-TODO: postconf returns $xxx in some cases. we need to expand it.
    if (-x $prog) {
	$maps = `$prog alias_maps`;
	$maps =~ s/,/ /g;
	$maps =~ s/\s+hash:/ /g;
	$maps =~ s/\s+dbm:/ /g;
	$maps =~ s/^.*=\s*//;
	$maps =~ s/[\s\n]*$//;
    }
    else {
	warn("postconf='$prog' not found");
    }

    my (@maps) = split(/\s+/, $maps);
    return \@maps;
}


# Descriptions: install configuration templates.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: create include*
# Return Value: none
sub postfix_setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->config();
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $ml_home_dir  = $params->{ ml_home_dir };

    use File::Spec;

    my $newml_template_files =
	$config->get_as_array_ref('newml_command_postfix_template_files');
    for my $file (@$newml_template_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir, $file);

	$curproc->ui_message("creating $dst");
	$self->_install($src, $dst, $params);
    }
}


# Descriptions: rewrite $params.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update $params
# Return Value: none
sub _postfix_rewrite_virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config    = $curproc->config();
    my $ml_name   = $config->{ ml_name  };
    my $ml_domain = $config->{ ml_domain };

    unless ($curproc->is_default_domain($ml_domain)) {
	$params->{ ml_name } = "${ml_name}=${ml_domain}";
    }
}


# Descriptions: install postfix virtual_maps.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: install/udpate postfix virtual_maps and the .db
# Return Value: none
sub postfix_install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $config       = $curproc->config();
    my $ml_name      = $config->{ ml_name };
    my $ml_domain    = $config->{ ml_domain };
    my $postmap      = $config->{ path_postmap };

    use File::Spec;
    my $virtual = $config->{ postfix_virtual_map_file };
    my $src     = File::Spec->catfile($template_dir, 'postfix_virtual');
    my $dst     = sprintf("%s.%s", $virtual, $$);
    $curproc->ui_message("updating $virtual");

    # create a virtual file for each domain at the first time.
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

    $curproc->append($dst, $virtual);
    unlink $dst;
}



# Descriptions: remove postfix virtual_maps.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: remove/udpate postfix virtual_maps and the .db
# Return Value: none
sub postfix_remove_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config = $curproc->config();
    my $map    = $config->{ postfix_virtual_map_file };
    my $key    = $params->{ ml_name };
    my $p      = {
	key => $key,
	map => $map,
    };

    $self->remove_postfix_style_virtual($curproc, $params, $optargs, $p);
}


# Descriptions: regenerate virtual.db.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub postfix_update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config  = $curproc->config();
    my $postmap = $config->{ path_postmap };
    my $virtual = $config->{ postfix_virtual_map_file };

    if (-f $virtual) {
	$curproc->ui_message("updating $virtual database");
	if (-x $postmap) {
	    system "$postmap $virtual";
	}
	else {
	    warn("postmap='$postmap' not found");
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::MTA::Control first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
