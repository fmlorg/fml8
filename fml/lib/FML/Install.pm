#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Install.pm,v 1.16 2004/07/27 15:47:39 fukachan Exp $
#

package FML::Install;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $install_root $debug);
use Carp;
use FileHandle;
use File::Spec;
use File::Copy;
use File::Basename;


# default ('' == '/')
$install_root = '';


=head1 NAME

FML::Install - utility functions used in installation.

=head1 SYNOPSIS

    # use FML::Install;
    my $installer = new FML::Install;
    my $config    = $installer->load_install_cf( $cf );

    printf $format, "version", $installer->get_version() if $debug;

    my $list = $config->get_as_array_ref('mandatory_dirs');
    for my $dir (@$list) {
	my $path = $installer->path($dir);
	printf $format, $dir, $path if $debug;
	unless (-d $path) {
	    $installer->mkdir($path);
	}
	else {
	    print STDERR "ok $path\n" if $debug;
	}
    }

    $installer->install_main_cf();
    $installer->install_sample_cf_files();
    $installer->install_default_config_files();
    $installer->install_mtree_dir();
    $installer->install_lib_dir();
    $installer->install_libexec_dir();
    $installer->install_data_dir();

    # install programs hereafter.
    $installer->install_bin_programs();

    # update loader.
    if ( $installer->need_resymlink_loader() ) {
	$installer->install_loader();
	$installer->resymlink_loader();
    }

    # set up ml_spool_dir such as /var/spool/ml if needed.
    $installer->setup_ml_spool_dir();

=head1 DESCRIPTION

Our installer C<install.pl> at the fml8 top directory uses this
module.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: initiailze $self->{ _show_message } flag.
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # show several messages by default
    enable_message($me);

    return bless $me, $type;
}


# Descriptions: change install_root directory.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: update $install_root gloval variable.
# Return Value: none
sub set_install_root
{
    my ($self, $dir) = @_;

    if (defined $dir) {
	$install_root = $dir;
	print STDERR "\tinstall_root = $install_root\n";
    }
}


# XXX-TODO: check uid, gid method


=head1 CONFIG

=head2 load_install_cf( $cf )

read the specified config file, initialize and return config object.

=cut


# Descriptions: read the specified config file and initialize config object.
#    Arguments: OBJ($self) STR($cf)
# Side Effects: initialize configuration object
# Return Value: OBJ
sub load_install_cf
{
    my ($self, $cf) = @_;

    use FML::Config;
    my $config = new FML::Config;
    croak( $config->error() ) if $config->error();

    if (-f $cf) {
	$config->load_file( $cf );
	croak( $config->error() ) if $config->error();

	$config->update();
	$self->{ _config } = $config;
	return $config;
    }
    else {
	croak("no such file: $cf");
    }

    return undef;
}


=head1 INSTALL METHODS

=head2 convert($src, $dst, [$mode])

create $dst with variable substitutions.
In addition, chmod() if $mode specified.

=cut


# Descriptions: create $dst with variable substitutions.
#    Arguments: OBJ($self) STR($src) STR($dst) NUM($mode)
# Side Effects: create $dst file.
# Return Value: none
sub convert
{
    my ($self, $src, $dst, $mode) = @_;
    my $tmp = $dst. ".new.$$";
    my $in  = new FileHandle $src;
    my $out = new FileHandle "> $tmp";

    # special flag
    my $dst_already_exist = -f $dst ? 1 : 0;
    my $is_show_message   = $self->_is_show_message();

    if (defined $in && defined $out) {
	my $version = $self->get_version();

	my $buf = '';
	while ($buf = <$in>) {
	    $buf =~ s/__fml_version__/$version/;
	    print $out $buf;
	}

	$out->close();
	$in->close();

	if (rename($tmp, $dst)) {
	    if (-f $dst) {
		if (defined $mode) { chmod $mode, $dst;}

		if ($is_show_message) {
		    if ($dst_already_exist) {
			print STDERR "updating $dst\n";
		    }
		    else {
			print STDERR "creating $dst\n";
		    }
		}
	    }
	    else {
		_errmsg("fail to create $dst");
	    }
	}
	else {
	    _errmsg("fail to rename $tmp $dst");
	}
    }
    else {
	_errmsg("cannot open $src") unless defined $in;
	_errmsg("cannot open $dst") unless defined $out;
	_errmsg("fail to create $dst");
    }
}


