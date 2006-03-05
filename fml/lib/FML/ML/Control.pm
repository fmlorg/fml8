#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Control.pm,v 1.13 2006/02/15 13:44:04 fukachan Exp $
#

package FML::ML::Control;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $debug);
use Carp;


=head1 NAME

FML::ML::Control - create, rename and delete ml_home_dir.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 ML CREATE

=cut


# Descriptions: generate _ml_name_xxx in $params.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($params)
# Side Effects: update $params
# Return Value: none
sub adjust_params_for_virtual_domain
{
    my ($self, $curproc, $command_context, $params) = @_;
    my ($ml_name_admin, $ml_name_ctl, $ml_name_error,
	$ml_name_post,$ml_name_request);
    my $ml_name   = $params->{ _ml_name };
    my $ml_domain = $params->{ ml_domain };

    my $is_default_domain = 0;
    if ($curproc->is_default_domain($ml_domain)) {
	$ml_name_admin   = sprintf("%s-%s",$ml_name,"admin",  $ml_domain);
	$ml_name_ctl     = sprintf("%s-%s",$ml_name,"ctl",    $ml_domain);
	$ml_name_error   = sprintf("%s-%s",$ml_name,"error",  $ml_domain);
	$ml_name_request = sprintf("%s-%s",$ml_name,"request",$ml_domain);

	# post is exceptional.
	$ml_name_post    = sprintf("%s",$ml_name, $ml_domain);

	#
        $is_default_domain = 1;
    }
    else {
	# virtual domain case
	$ml_name_admin   = sprintf("%s-%s=%s",$ml_name,"admin",  $ml_domain);
	$ml_name_ctl     = sprintf("%s-%s=%s",$ml_name,"ctl",    $ml_domain);
	$ml_name_error   = sprintf("%s-%s=%s",$ml_name,"error",  $ml_domain);
	$ml_name_request = sprintf("%s-%s=%s",$ml_name,"request",$ml_domain);

	# post is exceptional.
	$ml_name_post    = sprintf("%s=%s",$ml_name, $ml_domain);

	#
        $is_default_domain = 0;
    }

    $params->{ _ml_name_admin }     = $ml_name_admin;
    $params->{ _ml_name_ctl }       = $ml_name_ctl;
    $params->{ _ml_name_error }     = $ml_name_error;
    $params->{ _ml_name_post }      = $ml_name_post;
    $params->{ _ml_name_request }   = $ml_name_request;
    $params->{ _is_default_domain } = $is_default_domain;
}


# Descriptions: create $ml_home_dir if needed.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: create $ml_home_dir dirctory if needed
# Return Value: none
sub init_ml_home_dir
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config      = $curproc->config();
    my $ml_home_dir = $config->{ ml_home_dir };

    unless (-d $ml_home_dir) {
	$curproc->mkdir($ml_home_dir, "mode=public");
    }

    # $ml_home_dir/etc/mail
    my $dirlist =
	$config->get_as_array_ref('newml_command_init_public_directories');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    $curproc->ui_message("creating $_dir");
	    $curproc->mkdir($_dir, "mode=public");
	}
    }

    $dirlist =
	$config->get_as_array_ref('newml_command_init_private_directories');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    $curproc->ui_message("creating $_dir");
	    $curproc->mkdir($_dir, "mode=private");
	}
    }
}


# Descriptions: install config.cf, include, include-ctl et. al.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: install config.cf, include, include-ctl et. al.
# Return Value: none
sub install_template_files
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config       = $curproc->config();
    my $mode         = $self->get_mode() || 'newml';
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $ml_home_dir  = $params->{ ml_home_dir };
    my $templ_files  =
	$config->get_as_array_ref('newml_command_template_files');

    # 1. set up fml specific files e.g. config.cf
    use File::Spec;
    for my $file (@$templ_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir,  $file);

	$curproc->ui_message("creating $dst");
	$self->_install($src, $dst, $params);
    }

    # 2. set up MTA specific files e.g. include, .qmail-*
    unless ($mode eq 'createonpost' || $mode eq 'create-on-post') {
	use FML::MTA::Control;

	# 2.1 setup include include-ctl ... (postfix/sendmail style)
	# 2.2 setup ~fml/.qmail-* (qmail style)
	my $list = $config->get_as_array_ref('newml_command_mta_config_list');
	for my $mta (@$list) {
	    my $obj = new FML::MTA::Control { mta_type => $mta };
	    $obj->setup($curproc, $params);
	}
    }
}


