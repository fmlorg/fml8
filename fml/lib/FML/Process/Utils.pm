#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.16 2002/03/20 03:20:45 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Process::Utils - small utilities for FML::Process::

=head1 SYNOPSIS

See FML::Process::Kernel.

=head1 DESCRIPTION

=head1 METHODS

=head2 fml_version()

return fml version.

=head2 fml_owner()

return fml owner.

=head2 fml_group()

return fml group.

=head2 myname()

return current process name.

=head2 command_line_raw_argv()

@ARGV before getopts() analyze.

=head2 command_line_argv()

@ARGV after getopts() analyze.

=head2 command_line_argv_find(pat)

search pattern in @ARGV and return it if found.

=head2 command_line_options()

return options, result of getopts() analyze.

=cut


# Descriptions: return fml version
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_version
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_version };
}


# Descriptions: return fml owner
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_owner
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_owner };
}


# Descriptions: return fml group
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub fml_group
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ main_cf }->{ fml_group };
}


# Descriptions: return current process name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


# Descriptions: return raw @ARGV of current process,
#               where @ARGV is before getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


# Descriptions: return @ARGV of current process,
#               where @ARGV is after getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


# Descriptions: search string matched with specified pattern and
#               return it.
#    Arguments: OBJ($curproc) STR($pat)
# Side Effects: none
# Return Value: STR or UNDEF
sub command_line_argv_find
{
    my ($curproc, $pat) = @_;
    my $argv = $curproc->command_line_argv();

    if (defined $pat) {
	for my $x (@$argv) {
	    if ($x =~ /^$pat/) {
		return $1;
	    }
	}
    }

    return undef;
}


# Descriptions: options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


=head2 ml_domain()

not yet implemenetd properly.
Anyway, return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return my domain
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_domain
{
    my ($curproc) = @_;
    return $curproc->default_domain();
}


=head2 default_domain()

return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return the default domain defined in /etc/fml/main.cf.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub default_domain
{
    my ($curproc, $domain) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_domain };
}


=head2 executable_prefix()

return executable prefix such as "/usr/local".

=cut


# Descriptions: return the path for executables
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub executable_prefix
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ executable_prefix };
}


=head2 template_files_dir_for_newml()

=cut


# Descriptions: return the path where template files used in "newml" method exist
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub template_files_dir_for_newml
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ default_config_dir };
}


=head2 ml_home_prefix([domain])

return $ml_home_prefix in main.cf.

=cut


# Descriptions: front end wrapper to retrieve $ml_home_prefix (/var/spool/ml).
#               return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_prefix
{
    my ($curproc, $domain) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };
    __ml_home_prefix_from_main_cf($main_cf, $domain);
}


# Descriptions: return $ml_home_prefix defined in main.cf (/etc/fml/main.cf).
#               return $ml_home_prefix for $domain if $domain is specified.
#               return default one if $domain is not specified.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
sub __ml_home_prefix_from_main_cf
{
    my ($main_cf, $domain) = @_;

    if (defined $domain) {
	my ($virtual_maps) = __get_virtual_maps($main_cf);
	if (@$virtual_maps) {
	    __ml_home_prefix_search_in_virtual_maps($main_cf,
						    $domain,
						    $virtual_maps);
	}
	else {
	    ;
	}
    }
    else {
	if (defined $main_cf->{ ml_home_prefix }) {
	    return $main_cf->{ ml_home_prefix };
	}
	elsif (defined $main_cf->{ default_ml_home_prefix }) {
	    return $main_cf->{ default_ml_home_prefix };
	}
	else {
	    croak("\${default_,}ml_home_prefix is undefined.");
	}
    }
}



# Descriptions: search virtual domain in $virtual_maps.
#               return $ml_home_prefix for the virtual domain if found.
#    Arguments: HASH_REF($main_cf) STR($virtual_domain) ARRAY_REF($virtual_maps)
# Side Effects: none
# Return Value: STR
sub __ml_home_prefix_search_in_virtual_maps
{
    my ($main_cf, $virtual_domain, $virtual_maps) = @_;

    if (@$virtual_maps) {
	my $dir = '';
	eval q{ use IO::Adapter; };
	unless ($@) {
	  MAP:
	    for my $map (@$virtual_maps) {
		my $obj  = new IO::Adapter $map;
		$obj->open();
		$dir = $obj->find("^$virtual_domain");
		last MAP if $dir;
	    }
	    ($virtual_domain, $dir) = split(/\s+/, $dir);
	    $dir =~ s/[\s\n]*$// if defined $dir;

	    # found
	    if ($dir) {
		return $dir; # == $ml_home_prefix
	    }
	}
	else {
	    croak("cannot load IO::Adapter");
	}
    }

    return '';
}


#
# XXX
#    __ml_home_prefix_from_main_cf() is not needed.
#    since FML::Process::Switch calculate this variable and set it to
#    $curproc->{ main_cf }.
#


=head2 get_aliases_filepath($domain)

return file path of the aliases for this domain $domain.

=cut


sub mail_aliases
{
    my ($curproc, $domain) = @_;
    return $curproc->{ config }->{ mail_aliases_file };
}


=head2 get_virtual_maps()

return virtual maps.

=cut


# Descriptions: options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_ARRAY
sub get_virtual_maps
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };
    __get_virtual_maps($main_cf);
}


sub __get_virtual_maps
{
    my ($main_cf) = @_;

    if (defined $main_cf->{ virtual_maps } && $main_cf->{ virtual_maps }) {
	my (@r) = ();
	my (@maps) = split(/\s+/, $main_cf->{ virtual_maps });
	for (@maps) {
	    if (-f $_) { push(@r, $_);}
	}
	return \@r;
    }
    else {
	return undef;
    }
}


=head2 article_id_max()

return the current article number (sequence number).

=cut


# Descriptions: return the current article number (sequence number)
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_id_max
{
    my ($curproc) = @_;
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ sequence_file };
    my $id       = undef;

    use FileHandle;
    my $fh = new FileHandle $seq_file;
    if (defined $fh) {
	$id = $fh->getline();
	$id =~ s/^\s*//; $id =~ s/[\n\s]*$//;
	$fh->close();
    }

    if (defined $id) {
	return( $id =~ /^\d+$/ ? $id : 0 );
    }
    else {
	return 0;
    }
}


=head2 hints()

return hints as HASH_REF.
It is useful to switch process behabiour based on this hints.
This function is used in CGI processes typically to verify
whether the current process runs in admin mode or user mode ? et.al.

=cut


sub hints
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };

    return $main_cf->{ _hints };
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Utils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