=head2 install_main_cf()

install main.cf e.g. /etc/fml/main.cf.

=cut


# Descriptions: install main.cf file.
#    Arguments: OBJ($self)
# Side Effects: create main.cf.
# Return Value: none
sub install_main_cf
{
    my ($self) = @_;

    # XXX src = relative path, dst = absolute path
    my $src        = File::Spec->catfile("fml", "etc", "main.cf");
    my $config_dir = $self->path( 'config_dir' );
    my $dst        = File::Spec->catfile($install_root,
					 $config_dir, "main.cf");

    if (-f $dst) {
	print STDERR "skipping $dst (debug)\n" if $debug;
    }
    else {
	$self->convert($src, $dst, 0644);
    }
}


=head2 install_sample_cf_files()

install sample .cf files:

    site_default_config.cf
    mime_component_filter

=cut


# Descriptions: install sample .cf files.
#    Arguments: OBJ($self)
# Side Effects: create sample .cf files in /etc/fml/.
# Return Value: none
sub install_sample_cf_files
{
    my ($self)     = @_;
    my $config     = $self->{ _config };
    my $config_dir = $self->path( 'config_dir' );
    my $samples    = $config->get_as_array_ref('sample_cf_files');

    for my $file (@$samples) {
	# XXX src = relative path, dst = absolute path
	my $src = File::Spec->catfile("fml", "etc", $file);
	my $dst = File::Spec->catfile($install_root, $config_dir, $file);

	if (-f $dst) {
	    print STDERR "skipping $dst (debug)\n" if $debug;
	}
	else {
	    $self->convert($src, $dst, 0644);
	}
    }

    my $gw_config_dir = $config->get( 'group_writable_config_dir' );
    if (-d $gw_config_dir) {
	chmod 0775, $gw_config_dir;
    }
}


=head2 install_default_config_files()

install default templates at /etc/fml/defautls/$version/.

=head2 install_mtree_dir()

install mtree info at /etc/fml/defautls/$version/mtree/.

=cut


# Descriptions: install default templates.
#    Arguments: OBJ($self)
# Side Effects: create files in /etc/fml/defaults/$version/.
# Return Value: none
sub install_default_config_files
{
    my ($self)     = @_;
    my $config     = $self->{ _config };
    my $config_dir = $self->path( 'default_config_dir' );

    my $_config_dir = File::Spec->catfile($install_root, $config_dir);
    print STDERR "updating $_config_dir\n";

    $self->disable_message();

    # XXX change file name of components of $nl_template_files into
    # XXX ${file_name}.{ja,en,...}
    my $nl_template_files = $config->get_as_array_ref('nl_template_files');
    my $nl_language       = $config->{ nl_default_language } || 'en';
    for my $file (@$nl_template_files) {
	# XXX src = relative path, dst = absolute path
	my $src = File::Spec->catfile("fml", "etc", $file);
	my $dst = File::Spec->catfile($install_root, $config_dir, $file);

	# always override.
	$self->convert($src, $dst, 0644);

	# XXX-TODO: fix tricky installation of default_config.cf.
	# always override.
	# XXX we need install default_config.cf too! (caution: mandatory)
	if ($dst =~ /\.$nl_language$/) {
	    my $xxx = $dst;
	    $xxx =~ s/\.$nl_language$//;
	    $self->convert($src, $xxx, 0644);
	}
    }

    my $template_files = $config->get_as_array_ref('template_files');
    for my $file (@$template_files) {
	# XXX src = relative path, dst = absolute path
	my $src = File::Spec->catfile("fml", "etc", $file);
	my $dst = File::Spec->catfile($install_root, $config_dir, $file);

	# always override.
	$self->convert($src, $dst, 0644);
    }

    $self->enable_message();
}


# Descriptions: install mtree config.
#    Arguments: OBJ($self)
# Side Effects: create files in /etc/fml/defaults/$version/mtree/.
# Return Value: none
sub install_mtree_dir
{
    my ($self) = @_;
    my $config = $self->{ _config };

    # XXX src = relative path, dst = absolute path
    my $dst_dir = File::Spec->catfile($install_root,
				      $self->path( 'default_config_dir' ),
				      "mtree");
    my $src_dir = File::Spec->catfile("fml", "etc", "mtree");

    print STDERR "updating $dst_dir\n" if $debug;
    $self->copy_dir( $src_dir, $dst_dir );
}