# Descriptions: install ONLY config.cf file.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: config.cf created if needed.
# Return Value: none
sub install_config_cf
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config       = $curproc->config();
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $ml_home_dir  = $params->{ ml_home_dir };

    use File::Spec;
    for my $file (qw(config.cf)) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir,  $file);

	$curproc->ui_message("creating $dst");
	$self->_install($src, $dst, $params);
    }
}


# Descriptions: update alias entries.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: update aliases entry
# Return Value: none
sub update_aliases
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config    = $curproc->config();
    my $ml_name   = $config->{ ml_name };
    my $ml_domain = $config->{ ml_domain };
    my $alias     = $config->{ mail_aliases_file };
    my $mask      = umask( 022 );

    # append
    if ($self->is_mta_alias_maps_has_ml_entry($curproc, $params, $ml_name)) {
	$curproc->ui_message("warning: $ml_name already defined!");
	$curproc->ui_message("         ignore aliases updating");
	$curproc->logwarn("$ml_name ml already defined");
    }
    else {
	my $list = $config->get_as_array_ref('newml_command_mta_config_list');
	eval q{
	    for my $mta (@$list) {
		my $optargs = { mta_type => $mta, key => $ml_name };

		use FML::MTA::Control;
		my $obj = new FML::MTA::Control;
		my $found = $obj->find_key_in_alias_maps($curproc, $params, {
		    mta_type => $mta,
		    key      => $ml_name,
		});

		# we need to use the original $params here
		# update templates for qmail/control/virtualdomains
		unless ($curproc->is_default_domain($ml_domain)) {
		    $obj->install_virtual_map($curproc, $params, $optargs);
		    $obj->update_virtual_map($curproc, $params, $optargs);
		}

		if ($found) {
		    $curproc->ui_message("skipping alias update for $mta");
		}
		else {
		    $obj->install_alias($curproc, $params, $optargs);
		    $obj->update_alias($curproc, $params, $optargs);
		}
	    }
	};
	croak($@) if $@;
    }

    umask( $mask );
}


# Descriptions: check if $alias file has an $ml_name entry or not.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) STR($ml_name)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub is_mta_alias_maps_has_ml_entry
{
    my ($self, $curproc, $params, $ml_name) = @_;
    my $config = $curproc->config();
    my $list   = $config->get_as_array_ref('newml_command_mta_config_list');
    my $found  = 0;
    my $is_default_domain = $params->{ _is_default_domain };

    eval q{
	use FML::MTA::Control;

	if ($is_default_domain) {
	    my $obj = new FML::MTA::Control;
	    if ($obj->is_user_entry_exist_in_passwd($ml_name)) {
		my $s = "ml_name=$ml_name is found in passwd";
		$curproc->ui_message("error: $s");
		$curproc->logerror($s);
		$found = 1;
	    }
	}
	else {
	    $curproc->logdebug("not check $ml_name in passwd");
	}

	unless ($found) {
	  MTA:
	    for my $mta (@$list) {
		my $obj = new FML::MTA::Control;
		$found = $obj->find_key_in_alias_maps($curproc, $params, {
		    mta_type   => $mta,
		    key        => $ml_name,
		});

		if ($found) {
		    my $s = "ml_name=$ml_name is found in $mta aliases";
		    $curproc->ui_message("error: $s");
		    $curproc->logerror($s);
		    last MTA;
		}
	    }
	}
    };
    croak($@) if $@;

    return $found;
}


# Descriptions: set up ~fml/public_html/ for this mailing list.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: create directories for html articles
# Return Value: none
sub setup_mail_archive_dir
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config = $curproc->config();
    my $dir    = $config->{ html_archive_dir };

    unless (-d $dir) {
	$curproc->ui_message("creating $dir");
	$curproc->mkdir($dir, "mode=public");
    }
}


