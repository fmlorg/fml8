#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.53 2002/10/29 09:07:39 fukachan Exp $
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

set up a new mailing list
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

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
    my $config         = $curproc->{ 'config' };
    my $ml_name        = $config->{ ml_name };
    my $ml_domain      = $config->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    my $ml_home_dir    = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $params         = {
	fml_owner         => $curproc->fml_owner(),
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental check
    croak("\$ml_name is not specified")     unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;
    croak("\$ml_home_prefix not exists")    unless -d $ml_home_prefix;

    # check if $ml_home_prefix is writable
    croak("\$ml_home_prefix is not writable") unless -w $ml_home_prefix;

    # update $ml_home_prefix and $ml_home_dir to expand variables again.
    $config->set( 'ml_home_prefix', $ml_home_prefix );
    $config->set( 'ml_home_dir',    $ml_home_dir );

    # "makefml --force newml elena" creates elena ML even if elena
    # already exists.
    unless (defined $options->{ force } ) {
	if (-d $ml_home_dir) {
	    warn("$ml_name already exists ($ml_home_dir)");
	    return ;
	}
    }

    # check the duplication of alias keys in MTA aliases
    # Example: search among all entries in postfix $alias_maps
    if ($self->_is_mta_alias_maps_has_ml_entry($curproc, $params, $ml_name)) {
	warn("$ml_name already exists (somewhere in MTA aliases)");
	return ;
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
    my $config      = $curproc->{ 'config' };
    my $ml_home_dir = $config->{ ml_home_dir };

    unless (-d $ml_home_dir) {
	$curproc->mkdir($ml_home_dir, "mode=public");
    }

    # $ml_home_dir/etc/mail
    my $dirlist = $config->get_as_array_ref('newml_command_init_public_dirs');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    print STDERR "creating ", $_dir, "\n";
	    $curproc->mkdir( $_dir, "mode=public");
	}
    }

    $dirlist = $config->get_as_array_ref('newml_command_init_private_dirs');
    for my $_dir (@$dirlist) {
	unless (-d $_dir) {
	    print STDERR "creating ", $_dir, "\n";
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
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $ml_home_dir  = $params->{ ml_home_dir };
    my $templ_files  =
	$config->get_as_array_ref('newml_command_template_files');

    # 1. set up fml specific files e.g. config.cf
    use File::Spec;
    for my $file (@$templ_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir, $file);

	print STDERR "creating ", $dst, "\n";
	_install($src, $dst, $params);
    }

    # 2. set up MTA specific files e.g. include, .qmail-*
    use FML::MTAControl;

    # 2.1 setup include include-ctl ... (postfix/sendmail style)
    my $postfix = new FML::MTAControl { mta_type => 'postfix' };
    $postfix->setup($curproc, $params);

    # 2.2 setup ~fml/.qmail-* (qmail style)
    my $qmail = new FML::MTAControl { mta_type => 'qmail' };
    $qmail->setup($curproc, $params);

    # 2.3
    my $procmail = new FML::MTAControl { mta_type => 'procmail' };
    $procmail->setup($curproc, $params);
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
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };
    my $ml_domain = $config->{ ml_domain };
    my $alias     = $config->{ mail_aliases_file };
    my $mask      = umask( 022 ); 

    # append
    if ($self->_is_mta_alias_maps_has_ml_entry($curproc, $params, $ml_name)) {
	print STDERR "warning: $ml_name already defined!\n";
	print STDERR "         ignore aliases updating.\n";
    }
    else {
	eval q{
	    for my $mta (qw(postfix qmail procmail)) {
		my $optargs = { mta_type => $mta };

		use FML::MTAControl;
		my $obj = new FML::MTAControl;

		# we need to use the original $params here
		# update templates for qmail/control/virtualdomains
		unless ($curproc->is_default_domain($ml_domain)) {
		    $obj->install_virtual_map($curproc, $params, $optargs);
		    $obj->update_virtual_map($curproc, $params, $optargs);
		}

		$obj->install_alias($curproc, $params, $optargs);
		$obj->update_alias($curproc, $params, $optargs);
	    }
	};
	croak($@) if $@;
    }

    umask( $mask );
}


# Descriptions: $alias file has an $ml_name entry or not
#    Arguments: OBJ($self) OBJ($curproc) STR($ml_name)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _is_mta_alias_maps_has_ml_entry
{
    my ($self, $curproc, $params, $ml_name) = @_;
    my $found = 0;

    eval q{
	use FML::MTAControl;

	for my $mta (qw(postfix qmail)) {
	    my $obj = new FML::MTAControl;
	    $found = $obj->find_key_in_alias_maps($curproc, $params, {
		mta_type   => $mta,
		key        => $ml_name,
	    });
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
    my $config = $curproc->{ config };
    my $dir    = $config->{ html_archive_dir };

    unless (-d $dir) {
	print STDERR "creating ", $dir, "\n";
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
    my $config       = $curproc->{ config };

    #
    # 1. create directory path if needed
    #
    my (%is_dir_exists)  = ();
    my $cgi_base_dir     = $config->{ cgi_base_dir };
    my $admin_cgi_dir    = $config->{ admin_cgi_base_dir };
    my $ml_admin_cgi_dir = $config->{ ml_admin_cgi_base_dir };
    for my $dir ($cgi_base_dir, $admin_cgi_dir, $ml_admin_cgi_dir) {
	unless (-d $dir) {
	    print STDERR "creating ", $dir, "\n";
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

	print STDERR "creating ", $dst, "\n";
	print STDERR "         (a dummy to disable cgi by default)\n";
	_install($src, $dst, $params);
    }

    #
    # 3. install admin/{menu,config,thread}.cgi
    #
    {
	use File::Spec;
	my $libexec_dir = $config->{ fml_libexec_dir };
	my $src = File::Spec->catfile($libexec_dir, 'loader');

	# hints
	my $ml_name   = $config->{ ml_name };
	my $ml_domain = $config->{ ml_domain };
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
	    print STDERR "creating ", $dst, "\n";
	    _install($src, $dst, $params);
	    chmod 0755, $dst;
	}
    }

    #
    # 4. install ml-admin/
    #
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
    my $config       = $curproc->{ config };
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

	    print STDERR "creating ", $dst, "\n";
	    _install($src, $dst, $params);
	}
    }
}


# Descriptions: show cgi menu for newml
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create home directories, update aliases, ...
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
        use FML::CGI::Admin::ML;
        my $obj = new FML::CGI::Admin::ML;
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

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::newml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