=head2 install_lib_dir()

install library (perl modules).

=head2 install_libexec_dir()

install libexec executables.

=head2 install_data_dir()

install files under fml/share/.

=cut


# Descriptions: install perl modules.
#    Arguments: OBJ($self)
# Side Effects: install lib/
# Return Value: none
sub install_lib_dir
{
    my ($self)  = @_;
    my $config  = $self->{ _config };
    my $dst_dir = File::Spec->catfile($install_root, $self->path('lib_dir'));
    my $src_dir = '';

    print STDERR "updating $dst_dir\n";

    my $vendors = $config->get_as_array_ref('vendors');
    for my $vendor (@$vendors) {
	# XXX src = relative path, dst = absolute path
	$src_dir = File::Spec->catfile($vendor, "lib");
	print STDERR "    copy from $src_dir\n";
	$self->copy_dir( $src_dir, $dst_dir );
    }
}


# Descriptions: install executables.
#    Arguments: OBJ($self)
# Side Effects: update libexec/.
# Return Value: none
sub install_libexec_dir
{
    my ($self) = @_;

    # XXX src = relative path, dst = absolute path
    my $src_dir = File::Spec->catfile("fml", "libexec");
    my $dst_dir = File::Spec->catfile($install_root,
				      $self->path( 'libexec_dir' ));

    print STDERR "updating $dst_dir\n";
    $self->copy_dir( $src_dir, $dst_dir );
}


# Descriptions: install message files et.al.
#    Arguments: OBJ($self)
# Side Effects: update share/.
# Return Value: none
sub install_data_dir
{
    my ($self) = @_;

    # XXX src = relative path, dst = absolute path
    my $src_dir = File::Spec->catfile("fml", "share");
    my $dst_dir = File::Spec->catfile($install_root,
				      $self->path( 'data_dir' ));

    print STDERR "updating $dst_dir\n";
    $self->copy_dir( $src_dir, $dst_dir );
}


=head2 install_bin_programs()

install utitily programs typically located at /usr/local/bin.

=cut


# Descriptions: install utitily programs typically located at /usr/local/bin.
#    Arguments: OBJ($self)
# Side Effects: update /usr/lcoal/bin/.
# Return Value: none
sub install_bin_programs
{
    my ($self)  = @_;
    my $config  = $self->{ _config };
    my $progs   = $config->get_as_array_ref('bin_programs');
    my $dst_dir = $self->path( 'bindir' );

    for my $prog (@$progs) {
	# XXX src = relative path, dst = absolute path
	my $src = File::Spec->catfile("fml", "bin", $prog);
	my $dst = File::Spec->catfile($install_root, $dst_dir, $prog);

	print STDERR "updating $dst\n" if $debug;
	unless (-f $dst) {
	    $self->_need_resymlink_loader();
	}

	# override always
	$self->convert($src, $dst, 0755);
    }
}


=head1 LOADER

=head2 need_resymlink_loader()

check if we need to update loader symlink?

=head2 install_loader()

install loader.

=head2 resymlink_loader()

re-symlink loader.

=cut


# Descriptions: toggle on that we need to re-symlink loader.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _need_resymlink_loader }.
# Return Value: 1
sub _need_resymlink_loader
{
    my ($self) = @_;
    $self->{ _need_resymlink_loader } = 1;
}


# Descriptions: check if we need to update loader symlink?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_need_resymlink_loader
{
    my ($self) = @_;
    return( $self->{ _need_resymlink_loader } ? 1 : 0);
}


