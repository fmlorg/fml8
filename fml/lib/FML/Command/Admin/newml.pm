#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.72 2003/10/15 01:03:29 fukachan Exp $
#

package FML::Command::Admin::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::newml - set up a new mailing list

=head1 SYNOPSIS

    use FML::Command::Admin::newml;
    $obj = new FML::Command::Admin::newml;
    $obj->newml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list.
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: not need lock in the first time
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: set up a new mailing list
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $options        = $curproc->command_line_options();
    my $config         = $curproc->config();
    my $ml_name        = $config->{ ml_name };
    my $ml_domain      = $config->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $owner          = $config->{ newml_command_ml_admin_default_address }||
			 $curproc->fml_owner();
    my $params         = {
	fml_owner         => $owner,
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,

	# non conversion ml_name, which is preserved for further use
	_ml_name          => $ml_name,
    };

    # mkdir $ml_home_prefix if could.
    unless (-d $ml_home_prefix) {
	$curproc->mkdir($ml_home_prefix, "mode=public");
    }

    # fundamental check
    croak("\$ml_name is not specified")     unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;
    croak("\$ml_home_prefix not exists")    unless -d $ml_home_prefix;

    # check if $ml_home_prefix is writable
    croak("\$ml_home_prefix is not writable") unless -w $ml_home_prefix;

    # update $ml_home_prefix and $ml_home_dir to expand variables again.
    $config->set( 'ml_home_prefix', $ml_home_prefix );
    $config->set( 'ml_home_dir',    $ml_home_dir );

    # define _ml_name_xxx variables in $parms for virtual domain
    $self->_adjust_params_for_virtual_domain($curproc, $command_args, $params);

    # "makefml --force newml elena" creates elena ML even if elena
    # already exists.
    unless (defined $options->{ force } ) {
	if (-d $ml_home_dir) {
	    warn("$ml_name ml_home_dir($ml_home_dir) already exists");
	    return ;
	}
    }

    # check the duplication of alias keys in MTA aliases
    # Example: search among all entries in postfix $alias_maps and /etc/passwd
    # XXX we assume /etc/passwd exists for backword compatibility
    # XXX on all unix plathomes.
    if ($self->_is_mta_alias_maps_has_ml_entry($curproc, $params, $ml_name)) {
	unless (defined $options->{ force } ) {
	    warn("$ml_name already exists (somewhere in MTA aliases)");
	    return ;
	}
    }

    # 0. creat $ml_home_dir
    # 1. install $ml_home_dir/{config.cf,include,include-ctl}
    # 2. set up aliases
    # 3. prepare mail archive at ~fml/public_html/$domain/$ml/ ?
    # 4. prepare cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/admin/
    #    prepare thread cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/threadview.cgi ?
    # 5. prepare listinfo url
    $self->_init_ml_home_dir($curproc, $command_args, $params);
    $self->_install_template_files($curproc, $command_args, $params);
    $self->_update_aliases($curproc, $command_args, $params);
    $self->_setup_mail_archive_dir($curproc, $command_args, $params);
    $self->_setup_cgi_interface($curproc, $command_args, $params);
    $self->_setup_listinfo($curproc, $command_args, $params);
}


# Descriptions: generate _ml_name_xxx in $params
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($params)
# Side Effects: update $params
# Return Value: none
sub _adjust_params_for_virtual_domain
{
    my ($self, $curproc, $command_args, $params) = @_;
    my ($ml_name_admin, $ml_name_ctl, $ml_name_error,
	$ml_name_post,$ml_name_request);
    my $ml_name   = $params->{ _ml_name };
    my $ml_domain = $params->{ ml_domain };

    if ($curproc->is_default_domain($ml_domain)) {
	$ml_name_admin   = sprintf("%s-%s",$ml_name,"admin",$ml_domain);
	$ml_name_ctl     = sprintf("%s-%s",$ml_name,"ctl",$ml_domain);
	$ml_name_error   = sprintf("%s-%s",$ml_name,"error",$ml_domain);
	$ml_name_request = sprintf("%s-%s",$ml_name,"request",$ml_domain);

	# post is exceptional.
	$ml_name_post    = sprintf("%s",$ml_name, $ml_domain);
    }
    else {
	# virtual domain case
	$ml_name_admin   = sprintf("%s-%s=%s",$ml_name,"admin",$ml_domain);
	$ml_name_ctl     = sprintf("%s-%s=%s",$ml_name,"ctl",$ml_domain);
	$ml_name_error   = sprintf("%s-%s=%s",$ml_name,"error",$ml_domain);
	$ml_name_request = sprintf("%s-%s=%s",$ml_name,"request",$ml_domain);

	# post is exceptional.
	$ml_name_post    = sprintf("%s=%s",$ml_name, $ml_domain);
    }

    $params->{ _ml_name_admin }   = $ml_name_admin;
    $params->{ _ml_name_ctl }     = $ml_name_ctl;
    $params->{ _ml_name_error }   = $ml_name_error;
    $params->{ _ml_name_post }    = $ml_name_post;
    $params->{ _ml_name_request } = $ml_name_request;
}


