#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Utils.pm,v 1.85 2003/10/15 08:25:28 fukachan Exp $
#

package FML::Process::Utils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);
use File::Spec;
use File::stat;


=head1 NAME

FML::Process::Utils - convenient utilities for FML::Process:: classes

=head1 SYNOPSIS

See L<FML::Process::Kernel>.

=head1 DESCRIPTION

See FML:: classes, which uses these function everywhere.

=head1 access METHODS to handle configuration space

=head2 config()

return FML::Config object.

=head2 pcb()

return FML::PCB object.

=head2 schduler()

return FML::Process::Scheduler object.

=cut


# Descriptions: return FML::Config object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub config
{
    my ($curproc) = @_;

    if (defined $curproc->{ config }) {
	return $curproc->{ config };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::PCB object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub pcb
{
    my ($curproc) = @_;

    if (defined $curproc->{ pcb }) {
	return $curproc->{ pcb };
    }
    else {
	return undef;
    }
}


# Descriptions: return FML::Process::Scheduler object
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub scheduler
{
    my ($curproc) = @_;

    if (defined $curproc->{ scheduler }) {
	return $curproc->{ scheduler };
    }
    else {
	return undef;
    }
}


=head1 access METHODS to handle incoming_message

available all processes which eats message via STDIN.

The following functions return the whole or a part of the incoming
message corresponding to the current process.

The message is a chain of C<Mail::Message> objects such as

   header -> body

   header -> multipart-preamble -> multipart-separator -> part1 -> ...

See L<Mail::Message> for more details.

=head2 incoming_message_header()

return the header part for the incoming message.
It is the head of a chain of Mail::Message objects.

=head2 incoming_message_body()

return the body part for the incoming message.
It is the 2nd part of a chain of Mail::Message objects and after.
For example,

   body

   multipart-preamble -> multipart-separator -> part1 -> ...

=head2 incoming_message()

return the whole message for the incoming message.
It is the whole parts of a chain.

=cut


# Descriptions: return incoming_message header object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ header }) {
	return $curproc->{ incoming_message }->{ header };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message body object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ body }) {
	return $curproc->{ incoming_message }->{ body };
    }
    else {
	return undef;
    }
}


# Descriptions: return incoming_message message object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub incoming_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ incoming_message }->{ message }) {
	return $curproc->{ incoming_message }->{ message };
    }
    else {
	return undef;
    }
}


=head1 access METHODS to handle article

available only in C<libexec/distribute> process.

The usage of these functions is same as that of incoming_message_*()
methods but article_*() hanldes the article object to distribute now.
So, incoming_message_*() handles input but article_message_*() handles
output.

=head2 article_message_header()

=head2 article_message_body()

=head2 article_message()

=cut


# Descriptions: return article header object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_header
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ header }) {
	return $curproc->{ article }->{ header };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ header } not defined");
	return undef;
    }
}


# Descriptions: return article body object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message_body
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ body }) {
	return $curproc->{ article }->{ body };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ body } not defined");
	return undef;
    }
}


# Descriptions: return article message object if could
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub article_message
{
    my ($curproc) = @_;

    if (defined $curproc->{ article }->{ message }) {
	return $curproc->{ article }->{ message };
    }
    else {
	$curproc->logerror("\$curproc->{ article }->{ message } not defined");
	return undef;
    }
}


=head1 misc METHODS

=head2 mkdir($dir, $mode)

create directory $dir if needed.

=cut

#
# XXX-TODO: $curproc->mkdir() is strage.
# XXX-TODO: hmm, we create a new subcleass such as $curproc->util->mkdir() ?
# XXX-TODO: or $utils = $curproc->utils(); $utils->mkdir(dir, mode); ?
# XXX-TODO: we need FML::Utils class ?
#