# Descriptions: check if we need to update loader symlink?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub need_resymlink_loader
{
    my ($self) = @_;
    my $status = 0;
    my $config = $self->{ _config };

    # XXX src = relative path, dst = absolute path
    my $loader      = File::Spec->catfile("fml", "libexec", "loader");
    my $libexec_dir = $config->{ libexec_dir };
    my $cur_loader  = File::Spec->catfile($install_root,
					  $libexec_dir, "loader");

    if ($debug) {
	print STDERR "cur $cur_loader\n";
	print STDERR "new $loader\n";
    }

    # when new bin/$program found
    return 1 if $self->_is_need_resymlink_loader();

    # first time
    unless (-f $cur_loader) {
	return 1;
    }

    my $cur_sum = $self->md5( $cur_loader ) || '';
    my $new_sum = $self->md5( $loader )     || '';

    # need to update loader.
    if ($cur_sum ne $new_sum) {
	use Term::ReadLine;
	my $term   = new Term::ReadLine 'Simple Perl calc';
	my $prompt = "You must upgrade loader. Replace it ? [y/n]: ";
	my $OUT    = $term->OUT || \*STDOUT;
	my $res    = '';

      READLINE:
	while (defined ($res = $term->readline($prompt))) {
	    if ($res eq 'y' || $res eq 'Y') {
		$status = 1;
		last READLINE;
	    }
	    warn $@ if $@;
	}
    }

    return $status;
}


# Descriptions: install loader (fml/libexec/loader).
#    Arguments: OBJ($self)
# Side Effects: update loader.
# Return Value: none
sub install_loader
{
    my ($self) = @_;
    my $config = $self->{ _config };

    # XXX src = relative path, dst = absolute path
    my $loader      = File::Spec->catfile("fml", "libexec", "loader");
    my $libexec_dir = $config->{ libexec_dir };
    my $cur_loader  = File::Spec->catfile($install_root,
					  $libexec_dir, "loader");
    my $tmp         = $cur_loader . ".$$";

    $self->_copy($loader, $tmp);
    chmod 0755, $tmp;

    unless (rename($tmp, $cur_loader)) {
	_errmsg("fail to rename $tmp $cur_loader");
    }

    unless (-f $cur_loader) {
	_errmsg("fail to install $cur_loader");
	croak("fail to install $cur_loader\n");
    }
}


# Descriptions: re-symlink executable to loader.
#    Arguments: OBJ($self)
# Side Effects: update symlink.
# Return Value: none
sub resymlink_loader
{
    my ($self)        = @_;
    my $config        = $self->{ _config };
    my $libexec_dir   = File::Spec->catfile($install_root,
					    $config->{ libexec_dir });
    my $cur_loader    = File::Spec->catfile($libexec_dir, "loader");

    my $bin_programs  = $config->get_as_array_ref('bin_programs');
    my $exec_programs = $config->get_as_array_ref('libexec_programs');

    chdir $libexec_dir || croak("fail to chdir $libexec_dir");

    print STDERR "symlink: loader to";
    my $p = length("symlink: loader to");
    my $n = $p;
    for my $prog (@$bin_programs, @$exec_programs) {
	$n += length(" $prog");
	print STDERR " $prog";

	unlink($prog);
	symlink("loader", $prog);

	if ($n > 72) {
	    print STDERR "\n";
	    print STDERR " " x $p;
	    $n = $p;
	}
    }
    print STDERR "\n";
}


=head1 SET UP ML SPOOL

=head2 setup_ml_spool_dir()

set up $ml_spool_dir e.g. /var/spool/ml.

=cut


# Descriptions: set up $ml_spool_dir.
#    Arguments: OBJ($self)
# Side Effects: mkdir and chown /var/spool/ml.
# Return Value: none
sub setup_ml_spool_dir
{
    my ($self) = @_;
    my $config = $self->{ _config };
    my $spool  = $self->path( 'ml_spool_dir' );
    my $dir    = File::Spec->catfile($install_root, $spool);
    my $owner  = $config->{ owner };
    my $group  = $config->{ group };

    if (-d $dir and -w $dir) {
	print STDERR " * info: $dir exists. not touch it.\n";
    }
    else {
	print STDERR "creating $dir\n";
	$self->mkdir( $dir );

	print STDERR "   chown $owner:$group $dir\n";
	$self->chown( $owner, $group, $dir );
    }
}


=head1 UTILITY FUNCTIONS

=head2 get_version()

return fml version.
return current-YYYYMMDD if ".version" file is not found.

=cut


# Descriptions: return fml version.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_version
{
    my ($self) = @_;
    my $vers   = '';

    if (-f ".version") {
	use FileHandle;
	my $fh   = new FileHandle ".version";
	if (defined $fh) {
	    chomp($vers = <$fh>);
	    $fh->close;
	}
    }

    unless ($vers) {
	use Mail::Message::Date;
	my $date = new Mail::Message::Date time;
	$vers    = sprintf("current-%s", $date->{ YYYYMMDD });
    }

    return $vers;
}


