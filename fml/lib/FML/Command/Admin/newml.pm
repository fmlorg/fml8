#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: newml.pm,v 1.19 2002/03/20 03:19:03 fukachan Exp $
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
    my ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir) =
	$self->_get_domain_info($curproc, $command_args);
    my $params         = {
	fml_owner         => $curproc->fml_owner(),
	executable_prefix => $curproc->executable_prefix(),
	ml_name           => $ml_name,
	ml_domain         => $ml_domain,
	ml_home_prefix    => $ml_home_prefix,
	ml_home_dir       => $ml_home_dir,
    };

    # fundamental check
    croak("\$ml_name is not specified") unless $ml_name;
    croak("\$ml_home_dir is not specified") unless $ml_home_dir;

    # update $ml_home_prefix and expand variables again.
    $config->set( 'ml_home_prefix' , $ml_home_prefix );

    # "makefml --force newml elena" makes elena ML even if elena
    # already exists.
    unless (defined $options->{ force } ) {
	if (-d $ml_home_dir) {
	    warn("$ml_name already exists");
	    return ;
	}
    }

    # o.k. here we go !
    eval q{
	use File::Utils qw(mkdirhier);
	use File::Spec;
    };
    croak($@) if $@;

    mkdirhier( $ml_home_dir, $config->{ default_dir_mode } || 0755 );

    # $ml_home_dir/etc/mail
    my $mailconfdir = $config->{ mailconf_dir };
    unless (-d $mailconfdir) {
	print STDERR "creating $mailconfdir\n";
	mkdirhier( $mailconfdir, $config->{ default_dir_mode } || 0755 );
    }

    # update $config name space.
    $config->set('ml_name',   $self->{ _ml_name });
    $config->set('ml_domain', $self->{ _ml_domain });

    # 1. install $ml_home_dir/{config.cf,include,include-ctl}
    # 2. set up aliases
    # 3. prepare mail archive at ~fml/public_html/$domain/$ml/ ?
    # 4. prepare cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/admin/
    # 5. prepare thread cgi interface at ?
    #      ~fml/public_html/cgi-bin/fml/$domain/threadview.cgi ?
    $self->_install_template_files($curproc, $command_args, $params);
    $self->_update_aliases($curproc, $command_args, $params);
    $self->_setup_mail_archive_dir($curproc, $command_args, $params);
    $self->_setup_cgi_interface($curproc, $command_args, $params);
}


sub _install_template_files
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config       = $curproc->{ config };
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $ml_home_dir  = $params->{ ml_home_dir };

    my $newml_template_files =
	$config->get_as_array_ref('newml_command_template_files');
    for my $file (@$newml_template_files) {
	my $src = File::Spec->catfile($template_dir, $file);
	my $dst = File::Spec->catfile($ml_home_dir, $file);

	print STDERR "creating $dst\n";
	_install($src, $dst, $params);
    }
}


sub _update_aliases
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $config = $curproc->{ config };

    use File::Spec;
    my $alias = $config->{ mail_aliases_file };
    my $src   = File::Spec->catfile($template_dir, 'aliases');
    my $dst   = $alias . "." . $$;

    print STDERR "updating $alias\n";
    _install($src, $dst, $params);

    # append
    system "cat $dst >> $alias";
}


sub _setup_mail_archive_dir
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $config = $curproc->{ config };
    my $dir    = $config->{ html_archive_dir };

    eval q{ use File::Utils qw(mkdirhier);};
    croak($@) if $@;

    unless (-d $dir) {
	print STDERR "creating $dir\n";
	mkdirhier( $dir, $config->{ default_dir_mode } || 0755 );
    }
}


sub _setup_cgi_interface
{
    my ($self, $curproc, $command_args, $params) = @_;
    my $template_dir = $curproc->template_files_dir_for_newml();
    my $config       = $curproc->{ config };

    #
    # 1. create directory path if needed
    #
    eval q{ use File::Utils qw(mkdirhier);};
    croak($@) if $@;

    my $cgi_base_dir     = $config->{ cgi_base_dir };
    my $admin_cgi_dir    = $config->{ admin_cgi_base_dir };
    my $ml_admin_cgi_dir = $config->{ ml_admin_cgi_base_dir };
    for my $dir ($admin_cgi_dir, $ml_admin_cgi_dir) {
	unless (-d $dir) {
	    print STDERR "creating $dir\n";
	    mkdirhier( $dir, $config->{ default_dir_mode } || 0755 );
	}
    }

    #
    # 2. disable CGI access by creating a dummy .htaccess
    #
    {
	use File::Spec;
	my $src   = File::Spec->catfile($template_dir, 'dot_htaccess');
	my $dst   = File::Spec->catfile($cgi_base_dir, '.htaccess');

	print STDERR "creating $dst\n";
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
	my $ml_name   = $self->{ _ml_name };
	my $ml_domain = $self->{ _ml_domain };
	$params->{ __hints_for_fml_process__ } = qq{
	    \$hints = {
		cgi_mode  => 'admin',
		ml_name   => '$ml_name',
		ml_domain => '$ml_domain',
	    };
	};

	for my $dst (
		   File::Spec->catfile($admin_cgi_dir, 'menu.cgi'),
		   File::Spec->catfile($admin_cgi_dir, 'config.cgi'),
		   File::Spec->catfile($admin_cgi_dir, 'thread.cgi')
		     ) {
	    print STDERR "creating $dst\n";
	    _install($src, $dst, $params);
	    chmod 0755, $dst;
	}
    }

    #
    # 4. install ml-admin/
    #
}


# Descriptions: check argument and prepare virtual domain information
#               if needed.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: ARRAY
sub _get_domain_info
{
    my ($self, $curproc, $command_args) = @_;
    my $ml_name        = $command_args->{ 'ml_name' };
    my $ml_domain      = $curproc->default_domain();
    my $ml_home_prefix = '';
    my $ml_home_dir    = '';

    # virtual domain support e.g. "makefml newml elena@nuinui.net"
    if ($ml_name =~ /\@/o) {
	# overwrite $ml_name
	($ml_name, $ml_domain) = split(/\@/, $ml_name);
	$ml_home_prefix = $curproc->ml_home_prefix($ml_domain);
    }
    # default domain: e.g. "makefml newml elena"
    else {
	$ml_home_prefix = $curproc->ml_home_prefix();
    }

    eval q{ use File::Spec;};
    $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);

    # save for convenience
    $self->{ _ml_name   } = $ml_name;
    $self->{ _ml_domain } = $ml_domain;

    return ($ml_name, $ml_domain, $ml_home_prefix, $ml_home_dir);
}


# Descriptions: install $dst with variable expansion of $src
#    Arguments: STR($src) STR($dst) HASH_REF($config)
# Side Effects: create $dst
# Return Value: none
sub _install
{
    my ($src, $dst, $config) = @_;

    use FileHandle;
    my $in  = new FileHandle $src;
    my $out = new FileHandle "> $dst.$$";

    if (defined $in && defined $out) {
	chmod 0644, "$dst.$$";

	eval q{
	    use FML::Config::Convert;
	    &FML::Config::Convert::convert($in, $out, $config);
	};
	croak($@) if $@;

	$out->close();
	$in->close();

	rename("$dst.$$", $dst) || croak("fail to rename $dst");
    }
    else {
	croak("fail to open $src") unless defined $in;
	croak("fail to open $dst") unless defined $out;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::newml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