# Descriptions: create directory $dir if needed
#    Arguments: OBJ($curproc) STR($dir) STR($mode)
# Side Effects: create directory $dir
# Return Value: NUM(1 or 0)
sub mkdir
{
    my ($curproc, $dir, $mode) = @_;
    my $config  = $curproc->config();
    my $dirmode = $config->{ default_directory_mode } || '0700';

    # back up umask
    my $curmask = umask( 077 ); # full open for readability

    unless (-d $dir) {
	if (defined $mode) {
	    if ($mode =~ /^\d+$/) { # NUM 0700
		$curproc->_mkpath_num($dir, $mode);
	    }
	    elsif ($mode =~ /mode=(\S+)/) {
		my $xmode = "directory_${1}_mode";
		if (defined $config->{ $xmode }) {
		    $curproc->_mkpath_str($dir, $config->{ $xmode });
		}
		else {
		    $curproc->logerror("mkdir: invalid mode");
		}
	    }
	    else {
		$curproc->logerror("mkdir: invalid mode");
	    }
	}
	elsif ($dirmode =~ /^\d+$/) { # STR 0700
	    $curproc->_mkpath_str($dir, $dirmode);
	}
	else {
	    $curproc->logerror("mkdir: invalid mode");
	}
    }

    return( -d $dir ? 1 : 0 );
}


# Descriptions: mkdir with the specified dir mode
#    Arguments: OBJ($curproc) STR($dir) NUM($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_num
{
    my ($curproc, $dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/) { # NUM 0700
	eval q{ use File::Path;};
	mkpath([ $dir ], 0, $mode);
	chmod $mode, $dir;
	$curproc->log(sprintf("mkdir %s mode=0%o", $dir, $mode));
    }
    else {
	$curproc->logerror("mkdir: invalid mode (N)");
    }

    umask($cur_mask);
}