# Descriptions: set up CGI interface for this mailing list but
#               disable it by default.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: create directories and install cgi scripts
# Return Value: none
sub setup_cgi_interface
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $template_dir = $curproc->newml_command_template_files_dir();
    my $config       = $curproc->config();

    #
    # 1. create directory path if needed
    #
    my (%is_dir_exists)  = ();
    my $cgi_base_dir     = $config->{ cgi_base_dir };
    my $admin_cgi_dir    = $config->{ admin_cgi_base_dir };
    my $ml_admin_cgi_dir = $config->{ ml_admin_cgi_base_dir };
    for my $dir ($cgi_base_dir, $admin_cgi_dir, $ml_admin_cgi_dir) {
	unless (-d $dir) {
	    $curproc->ui_message("creating $dir");
	    $is_dir_exists{ $dir } = 0;
	    $curproc->mkdir($dir, "mode=public");
	}
	else {
	    $is_dir_exists{ $dir } = 1;
	}
    }

    #
    # 2. disable CGI access by creating a dummy .htaccess
    #    install .htaccess only for the first time.
    #
    unless ( $is_dir_exists{ $cgi_base_dir } ) {
	use File::Spec;
	my $src   = File::Spec->catfile($template_dir, 'dot_htaccess');
	my $dst   = File::Spec->catfile($cgi_base_dir, '.htaccess');

	$curproc->ui_message("creating $dst");
	$curproc->ui_message("         (a dummy to disable cgi by default)");
	$self->_install($src, $dst, $params);
    }

    #
    # 3.  install *.cgi
    #

    use File::Spec;
    my $libexec_dir = $config->{ fml_libexec_dir };
    my $src         = File::Spec->catfile($libexec_dir, 'loader');
    my $ml_name     = $config->{ ml_name };
    my $ml_domain   = $config->{ ml_domain };

    # 3.1 install admin/{menu,config,thread}.cgi
    {
	# hints
	$params->{ __hints_for_fml_process__ } = qq{
	    \$hints = {
		cgi_mode  => 'admin',
		ml_name   => '$ml_name',
		ml_domain => '$ml_domain',
	    };
	};

	use File::Spec;
	for my $dst (
		   File::Spec->catfile($admin_cgi_dir, 'menu.cgi'),
		   File::Spec->catfile($admin_cgi_dir, 'config.cgi'),
		   File::Spec->catfile($admin_cgi_dir, 'thread.cgi')
		     ) {
	    $curproc->ui_message("creating $dst");
	    $self->_install($src, $dst, $params);
	    chmod 0755, $dst;
	}
    }

    #
    # 3.2. install ml-admin/
    {
	# hints
	$params->{ __hints_for_fml_process__ } = qq{
	    \$hints = {
		cgi_mode  => 'ml-admin',
		ml_name   => '$ml_name',
		ml_domain => '$ml_domain',
	    };
	};

	use File::Spec;
	for my $dst (
		   File::Spec->catfile($ml_admin_cgi_dir, 'menu.cgi'),
		   File::Spec->catfile($ml_admin_cgi_dir, 'config.cgi'),
		   File::Spec->catfile($ml_admin_cgi_dir, 'thread.cgi')
		     ) {
	    $curproc->ui_message("creating $dst");
	    $self->_install($src, $dst, $params);
	    chmod 0755, $dst;
	}
    }
}


# Descriptions: install $dst with variable expansion of $src.
#    Arguments: OBJ($self) STR($src) STR($dst) HASH_REF($config)
# Side Effects: create $dst
# Return Value: none
sub _install
{
    my ($self, $src, $dst, $config) = @_;

    # XXX-TODO: method-ify.
    eval q{
	use FML::Config::Convert;
	&FML::Config::Convert::convert_file($src, $dst, $config);
    };
    croak($@) if $@;
}


# Descriptions: set up information for this mailing list.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: create directories
# Return Value: none
sub setup_listinfo
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config       = $curproc->config();
    my $template_dir = $config->{ listinfo_template_dir };
    my $listinfo_dir = $config->{ listinfo_dir };

    unless (-d $listinfo_dir) {
	$curproc->mkdir($listinfo_dir, "mode=public");
    }

    use DirHandle;
    my $dh = new DirHandle $template_dir;
    if (defined $dh) {
	my $file = '';

      FILE:
	while (defined($file = $dh->read)) {
	    next FILE if $file =~ /^\./o;
	    next FILE if $file =~ /^CVS/o;

	    use File::Spec;
	    my $src = File::Spec->catfile($template_dir, $file);
	    my $dst = File::Spec->catfile($listinfo_dir, $file);

	    $curproc->ui_message("creating $dst");
	    $self->_install($src, $dst, $params);
	}
    }
}


=head1 CREATE-ON-POST

=cut


