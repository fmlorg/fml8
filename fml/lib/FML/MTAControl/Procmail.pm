#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Procmail.pm,v 1.6 2003/02/11 11:04:44 fukachan Exp $
#

package FML::MTAControl::Procmail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTAControl::Procmail - handle procmail specific configurations

=head1 SYNOPSIS

set up aliases and virtual maps for procmail.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: install new alias entries
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub procmail_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();

    use File::Spec;
    my $alias = $config->{ procmail_aliases_file };
    my $src   = File::Spec->catfile($template_dir, 'procmailrc');
    my $dst   = $alias . "." . $$;

    $self->_install($src, $dst, $params);

    print STDERR "updating $alias\n";

    use File::Utils qw(append);
    append($dst, $alias);
    unlink $dst;
}


# Descriptions: remove alias
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub procmail_remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config    = $curproc->{ config };
    my $alias     = $config->{ procmail_aliases_file };
    my $alias_new = $alias."new.$$";
    my $ml_name   = $params->{ ml_name  };
    my $ml_domain = $params->{ ml_domain };
    my $removed   = 0;

    my $key = $params->{ ml_name };

    print STDERR "removing $key in $alias\n";

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
sub procmail_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;

}


# Descriptions: find key in aliases
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub procmail_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $key  = $optargs->{ key };
    my $maps = $self->procmail_alias_maps($curproc, $optargs);

    for my $map (@$maps) {
	print STDERR "scan key = $key, map = $map\n" if $debug;

	use FileHandle;
	my $fh = new FileHandle $map;
	if (defined $fh) {
	    my $buf;
	    while ($buf = <$fh>) {
		return 1 if $buf =~ /^$key:/;
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
sub procmail_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config     = $curproc->{ config };
    my $alias_file = $config->{ mail_aliases_file };
    my $key        = $optargs->{ key };
    my $mode       = $optargs->{ mode };
    my $maps       = $self->procmail_alias_maps($curproc, $optargs);
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
	    my ($buf, $key, $value);

	  LINE:
	    while ($buf = <$fh>) {
		next LINE if $buf =~ /^#/;
		next LINE if $buf =~ /^\s*$/;

		chomp $buf;
		($key, $value)   = split(/:/, $buf, 2);
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
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub procmail_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;

    return [];
}


# Descriptions: install configuratin templates
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: create include*
# Return Value: none
sub procmail_setup
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


#
# XXX-TODO: how to handle procmail virtual maps ?
#


# Descriptions: rewrite $params
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update $params
# Return Value: none
sub _procmail_rewrite_virtual_params
{
    my ($self, $curproc, $params, $optargs) = @_;

}


# Descriptions: install procmail virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: install/udpate procmail virtual_maps and the .db
# Return Value: none
sub procmail_install_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;

}



# Descriptions: remove procmail virtual_maps
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: remove/udpate procmail virtual_maps and the .db
# Return Value: none
sub procmail_remove_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;

}


# Descriptions: regenerate virtual.db
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($params) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub procmail_update_virtual_map
{
    my ($self, $curproc, $params, $optargs) = @_;

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
