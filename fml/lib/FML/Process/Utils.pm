#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.27 2002/06/24 09:42:52 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Process::Utils - convenient utilities for FML::Process:: classes

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

return the current process name.

=head2 command_line_raw_argv()

return @ARGV before getopts() analyze.

=head2 command_line_argv()

return @ARGV after getopts() analyze.

=head2 command_line_argv_find(pat)

return the matched pattern in @ARGV and return it if found.

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


# Descriptions: return the current process name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub myname
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ myname };
}


# Descriptions: return raw @ARGV of the current process,
#               where @ARGV is before getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_raw_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ argv };
}


# Descriptions: return @ARGV of the current process,
#               where @ARGV is after getopts() applied
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_argv
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ ARGV };
}


# Descriptions: return a string matched with the specified pattern and
#               return it.
#    Arguments: OBJ($curproc) STR($pat)
# Side Effects: none
# Return Value: STR
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


# Descriptions: return options, which is the result by getopts() analyze
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub command_line_options
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return $args->{ options };
}


=head2 ml_name()

not yet implemenetd properly. (?)

=cut


# Descriptions: return my domain
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_name
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };

    if (defined $config->{ ml_name } && $config->{ ml_name }) {
	return $config->{ ml_name };
    }
    else {
	croak("\$ml_name not defined.");
    }
}


=head2 ml_domain()

return the domain handled in the current process. If not defined
properly, return the default domain defined in /etc/fml/main.cf.

=cut


# Descriptions: return my domain
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_domain
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };

    if (defined $config->{ ml_domain } && $config->{ ml_domain }) {
	return $config->{ ml_domain };
    }
    else {
	return $curproc->default_domain();
    }
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


# Descriptions: check if $domain is the default one or not.
#               This is used to check $domain is a virtual domain or not.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_default_domain
{
    my ($curproc, $domain) = @_;
    my $default_domain = $curproc->default_domain();

    if ("\L$domain\E" eq "\L$default_domain\E") {
	return 1;
    }
    else {
	return 0;
    }
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

return the path where template files used in "newml" method exist.

=cut


# Descriptions: return the path where template files used
#               in "newml" method exist
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

######################################################################
# XXX
#    __ml_home_prefix_from_main_cf() is not needed.
#    since FML::Process::Switch calculate this variable and set it to
#    $curproc->{ main_cf }.
######################################################################


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


# Descriptions: return $ml ML's home directory
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_dir
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    use File::Spec;
    return File::Spec->catfile($prefix, $ml);
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
    my $default_domain = $main_cf->{ default_domain };

    if (defined $domain) {
	my $found = '';

	my ($virtual_maps) = __get_virtual_maps($main_cf);
	if (@$virtual_maps) {
	    $found = __ml_home_prefix_search_in_virtual_maps($main_cf,
							     $domain,
							     $virtual_maps);
	}

	if ($found) {
	    return $found;
	}
	else {
	    if ("\L$domain\E" eq "\L$default_domain\E") {
		return $main_cf->{ default_ml_home_prefix };
	    }
	    else {
		croak("ml_home_prefix: unknown domain");
	    }
	}
    }
    else {
	# if the domain is given as a hint (CGI)
	if (defined $main_cf->{ _hints }->{ ml_domain }) {

	}
	elsif (defined $main_cf->{ ml_home_prefix }) {
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
#    Arguments: HASH_REF($main_cf)
#               STR($virtual_domain)
#               ARRAY_REF($virtual_maps)
#         bugs: currently support the only file type of IO::Adapter.
#               This limit comes from the architecture 
#               since this function may be used
#               before $curproc and $config is allocated.
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
		my $obj = new IO::Adapter $map;
		if (defined $obj) {
		    $obj->open();
		    $dir = $obj->find("^$virtual_domain");
		}
		last MAP if $dir;
	    }

	    if ($dir) {
		($virtual_domain, $dir) = split(/\s+/, $dir);
		$dir =~ s/[\s\n]*$// if defined $dir;

		# found
		if ($dir) {
		    return $dir; # == $ml_home_prefix
		}
	    }
	}
	else {
	    croak("cannot load IO::Adapter");
	}
    }

    return '';
}


=head2 config_cf_filepath($ml, $domain)

return config.cf path for this $ml ($ml@$domain).

=head2 is_config_cf_exist($ml, $domain)

return 1 if config.cf exists. 0 if not.

=cut


# Descriptions: return $ml ML's home directory
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub config_cf_filepath
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    unless (defined $ml) {
	$ml = $curproc->{ config }->{ ml_name };
    }

    use File::Spec;
    return File::Spec->catfile($prefix, $ml, "config.cf");
}