# Descriptions: set up or fix create-on-post environment.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: fix include, virtual files.
# Return Value: none
sub install_createonpost
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config    = $curproc->config(); 
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();

    # 1. set up virtual.
    eval q{
	my $list = $config->get_as_array_ref('newml_command_mta_config_list');
	for my $mta (@$list) {
	    my $optargs = { mta_type => $mta, key => $ml_name };

	    use FML::MTA::Control;
	    my $obj = new FML::MTA::Control;
	    if ($obj->can('install_createonpost')) {
		$obj->install_createonpost($curproc, $params, $optargs);
	    }
	    else {
		$curproc->ui_message("ignoring create-on-post setup for $mta");
	    }
	}
    };

    # 2. remove include* files.
    use File::Spec;
    my $ml_home_dir = $curproc->ml_home_dir($ml_name, $ml_domain);
    for my $file (qw(include include-ctl include-error)) {
	my $dst = File::Spec->catfile($ml_home_dir, $file);
	unlink($dst);
    }

    # 3. reset include file.
    my $include = File::Spec->catfile($ml_home_dir, "include");
    my $prefix  = $curproc->executable_prefix();
    my $program = File::Spec->catfile($prefix, "createonpost");

    use FileHandle;
    my $wh = new FileHandle "> $include";
    if (defined $wh) {
	print $wh "\"| $program $ml_name\@$ml_domain\"\n";
	$wh->close();
    }
}


# Descriptions: disable create-on-post environment.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: fix include, virtual files.
# Return Value: none
sub delete_createonpost
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config  = $curproc->config(); 
    my $ml_name = $config->{ ml_name };
    my $list    = $config->get_as_array_ref('newml_command_mta_config_list');

    eval q{
	for my $mta (@$list) {
	    my $optargs = { mta_type => $mta, key => $ml_name };

	    use FML::MTA::Control;
	    my $obj = new FML::MTA::Control;
	    if ($obj->can('delete_createonpost')) {
		$obj->delete_createonpost($curproc, $params, $optargs);
	    }
	    else {
		my $s = "ignoring create-on-post disabler for $mta";
		$curproc->ui_message($s);
	    }
	}
    };
}


=head1 ML REMOVE

=cut


# Descriptions: remove $ml_home_dir and update aliases if needed.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: remove ml_home_dir, update aliases entry
# Return Value: none
sub delete_ml_home_dir
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $ml_name        = $params->{ ml_name };
    my $ml_domain      = $params->{ ml_domain };
    my $ml_home_prefix = $params->{ ml_home_prefix };
    my $ml_home_dir    = $params->{ ml_home_dir };

    $curproc->ui_message("removing ml_home_dir for $ml_name");

    # /var/spool/ml/elena -> /var/spool/ml/@elena
    my $removed_dir = $curproc->ml_home_dir_deleted_path($ml_name, $ml_domain);
    rename($ml_home_dir, $removed_dir);

    if (-d $removed_dir && (! -d $ml_home_dir)) {
	$curproc->ui_message("removed");
    }
    else {
	my $s = "failed to remove ml_home_dir";
	$curproc->ui_message("error: $s");
	$curproc->logerror($s);
    }
}


# Descriptions: remove aliases entry.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               OBJ($command_context)
#               HASH_REF($params)
# Side Effects: update aliases entry
# Return Value: none
sub delete_aliases
{
    my ($self, $curproc, $command_context, $params) = @_;
    my $config  = $curproc->config();
    my $ml_name = $params->{ ml_name };
    my $list    = $config->get_as_array_ref('newml_command_mta_config_list');

    eval q{
	use FML::MTA::Control;

	for my $mta (@$list) {
	    # XXX-TODO: $optargs = { mta_type => $mta } valid ?
	    my $optargs = { mta_type => $mta };
	    my $obj = new FML::MTA::Control;
	    $obj->delete_alias($curproc, $params, $optargs);
	    $obj->update_alias($curproc, $params, $optargs);
	    $obj->delete_virtual_map($curproc, $params, $optargs);
	    $obj->update_virtual_map($curproc, $params, $optargs);
	}
    };
    croak($@) if $@;
}


=head1 UTILITY

=head2 set_mode($mode)

set mode.

=head2 get_mode()

get mode.

=cut


# Descriptions: set mode.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: none
# Return Value: none
sub set_mode
{
    my ($self, $mode) = @_;

    if (defined $mode) {
	$self->{ _current_mode } = $mode;
    }
}


# Descriptions: get mode.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_mode
{
    my ($self) = @_;
    return( $self->{ _current_mode } || '' );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::ML::Control first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