# Descriptions: mkdir with the specified dir mode
#    Arguments: OBJ($curproc) STR($dir) STR($mode)
# Side Effects: mkdir && chmod
# Return Value: none
sub _mkpath_str
{
    my ($curproc, $dir, $mode) = @_;
    my $cur_mask = umask();

    umask(0);

    if ($mode =~ /^\d+$/) { # STR 0700
	eval qq{
	    use File::Path;
	    mkpath([ \$dir ], 0, $mode);
	    chmod $mode, \$dir;
	    \$curproc->log(\"mkdirhier \$dir mode=$mode\");
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->logerror("mkdir: invalid mode (S)");
    }

    umask($cur_mask);
}


# XXX-TODO: $curproc->cat() is strage.

# Descriptions: concantenate files to STDOUT
#    Arguments: OBJ($curproc) ARRAY_REF($files) HANDLE($out)
# Side Effects: none
# Return Value: none
sub cat
{
    my ($curproc, $files, $out) = @_;
    $out ||= \*STDOUT;

    for my $file (@$files) {
	_cat($file, $out);
    }
}


# Descriptions: cat file to STDOUT
#    Arguments: STR($file) HANDLE($out)
# Side Effects: none
# Return Value: none
sub _cat
{
    my ($file, $out) = @_;

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
	my $buf = '';
	while (sysread($fh, $buf, 4096)) {
	    syswrite($out, $buf);
	}
	$fh->close();
    }
}


=head2 unique( $array )

make components in $array unique.

=cut


# Descriptions: make components in $array unique
#    Arguments: OBJ($self) ARRAY_REF($array)
# Side Effects: none
# Return Value: ARRAY_REF
sub unique
{
    my ($self, $array) = @_;
    my $x     = [];
    my $cache = {};

    if (ref($array) eq 'ARRAY' && @$array) {
      COMPONENT:
	for my $k (@$array) {
	    next COMPONENT if $cache->{ $k };
	    push(@$x, $k);
	    $cache->{ $k } = 1;
	}
    }

    return $x;
}


=head1 ml_home_dir handling

=cut


# Descriptions:
#    Arguments: OBJ($curproc) STR($ml_home_prefix) STR($ml_name)
# Side Effects: none
# Return Value: STR
sub removed_ml_home_dir_path
{
    my ($curproc, $ml_home_prefix, $ml_name) = @_;

    use Mail::Message::Date;
    my $dobj = new Mail::Message::Date time;
    my $date = $dobj->{ YYYYMMDD };

    use File::Spec;
    my $x = sprintf("%s%s.%d", '@', $ml_name, $date);
    return File::Spec->catfile($ml_home_prefix, $x);
}


# Descriptions: find the latest removed $ml_home_dir
#    Arguments: OBJ($curproc) STR($ml_home_prefix) STR($ml_name)
# Side Effects: none
# Return Value: STR
sub find_latest_removed_ml_home_dir
{
    my ($curproc, $ml_home_prefix, $ml_name) = @_;
    my ($entry) = [];

    use DirHandle;
    my $dh = new DirHandle $ml_home_prefix;
    if (defined $dh) {
	my $x;

      ENTRY:
	while ($x = $dh->read()) {
	    next ENTRY if $x =~ /^\./o;

	    if ($x =~ /^\@$ml_name$/ || $x =~ /^\@$ml_name\.\d+$/) {
		push(@$entry, $x);
	    }
	}
	$dh->close();
    }

    my $name = $curproc->_sort_ml_name($ml_home_prefix, $ml_name, $entry);
    if ($name) {
	return File::Spec->catfile($ml_home_prefix, $name);
    }
    else {
	return '';
    }
}


# Descriptions: sort ml_name entries (@$entry) and return the latest.
#    Arguments: OBJ($curproc)
#               STR($ml_home_prefix) STR($ml_name) ARRAY_REF($entry)
# Side Effects: none
# Return Value: STR
sub _sort_ml_name
{
    my ($curproc, $ml_home_prefix, $ml_name, $entry) = @_;
    my $latest   = 0;
    my $is_found = 0;

    for my $x (@$entry) {
	if ($x =~ /^\@$ml_name\.(\d+)$/) {
	    $latest = $1 > $latest ? $1 : $latest;
	}
	elsif ($x =~ /^\@$ml_name$/) {
	    $is_found = $x;
	}
    }

    my $latest_name = sprintf("%s%s.%d", '@', $ml_name, $latest);
    if ($latest && $is_found) {
	my $mtime_latest = _mtime($ml_home_prefix, $latest_name);
	my $mtime_exact  = _mtime($ml_home_prefix, $is_found);
	return( ($mtime_latest > $mtime_exact) ? $latest_name : $is_found );
    }
    elsif ($latest) {
	return $latest_name;
    }
    elsif ($is_found) {
	return $is_found;
    }
    else {
	return '';
    }
}


# Descriptions: return mtime of $prefix/$x file/dir.
#    Arguments: STR($prefix) STR($x)
# Side Effects: none
# Return Value: NUM
sub _mtime
{
    my ($prefix, $x) = @_;
    my $p  = File::Spec->catfile($prefix, $x);
    my $st = stat($p);
    return $st->mtime;
}


=head1 METHODS for convenience

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


# Descriptions: return the current action name,
#               which syntax is checked by regexp.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub safe_cgi_action_name
{
    my ($curproc) = @_;
    my $name = $curproc->myname();

    if ($curproc->is_safe_syntax('action', $name)) {
	return $name;
    }
    else {
	return undef;
    }
}


# Descriptions: check $str with $class regexp defined in FML::Restriction.
#    Arguments: OBJ($curproc) STR($class) STR($str)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_safe_syntax
{
    my ($curproc, $class, $str) = @_;

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;

    if ($safe->regexp_match($class, $str)) {
	return 1;
    }
    else {
	return 0;
    }
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


# Descriptions: return ml_name
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub ml_name
{
    my ($curproc) = @_;
    my $config = $curproc->config();

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
    my $config = $curproc->config();

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

    # XXX domain name is case insensitive.
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

# XXX-TODO: __ml_home_prefix_from_main_cf() is not needed.
# XXX-TODO: since FML::Process::Switch calculate this variable and
# XXX-TODO: set it to $curproc->{ main_cf }.


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
#    Arguments: HASH_REF($main_cf) STR($domain)
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
		croak("ml_home_prefix: unknown domain ($domain)");
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
#
#               SUPPORT ONLY FILE TYPE MAPS NOT SQL NOR LDAP.
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
		# XXX only support file:// map
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


# Descriptions: return $ml ML's config.cf path
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub config_cf_filepath
{
    my ($curproc, $ml, $domain) = @_;
    my $prefix = $curproc->ml_home_prefix($domain);

    unless (defined $ml) {
	$ml = $curproc->config()->{ ml_name };
    }

    use File::Spec;
    return File::Spec->catfile($prefix, $ml, "config.cf");
}


# Descriptions: return whether $ml ML's config.cf file exists or not.
#    Arguments: OBJ($curproc) STR($ml) STR($domain)
# Side Effects: none
# Return Value: STR
sub is_config_cf_exist
{
    my ($curproc, $ml, $domain) = @_;
    my $f = $curproc->config_cf_filepath($ml, $domain);

    return ( -f $f ? 1 : 0 );
}


=head2 get_virtual_maps()

return virtual maps.

=cut


# Descriptions: return virtual maps as array reference.
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
	for my $map (@maps) {
	    if (-f $map) { push(@r, $map);}
	}
	return \@r;
    }
    else {
	return undef;
    }
}


=head2 is_cgi_process()

inform whether this process runs as cgi ?

=head2 is_under_mta_process()

inform whether this process runs under MTA ?

=cut


# Descriptions: whether this process runs as cgi ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_cgi_process
{
    my ($curproc) = @_;
    my $name = $curproc->myname() || '';

    if ($name =~ /\.cgi$/) {
	return 1;
    }

    return 0;
}


# Descriptions: whether this process runs as cgi ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_under_mta_process
{
    my ($curproc) = @_;
    my $name = $curproc->myname() || '';

    if ($name eq 'distribute' ||
	$name eq 'command'    ||
	$name eq 'digest'     ||
	$name eq 'error'      ||
	$name eq 'fml.pl'     ) {
	return 1;
    }

    return 0;
}


=head2 get_ml_list()

get ARRAY_REF of valid mailing lists.

=cut


# Descriptions: list up ML's within the specified $ml_domain.
#    Arguments: OBJ($curproc) STR($ml_domain)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_ml_list
{
    my ($curproc, $ml_domain) = @_;
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
	use FML::Restriction::Base;
	my $safe    = new FML::Restriction::Base;
	my $ml_name = '';

	while ($ml_name = $dh->read()) {
	    next if $ml_name =~ /^\./o;
	    next if $ml_name =~ /^\@/o;

	    # XXX permit $ml_name matched by FML::Restriction::Base.
	    if ($safe->regexp_match('ml_name', $ml_name)) {
		$cf = File::Spec->catfile($prefix, $ml_name, "config.cf");
		push(@dirlist, $ml_name) if -f $cf;
	    }
	}
	$dh->close;
    }

    @dirlist = sort @dirlist;
    return \@dirlist;
}


