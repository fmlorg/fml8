#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.13 2004/04/18 05:59:44 fukachan Exp $
#

package FML::Process::CGI::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::CGI::Utils - utility for FML::Process::CGI::Kernel.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: return $ml_name, which varies with the cgi_mode.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_ml_name
{
    my ($curproc) = @_;
    my $cgi_mode  = $curproc->cgi_var_cgi_mode();

    if ($cgi_mode eq 'admin') {
	return $curproc->cgi_try_get_ml_name();
    }
    else {
	my $hints = $curproc->hints();
	return $hints->{ ml_name };
    }
}


# Descriptions: return $ml_domain defined in *.cgi programd.
#               ml_domain is hard-coded, not dependent on cgi_var_cgi_mode.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_ml_domain
{
    my ($curproc) = @_;
    my $hints     = $curproc->hints();
    return $hints->{ ml_domain };
}


# Descriptions: return $ml_home_prefix defined in *.cgi program.
#               ml_home_prefix is determined by ml_domain,
#               which is hard-coded, not dependent on cgi_var_cgi_mode.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_ml_home_prefix
{
    my ($curproc) = @_;
    my $ml_domain = $curproc->cgi_var_ml_domain();
    return $curproc->ml_home_prefix( $ml_domain );
}


# Descriptions: return list of ml_name as ARRAY_REF.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub cgi_var_ml_name_list
{
    my ($curproc) = @_;
    my $cgi_mode  = $curproc->cgi_var_cgi_mode();
    my $ml_domain = $curproc->cgi_var_ml_domain();

    if ($cgi_mode eq 'admin') {
	return $curproc->get_ml_list($ml_domain);
    }
    else {
	my $ml_name = $curproc->cgi_var_ml_name();
	return [ $ml_name ];
    }
}


# Descriptions: return address map.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_address_map
{
    my ($curproc)   = @_;
    my $config      = $curproc->config();
    my $_defaultmap = $config->{ cgi_menu_default_address_map };

    return $curproc->safe_param_map() || $_defaultmap;
}


# Descriptions: return list of address map.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub cgi_var_address_map_list
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    return $config->get_as_array_ref('cgi_menu_address_map_select_list');
}


# Descriptions: return my program name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_myname
{
    my ($curproc) = @_;

    return $curproc->myname();
}


# Descriptions: return available command list in cgi mode.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub cgi_var_available_command_list
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $cgi_mode  = $curproc->cgi_var_cgi_mode();

    if ($cgi_mode eq 'admin') {
	return $config->get_as_array_ref('admin_cgi_allowed_commands');
    }
    else {
	# XXX-TODO: commands_for_ml_admin_cgi -> ml_admin_cgi_allowed_commands
	return $config->get_as_array_ref('commands_for_ml_admin_cgi');
    }
}


# Descriptions: return action name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_action
{
    my ($curproc) = @_;
    return $curproc->safe_cgi_action_name();
}


# Descriptions: return frame target name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_frame_target
{
    my ($curproc) = @_;
    return '_top';
}


# Descriptions: return $mode, which is hard-coded in *.cgi program.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_cgi_mode
{
    my ($curproc) = @_;
    my $hints     = $curproc->hints();

    return( $hints->{ cgi_mode } || '' );
}


# Descriptions: return value of language varible.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_language
{
    my ($curproc) = @_;
    my $lang      = $curproc->safe_param_language() || '';

    if ($lang =~ /^(Japanese|English)$/io)  {
	return lc($lang);
    }
    else {
	return '';
    }
}


# Descriptions: return title string.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_navigator_title
{
    my ($curproc) = @_;
    my $fml_url   = $curproc->cgi_var_fml_project_url();
    my $mode      = $curproc->cgi_var_cgi_mode();

    if ($mode eq 'admin') {
	return "<B>$fml_url admin menu</B>\n<BR>";
    }
    else {
	return "<B>$fml_url ml-admin menu</B>\n<BR>";
    }
}


# Descriptions: return fml project url.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_fml_project_url
{
    my ($curproc) = @_;

    return '<A HREF="http://www.fml.org/software/fml-devel/">fml</A>';
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
