#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.21 2003/08/25 14:13:59 fukachan Exp $
#

package FML::Process::CGI::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::CGI::Utils - utility for FML::Process::CGI::Kernel

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


# Descriptions: return $ml_domain defined in *.cgi programd .
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


sub cgi_var_myname
{
    my ($curproc) = @_;

    return $curproc->myname();
}


sub cgi_var_available_command_list
{
    my ($curproc) = @_;
    my $config = $curproc->config();
    my $cgi_mode  = $curproc->cgi_var_cgi_mode();

    if ($cgi_mode eq 'admin') {
	return $config->get_as_array_ref('commands_for_admin_cgi');
    }
    else {
	return $config->get_as_array_ref('commands_for_ml_admin_cgi');
    }
}


# Descriptions: return $mode, which is hard-coded in *.cgi program.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_var_cgi_mode
{
    my ($curproc) = @_;
    my $hints     = $curproc->hints();

    return $hints->{ cgi_mode };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