=head2 get_address_list( $map )

get ARRAY_REF of address list for the specified map.

=cut


# Descriptions: get address list for the specified map
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_address_list
{
    my ($curproc, $map) = @_;
    my $config = $curproc->config();
    my $list   = $config->get_as_array_ref( $map );

    eval q{ use FML::Command::UserControl;};
    unless ($@) {
	my $obj = new FML::Command::UserControl;
	return $obj->get_user_list($curproc, $list);
    }

    return [];
}


=head2 which_map_nl($map)

which this $map belongs to ?

=cut


# Descriptions: which member of maps is this $map ?
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: STR
sub which_map_nl
{
    my ($curproc, $map) = @_;
    my $config = $curproc->config();
    my $found  = '';

  SEARCH_MAPS:
    for my $mode (qw(member recipient admin_member digest_recipient)) {
	my $maps = $config->get_as_array_ref("${mode}_maps");
	for my $m (@$maps) {
	    if ($map eq $m) {
		$found = $mode;
		last SEARCH_MAPS;
	    }
	}
    }

    return $found;
}


=head2 convert_to_mail_address($list)

convert_to_mail_address() converts $list to mail addresses.
For example

    maitainer	=>	$maintainer
    sender	=>	sender of the current message (From: in header)

=cut


# Descriptions: convert to mail addresses.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub convert_to_mail_address
{
    my ($curproc, $list) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->{ credential };
    my $result = [];

    for my $rcpt (@$list) {
	if ($rcpt eq 'maintainer') {
	    push(@$result, $config->{ maintainer });
	}
	elsif ($rcpt eq 'sender') {
	    my $sender = $cred->sender();
	    push(@$result, $sender);
	}
	else {
	    $curproc->logerror("unknown recipient type $rcpt");
	}
    }

    return $result;
}


=head2 article_max_id()

return the current article number (sequence number).

=cut