# Descriptions: return $ml ML's home directory
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub is_config_cf_exist
{
    my ($curproc, $ml, $domain) = @_;
    my $f = $curproc->config_cf_filepath($ml, $domain);

    return ( -f $f ? 1 : 0 );
}


=head2 get_aliases_filepath($domain)

return the file path of the alias file for this domain $domain.

=cut


# Descriptions: return the file path of the alias file
#               for this domain $domain.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: STR
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
# Return Value: ARRAY_REF
sub get_virtual_maps
{
    my ($curproc) = @_;
    my $main_cf = $curproc->{ __parent_args }->{ main_cf };
    __get_virtual_maps($main_cf);
}


# Descriptions: return virtual maps as array reference.
#    Arguments: HASH_REF($main_cf)
# Side Effects: none
# Return Value: ARRAY_REF
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


=head2 get_ml_list()

get HASH ARRAY of valid mailing lists.

=cut


# Descriptions: list up ML for the specified $ml_domain
#    Arguments: OBJ($curproc) HASH_REF($args) STR($ml_domain)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_ml_list
{
    my ($curproc, $args, $ml_domain) = @_;
    my $ml_home_prefix = $curproc->ml_home_prefix();

    if (defined $ml_domain) {
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    else {
	my $xx_domain   = $curproc->ml_domain();
	$ml_home_prefix = $curproc->ml_home_prefix($xx_domain);
    }

    # cheap sanity:
    unless ($ml_home_prefix) {
	croak("get_ml_list: ml_home_prefix undefined");
    }

    use File::Spec;
    use DirHandle;
    my $dh      = new DirHandle $ml_home_prefix;
    my $prefix  = $ml_home_prefix;
    my $cf      = '';
    my @dirlist = ();

    if (defined $dh) {
	while ($_ = $dh->read()) {
	    next if /^\./;
	    next if /^\@/;
	    $cf = File::Spec->catfile($prefix, $_, "config.cf");
	    push(@dirlist, $_) if -f $cf;
	}
	$dh->close;
    }

    @dirlist = sort @dirlist;
    return \@dirlist;
}


=head2 get_recipient_list()

get HASH ARRAY of valid mailing lists.

=cut


# Descriptions: list up recipients list
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_recipient_list
{
    my ($curproc) = @_;
    my $config = $curproc->{ config };
    my $list   = $config->get_as_array_ref( 'recipient_maps' );

    eval q{ use IO::Adapter;};
    unless ($@) {
	my $r = [];

	for my $map (@$list) {
	    my $io  = new IO::Adapter $map;
	    my $key = '';
	    if (defined $io) {
		$io->open();
		while (defined($key = $io->get_next_key())) {
		    push(@$r, $key);
		}
		$io->close();
	    }
	}

	return $r;
    }

    return [];
}


=head2 rewrite_config_if_needed($args, $params)

rewrite $ml_* information for virtual domain.
C<$params> is like this:

	$params = {
		ml_name   => 'rudo',
		ml_domain => 'nuinui.net',
	};

=cut


# Descriptions: check argument and prepare virtual domain information
#               if needed.
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_REF($params)
# Side Effects: none
# Return Value: HASH_REF
sub rewrite_config_if_needed
{
    my ($curproc, $args, $params) = @_;
    my $config         = $curproc->{ config };
    my $ml_name        = '';
    my $ml_domain      = $curproc->default_domain();
    my $ml_home_prefix = '';
    my $ml_home_dir    = '';

    # ml_domain
    if (defined $params->{ 'ml_domain' }) {
	$ml_domain = $params->{ 'ml_domain' };
    }
    else {
	$ml_domain = $curproc->default_domain();
    }

    # virtual domain support e.g. "makefml newml elena@nuinui.net"
    if (defined $params->{ 'ml_name' } && $params->{ 'ml_name' }) {
	$ml_name = $params->{ 'ml_name' };
    }

    if (defined $ml_name && $ml_name && ($ml_name =~ /\@/o)) {
	# overwrite $ml_name
	($ml_name, $ml_domain) = split(/\@/, $ml_name);
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    # default domain: e.g. "makefml newml elena"
    else {
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }

    # cheap sanity
    unless ($ml_home_prefix) {
	croak("rewrite_config_if_needed: ml_home_prefix is undefined".
	      "\n\tfor domain=$ml_domain");
    }

    eval q{ use File::Spec;};
    $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);

    # rewrite $curproc->{ config };
    $config->set('ml_name',        $ml_name);
    $config->set('ml_domain',      $ml_domain);
    $config->set('ml_home_prefix', $ml_home_prefix);
    $config->set('ml_home_dir',    $ml_home_dir);
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


# Descriptions: return hints on this process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
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