# Descriptions: create $ml_home_dir if needed
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: create $ml_home_dir dirctory if needed
# Return Value: none
sub _init_ml_home_dir
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config      = $curproc->config();
    my $ml_home_dir = $config->{ ml_home_dir };

    unless (-d $ml_home_dir) {
	$curproc->mkdir($ml_home_dir, "mode=public");
    }

    # $ml_home_dir/etc/mail
    my $dirlist = $config->get_as_array_ref('newml_command_init_public_dirs');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    $curproc->ui_message("creating $_dir");
	    $curproc->mkdir( $_dir, "mode=public");
	}
    }

    $dirlist = $config->get_as_array_ref('newml_command_init_private_dirs');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    $curproc->ui_message("creating $_dir");
	    $curproc->mkdir( $_dir, "mode=private");
	}
    }
}


# Descriptions: install config.cf, include, include-ctl et. al.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: install config.cf, include, include-ctl et. al.
# Return Value: none
sub _install_template_files
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config       = $curproc->config();
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $ml_home_dir  = $params->{ ml_home_dir };
    my $templ_files  =
	$config->get_as_array_ref('newml_command_template_files');

    # 1. set up fml specific files e.g. config.cf
    use File::Spec;
    for my $file (@$templ_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir, $file);

	$curproc->ui_message("creating $dst");
	_install($src, $dst, $params);
    }

    # 2. set up MTA specific files e.g. include, .qmail-*
    use FML::MTAControl;

    # 2.1 setup include include-ctl ... (postfix/sendmail style)
    # 2.2 setup ~fml/.qmail-* (qmail style)
    my $list = $config->get_as_array_ref('newml_command_mta_config_list');
    for my $mta (@$list) {
	my $obj = new FML::MTAControl { mta_type => $mta };
	$obj->setup($curproc, $params);
    }
}


# Descriptions: update aliases entry
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: update aliases entry
# Return Value: none
sub _update_aliases
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config    = $curproc->config();
    my $ml_name   = $config->{ ml_name };
    my $ml_domain = $config->{ ml_domain };
    my $alias     = $config->{ mail_aliases_file };
    my $mask      = umask( 022 );

    # append
    if ($self->_is_mta_alias_maps_has_ml_entry($curproc, $params, $ml_name)) {
	$curproc->ui_message("warning: $ml_name already defined!");
	$curproc->ui_message("         ignore aliases updating");
	$curproc->logwarn("$ml_name ml already defined");
    }
    else {
	my $list = $config->get_as_array_ref('newml_command_mta_config_list');
	eval q{
	    for my $mta (@$list) {
		my $optargs = { mta_type => $mta, key => $ml_name };

		use FML::MTAControl;
		my $obj = new FML::MTAControl;
		my $found = $obj->find_key_in_alias_maps($curproc, $params, {
		    mta_type   => $mta,
		    key        => $ml_name,
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


# Descriptions: $alias file has an $ml_name entry or not
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params) STR($ml_name)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _is_mta_alias_maps_has_ml_entry
{
    my ($self, $curproc, $params, $ml_name) = @_;
    my $config = $curproc->config();
    my $list   = $config->get_as_array_ref('newml_command_mta_config_list');
    my $found  = 0;

    eval q{
	use FML::MTAControl;

	my $obj = new FML::MTAControl;
	if ($obj->is_user_entry_exist_in_passwd($ml_name)) {
	    my $s = "ml_name=$ml_name is found in passwd";
	    $curproc->ui_message("error: $s");
	    $curproc->logerror($s);
	    $found = 1;
	}

	unless ($found) {
	  MTA:
	    for my $mta (@$list) {
		my $obj = new FML::MTAControl;
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


# Descriptions: set up ~fml/public_html/ for this mailing list
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: create directories for html articles
# Return Value: none
sub _setup_mail_archive_dir
{
    my ($self, $curproc, $command_args, $params) = @_;
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
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: create directories and install cgi scripts
# Return Value: none
sub _setup_cgi_interface
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $template_dir = $curproc->template_files_dir_for_newml();
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
	_install($src, $dst, $params);
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
	    _install($src, $dst, $params);
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
	    _install($src, $dst, $params);
	    chmod 0755, $dst;
	}
    }
}


# Descriptions: install $dst with variable expansion of $src
#    Arguments: STR($src) STR($dst) HASH_REF($config)
# Side Effects: create $dst
# Return Value: none
sub _install
{
    my ($src, $dst, $config) = @_;

    eval q{
	use FML::Config::Convert;
	&FML::Config::Convert::convert_file($src, $dst, $config);
    };
    croak($@) if $@;
}


# Descriptions: set up information for this mailing list.
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($command_args)
#               HASH_REF($params)
# Side Effects: create directories
# Return Value: none
sub _setup_listinfo
{
    my ($self, $curproc, $command_args, $params) = @_;
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
	    next FILE if $file =~ /^\./;
	    next FILE if $file =~ /^CVS/;

	    use File::Spec;
	    my $src   = File::Spec->catfile($template_dir, $file);
	    my $dst   = File::Spec->catfile($listinfo_dir, $file);

	    $curproc->ui_message("creating $dst");
	    _install($src, $dst, $params);
	}
    }
}


# Descriptions: show cgi menu for newml
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
        use FML::CGI::ML;
        my $obj = new FML::CGI::ML;
        $obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
        croak($r);
    }
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

FML::Command::Admin::newml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