=head2 is_run_as_root()

check if the current process runs as root.

=cut


# Descriptions: check if the current process runs as root.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_run_as_root
{
    my ($self) = @_;

    if ($< == 0) {
	return 1;
    }

    return 0;
}


=head2 is_valid_owner( $owner )

check if $owner is a valid user ?

=head2 is_valid_group( $group )

check if $group is a valid group ?

=cut


# Descriptions: check if the $user is valid?
#    Arguments: OBJ($self) STR($user)
# Side Effects: croak() if critical error found.
# Return Value: NUM(1 or 0)
sub is_valid_owner
{
    my ($self, $user) = @_;

    use User::pwent;
    my $pw = getpwnam($user) || do {
	my $r = "no such user: $user";
	my $s = $self->message_nl("installer.no_such_user", $r);
	croak($r);
    };
    if ($pw->uid == 0) {
	my $r = "user should be not ROOT!";
	my $s = $self->message_nl("installer.no_root_user", $r);
	croak($r);
    }

    return 1;
}


# Descriptions: check if the $group is valid?
#    Arguments: OBJ($self) STR($group)
# Side Effects: croak() if critical error found.
# Return Value: NUM(1 or 0)
sub is_valid_group
{
    my ($self, $group) = @_;

    use User::grent;
    my $gr = getgrnam($group) || do {
	my $r = "no such group: $group";
	my $s = $self->message_nl("installer.no_such_group", $r);
	croak($r);
    };

    return 1;
}


=head2 path( $dir )

return the absolute directory path for the specified type C<$dir>.

=cut


# Descriptions: return the absolute dir path for the type $dir.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: STR
sub path
{
    my ($self, $dir) = @_;
    my $config       = $self->{ _config };
    my $version      = $self->get_version();
    my $config_dir   = $config->{ config_dir };

    if ($dir eq 'prefix'      ||
	$dir eq 'exec_prefix' ||
	$dir eq 'config_dir'  ||
	$dir eq 'bindir'      ||
	$dir eq 'mandir'      ||
	$dir eq 'ml_spool_dir') {
	return $config->{ $dir };
    }
    elsif ($dir eq 'default_config_dir') {
	return File::Spec->catfile($config->{ config_dir },
				   "defaults",
				   $version);
    }
    else {
	if (defined $config->{ $dir }) {
	    return File::Spec->catfile($config->{ $dir }, $version);
	}
	else {
	    return '';
	}
    }
}


=head1 UTILITY FUNCTIONS FOR FILE HANDLING

=head2 copy

=cut


# Descriptions: copy $src to $dst by preserving $atime and $mtime.
#    Arguments: OBJ($self) STR($src) STT($dst)
# Side Effects: create $dst
# Return Value: none
sub _copy
{
    my ($self, $src, $dst) = @_;

    use File::stat;
    my $st = stat($src);

    use File::Copy;
    copy($src, $dst);

    if (-f $dst) {
	my $atime = $st->atime;
	my $mtime = $st->mtime;
	utime $atime, $mtime, $dst;
    }
}


=head2 mkdir( $dir, [$mode] )

mkdir $dir with the mode $mode if $mode specified.
Whereas, mkdir $dir with the mode 0755 if $mode unspecified.

=head2 copy_dir( $src_dir, $dst_dir )

copy files recursively.

=head2 chown( $owner, $group, $dir )

chown $owner:$group $dir.

=cut


# Descriptions: mkdir $dir with the mode $mode.
#    Arguments: OBJ($self) STR($dir) NUM($mode)
# Side Effects: mkdir $dir
# Return Value: none
sub mkdir
{
    my ($self, $dir, $mode) = @_;

    unless (-d $dir) {
	use File::Path;
	mkpath( [ $dir ], 0, ($mode || 0755) );
    }
}


my @_cache = ();