# Descriptions: return the current article number (sequence number)
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_max_id
{
    my ($curproc) = @_;

    use FML::Article;
    my $article = new FML::Article $curproc;
    return $article->id();
}


=head2 get_print_style()

=head2 set_print_style(mode)

=cut


# Descriptions: get print style
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub get_print_style
{
    my ($curproc) = @_;

    return( $curproc->{ __print_style } || 'text');
}


# Descriptions: set print style
#    Arguments: OBJ($curproc) STR($mode)
# Side Effects: none
# Return Value: STR
sub set_print_style
{
    my ($curproc, $mode) = @_;

    $curproc->{ __print_style } = $mode;
}


# Descriptions: inform default language
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub language_default
{
    my ($curproc) = @_;

    return 'euc-jp'; # default
}


# Descriptions: language used in html files
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub language_of_html_file
{
    my ($curproc) = @_;
    $curproc->language_default();
}


# Descriptions: set the current charset
#    Arguments: OBJ($curproc) STR($category) STR($charset)
# Side Effects: none
# Return Value: none
sub set_charset
{
    my ($curproc, $category, $charset) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("charset", $category, $charset);
}


# Descriptions: get the current charset.
#               The default value is given by $template_file_charset.
#    Arguments: OBJ($curproc) STR($category)
# Side Effects: none
# Return Value: STR
sub get_charset
{
    my ($curproc, $category) = @_;
    my $config    = $curproc->config();
    my $pcb       = $curproc->pcb();
    my $_category = $category || "template_file";
    my $default   = $config->{ "${_category}_charset" } || 'us-ascii';
    my $charset   = $pcb->get("charset", $_category) || $default || 'us-ascii';

    return $charset;
}


=head2 get_accept_language_list($list)

set preferred language candidates requested by sender.
$list is ARRAY_REF.

=head2 get_accept_language_list()

return preferred language candidates requested by sender.
The type of return value is ARRAY_REF.

=cut


# Descriptions: return language candidates requested by sender
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: ARRAY_REF
sub set_accept_language_list
{
    my ($curproc, $list) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	if (ref($list) eq 'ARRAY') {
	    $pcb->set('incoming_message', 'accept-language', $list);
	}
	else {
	    $curproc->logerror("set_accept_language_list: invalid data");
	}
    }
}


# Descriptions: return language candidates requested by sender
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_accept_language_list
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    if (defined $pcb) {
	return $pcb->get('incoming_message', 'accept-language');
    }
    else {
	return [ '*' ];
    }
}


=head2 thread_db_args($args)

prepare and return information (HASH_REF) needed to manipulate thread
database.

=cut


# Descriptions: return information (HASH_REF) needed for thread database.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: HASH_REF
sub thread_db_args
{
    my ($curproc, $args) = @_;
    my $config       = $curproc->config();
    my $ml_name      = $config->{ ml_name };
    my $html_dir     = $config->{ html_archive_dir };
    my $udb_dir      = $config->{ udb_base_dir };
    my $index_order  = $config->{ html_archive_index_order_type };
    my $cur_lang     = $curproc->language_of_html_file();

    # whether we should mask address?
    my $use_address_mask  = 'yes';
    my $address_mask_type = 'all';
    if ($config->yes('use_html_archive_address_mask')) {
	$use_address_mask = 'yes';
	$address_mask_type
	    = $config->{ html_archive_address_mask_type } || 'all';
    }

    unless (-d $udb_dir) { $curproc->mkdir($udb_dir);}

    # XXX-TODO: care for non Japanese.
    return {

	charset      => $cur_lang,

	output_dir   => $html_dir, # ~fml/public_html/mlarchive/$domain/$ml/
	db_base_dir  => $udb_dir,  # /var/spool/ml/@udb@
	db_name      => $ml_name,  # elena

	index_order  => $index_order,  # normal/reverse

	# address mask = yes/no, _type = all
	use_address_mask  => $use_address_mask,
	address_mask_type => $address_mask_type,
    };
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


=head2 debug_level()

return debug level.

=cut


# Descriptions: return debug level.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub debug_level
{
    my ($curproc) = @_;
    my $args = $curproc->{ __parent_args };

    return( $args->{ main_cf }->{ debug } || 0 );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Utils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
