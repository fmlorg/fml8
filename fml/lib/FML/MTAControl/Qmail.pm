#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Qmail.pm,v 1.3 2002/05/27 08:53:24 fukachan Exp $
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
sub qmail_update_alias
{
    my ($self, $curproc, $optargs) = @_;
}


# Descriptions: find key in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub qmail_find_key_in_alias
{
    my ($self, $curproc, $optargs) = @_;
}


# Descriptions: get { key => value } in aliases
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: HASH_REF
sub qmail_get_aliases_as_hash_ref
{
    my ($self, $curproc, $optargs) = @_;
}


# Descriptions: return alias_maps as ARRAY_REF
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: ARRAY_REF
sub qmail_alias_maps
{
    my ($self, $curproc, $optargs) = @_;
}



# Descriptions: install configuratin templates
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($optargs)
# Side Effects: creates ~/.qmail-XXX
# Return Value: none
sub qmail_setup
{
    my ($self, $curproc, $params) = @_;
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

    my $virtual_domain_conf = $config->{ qmail_control_virtualdomains_file };
    unless (-f $virtual_domain_conf) {
	print STDERR "  XXX We assume $ml_domain:fml-$ml_domain\n"; 
	print STDERR "  XXX in $virtual_domain_conf\n";
	print STDERR "  XXX\n";
    }

}


# Descriptions: dummy
#    Arguments: none
# Side Effects: none
# Return Value: none
sub qmail_virtual_params
{
    ;
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
