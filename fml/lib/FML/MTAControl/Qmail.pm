#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Qmail.pm,v 1.8 2002/06/30 14:30:15 fukachan Exp $
#

package FML::MTAControl::Qmail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::MTAControl - qmail utilities

=head1 SYNOPSIS

   nothing implemented yet.

=head1 DESCRIPTION

=head1 METHODS

=head2 new($args)

    $args = {
	mta_type => 'qmail',
    };

C<qmail> as C<mta_type> is available now.

=cut


# Descriptions: update alias
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub qmail_install_alias
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: update alias
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub qmail_remove_alias
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: update alias
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: update aliases
# Return Value: none
sub qmail_update_alias
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: find key in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub qmail_find_key_in_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: get { key => value } in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub qmail_get_aliases_as_hash_ref
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: return alias_maps as ARRAY_REF
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub qmail_alias_maps
{
    my ($self, $curproc, $params, $optargs) = @_;

    0;
}


# Descriptions: install configuratin templates
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: creates ~/.qmail-XXX
# Return Value: none
sub qmail_setup
{
    my ($self, $curproc, $params, $optargs) = @_;
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $ml_home_dir  = $params->{ ml_home_dir };

    use File::Spec;

    my $qmail_template_files =
	$config->get_as_array_ref('newml_command_qmail_template_files');
    my $fml_owner_home_dir = $config->{ fml_owner_home_dir };
    my $ml_name   = $config->{ ml_name };
    my $ml_domain = $config->{ ml_domain }; $ml_domain =~ s/\./:/g;
    for my $file (@$qmail_template_files) {
	my $xfile = $file;
	$xfile =~ s/dot-/\./;
	$xfile =~ s/dot-/\./;
	$xfile =~ s/qmail/qmail-$ml_domain-$ml_name/;

	my $src   = File::Spec->catfile($template_dir, $file);
	my $dst   = File::Spec->catfile($fml_owner_home_dir, $xfile);

	print STDERR "creating $dst\n";
	$self->_install($src, $dst, $params);
    }

    my $virtual_domain_conf = $config->{ qmail_virtualdomains_file };
    unless (-f $virtual_domain_conf) {
	if (0) {
	    print STDERR "  XXX We assume $ml_domain:fml-$ml_domain\n";
	    print STDERR "  XXX in $virtual_domain_conf\n";
	    print STDERR "  XXX\n";
	}
    }

}


# Descriptions: prepare a template for qmail/control/virtualdomains
#               for example: rule of a virtual domain for "nuinui.net"
#                            nuinui.net:fml-.nuinui.net
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params)
#         bugs: we cannot update /var/qmail/control/virtualdomains
#               since it needs root priviledge.
#               So, we can only update our templates for qmail.
# Side Effects: update template not /var/qmail/control/virtualdomains
# Return Value: none
sub qmail_install_virtual_map
{
    my ($self, $curproc, $params) = @_;
    my $fmlowner     = $curproc->fml_owner();
    my $config       = $curproc->{ config };
    my $ml_domain    = $config->{ ml_domain };
    my $virtual      = $config->{ qmail_virtual_map_file };

    # 1. check the current temlate file firstly
    my $found = 0;
    my $fh    = new FileHandle $virtual;
    if (defined $fh) {
	while (<$fh>) {
	    $found = 1 if /^$ml_domain:/i;
	}
	$fh->close();
    }

    # 2. if not found
    unless ($found) {
	print STDERR "updating $virtual\n";

	my $fh = new FileHandle ">> $virtual";
	if (defined $fh) {
	    print $fh "$ml_domain:$fmlowner-$ml_domain\n";
	    $fh->close();
	}
    }
    else {
	print STDERR "skipping $virtual\n";
    }
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub qmail_remove_virtual_map
{
    0;
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub qmail_update_virtual_map
{
    0;
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