# Descriptions: copy all files recursively.
#    Arguments: OBJ($self) STR($src_dir) STR($dst_dir)
# Side Effects: update $dst_dir
# Return Value: none
sub copy_dir
{
    my ($self, $src_dir, $dst_dir) = @_;

    @_cache = (); # XXX global in this package.

    use File::Find;
    find(\&_want_file, $src_dir);

    my $n;
    for my $file (@_cache) {
	$n = $file;
	$n =~ s@$src_dir@@;

	my $src = $file;
	my $dst = File::Spec->catfile( $dst_dir, $n );

	my $src_dir = dirname($src);
	my $dst_dir = dirname($dst);
	unless (-d $dst_dir) {
	    print STDERR " ** ? ** $dst_dir\n" if -f $dst_dir;
	    $self->mkdir( $dst_dir );
	}

	if (-f $src && -d $dst_dir) {
	    $self->_copy($src, $dst);
	}
	else {
	    print "warning $src -> $dst\n" if $debug;
	}
    }
}


# Descriptions: subroutine used by File::Find().
#    Arguments: none
# Side Effects: update @_cache
# Return Value: none
sub _want_file
{
    my ($s) = $File::Find::name;

    if ($s !~ /CVS/) {
	push(@_cache, $s);
    }
}


# Descriptions: chown utility.
#    Arguments: OBJ($self) STR($owner) STR($group) STR($dir)
# Side Effects: change owner and group of $dir
# Return Value: none
sub chown
{
    my ($self, $owner, $group, $dir) = @_;

    use User::pwent;
    my $pw  = getpwnam($owner) || croak("no such user: $owner");
    my $uid = $pw->uid;

    use User::grent;
    my $gr  = getgrnam($group) || croak("no such group: $group");
    my $gid = $gr->gid;

    @_cache = (); # XXX global in this package.

    use File::Find;
    find(\&_want_file, $dir);

    for my $file (@_cache) {
	print STDERR "chown $uid, $gid, $file\n" if $debug;
	chown $uid, $gid, $file;
    }
}


=head2 md5( $file )

return MD5 checksum for the file.

=cut


# Descriptions: return MD5 checksum for the file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub md5
{
    my ($self, $file) = @_;
    my $buf = '';

    my $fh  = new FileHandle $file;
    if (defined $fh) {
	my $xbuf;
	while ($xbuf = <$fh>) { $buf .= $xbuf;}
	$fh->close();
    }

    use Mail::Message::Checksum;
    my $cksum = new Mail::Message::Checksum;
    my $sum   = $cksum->md5( \$buf );

    return $sum;
}


=head1 MESSAGE MANIPULATION

=head2 message_nl($clss, $default_msg)

return message by natural language.

=cut


# Descriptions: return message by natural language.
#    Arguments: OBJ($self) STR($class) STR($default_msg)
# Side Effects: none
# Return Value: STR
sub message_nl
{
    my ($self, $class, $default_msg) = @_;
    my $charset ||= 'us-ascii';

    use File::Spec;
    $class =~ s@\.@/@g; # XXX . -> /

    my $msg_dir  = File::Spec->catfile("fml", "share", "message");
    my $msg_file = File::Spec->catfile($msg_dir, $charset, $class);

    if (-f $msg_file) {
	return $self->_import_message_from_file($msg_file);
    }
    else {
	return $default_msg;
    }
}


# Descriptions: get message from file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: STR
sub _import_message_from_file
{
    my ($self, $file) = @_;
    my $buf = '';

    use FileHandle;
    my $fh = new FileHandle $file;
    if (defined $fh) {
        my $xbuf;
        while ($xbuf = <$fh>) { $buf .= $xbuf;}
        $fh->close();
    }

    return $buf;
}


=head2 enable_message()

enable verbose message output.

=head2 disable_message()

disable verbose message output.

=cut


# Descriptions: enable message output.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _show_message }.
# Return Value: NUM
sub enable_message
{
    my ($self) = @_;
    $self->{ _show_message } = 1;
}


# Descriptions: disable message output.
#    Arguments: OBJ($self)
# Side Effects: update $self->{ _show_message }.
# Return Value: NUM
sub disable_message
{
    my ($self) = @_;
    $self->{ _show_message } = 0;
}


# Descriptions: check if we show message
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub _is_show_message
{
    my ($self) = @_;
    return $self->{ _show_message };
}


# Descriptions: show error message by some predefined fomrat.
#    Arguments: STR($s)
# Side Effects: none
# Return Value: none
sub _errmsg
{
    my ($s) = @_;
    print STDERR " * error: $s\n";
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

FML::Install appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
