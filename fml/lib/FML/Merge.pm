#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Merge.pm,v 1.6 2004/03/17 12:55:03 fukachan Exp $
#

package FML::Merge;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Merge::Utils;
push(@INC, qw(FML::Merge::Utils));


=head1 NAME

FML::Merge - merge other system configurations to fml8 ones.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut



# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($params)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $params) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { 
	_curproc => $curproc,
	_params  => $params,
    };

    # import variables: ml_* ...
    for my $x (keys %$params) {
	$me->{ "_$x" } = $params->{ $x } if defined $params->{ $x };
    };

    # back up to $ml_home_dir/.fml4rc/ directory.
    #    $ml_home_dir/.fml4rc/
    #    $ml_home_dir/.fml4rc/etc/
    use File::Spec;
    my $ml_home_dir = $params->{ ml_home_dir } || '';
    if ($ml_home_dir) {
	my $x_dir = File::Spec->catfile($ml_home_dir, ".fml4rc");
	$me->{ _backup_dir } = $x_dir;
	$curproc->mkdir($x_dir, "mode=private") unless -d $x_dir;

	$x_dir = File::Spec->catfile($ml_home_dir, ".fml4rc", "etc");
	$curproc->mkdir($x_dir, "mode=private") unless -d $x_dir;
    }
    else {
	croak("specify \$ml_home_dir");
    }

    return bless $me, $type;
}


# Descriptions: specify target system.
#    Arguments: OBJ($self) STR($system)
# Side Effects: none
# Return Value: none
sub set_target_system
{
    my ($self, $system) = @_;

    # dummy yet.
}


=head1 BACK UP CONFIGURATION FILES

=cut


# Descriptions: back up old configuration files.
#    Arguments: OBJ($self)
# Side Effects: move or copy files.
# Return Value: none
sub backup_old_config_files
{
    my ($self) = @_;

    use FML::Merge::FML4::Config;
    my $config = new FML::Merge::FML4::Config;
    my $files  = $config->get_old_config_files();
    for my $f (@$files) {
	my $mode = $self->_need_copy() ? "copy" : $config->backup_mode($f);
	my $src  = $self->old_file_path($f);
	my $dst  = $self->backup_file_path($f);

	if (-f $src) {
	    if ($mode eq 'move') {
		printf STDERR "renaming %-30s -> %-30s\n", $src, $dst;
		rename($src, $dst) || croak("cannot rename $src $dst");
	    }
	    elsif ($mode eq 'copy') {
		printf STDERR "copying: %-30s -> %-30s\n", $src, $dst;
		use IO::Adapter::AtomicFile;
		IO::Adapter::AtomicFile->copy($src, $dst);
	    }
	    else {
		print STDERR "error:   unknown mode (DO NOTHING).\n";
	    }
	}
    }

    # continuous use: summary, log, seq ...
    my $cont_files = $config->get_continuous_use_files();
    for my $f (@$cont_files) {
	my $src  = $self->backup_file_path($f);
	my $dst  = $self->new_file_path($f);
	printf STDERR "copying: %-30s -> %-30s\n", $src, $dst;
	use IO::Adapter::AtomicFile;
        IO::Adapter::AtomicFile->copy($src, $dst);	
    }
}


# Descriptions: check if we always need copy files to back up dir.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _need_copy
{
    my ($self)       = @_;
    my $old_home_dir = $self->{ _src_dir };
    my $ml_home_dir  = $self->{ _ml_home_dir };

    if ($old_home_dir ne $ml_home_dir) {
	return 1;
    }
    else {
	return 0;
    }
}


=head1 DISABLE INCLUDE FILES

To cause temporary failure, disable old include* files by changing it
to "exit 75".

Code 75 depends on the value of EX_TEMPFAIL of your system. See
/usr/include/sysexit.h for more details.

For example, the value of NetBSD follows.

     EX_TEMPFAIL -- temporary failure, indicating something that
              is not really an error.  In sendmail, this means
              that a mailer (e.g.) could not create a connection,
              and the request should be reattempted later.

=cut


sub disable_old_include_files
{
    my ($self) = @_;

    use FML::Merge::FML4::Config;
    my $config = new FML::Merge::FML4::Config;
    my $files  = $config->get_old_include_files();

    for my $f (@$files) {
	my $file = $self->old_file_path($f);
	print STDERR "disable: $file\n";
	use IO::Adapter::AtomicFile;
        IO::Adapter::AtomicFile->copy($file, "$file.bak");
	my $wh = new FileHandle "> $file.tmp";
	if (defined $wh) {
	    print $wh "exit 75\n"; # EX_TEMPFAIL
	    $wh->close();

	    unless (rename("$file.tmp", $file)) {
		croak("fail to rename $file.tmp to $file");
	    }
	}
	else {
	    croak("fail to create $file.tmp");
	}
    }
}


sub enable_old_include_files
{
    my ($self) = @_;

    use FML::Merge::FML4::Config;
    my $config = new FML::Merge::FML4::Config;
    my $files  = $config->get_old_include_files();

    for my $f (@$files) {
	my $file = $self->old_file_path($f);
	print STDERR "enable $file\n";
	print STDERR "   mv $file.bak $file\n";
    }
}


=head1

=cut


sub convert_list_files
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $params  = $self->{ _params } || {};

    use FML::Merge::FML4::List;
    my $list = new FML::Merge::FML4::List $curproc, $params;
    $list->convert();
}


=head1

=cut


sub merge_into_config_cf
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $params  = $self->{ _params } || {};

    # files to compare.
    my $old_config_ph     = $self->old_file_path("config.ph");
    my $default_config_ph = "/tmp/default_config.ph";

    use FML::Merge::FML4::config_ph;
    my $config_ph = new FML::Merge::FML4::config_ph;
    $config_ph->set_default_config_ph("/tmp/default_config.ph"); 
    my $diff      = $config_ph->diff($old_config_ph);
    $self->_inject_into_config_cf($diff);
}


sub _inject_into_config_cf
{
    my ($self, $diff) = @_;
    my $config_cf = $self->new_file_path("config.cf");
    my $tmp       = "$config_cf.new.$$";

    print STDERR "merging: $config_cf\n";
    my $rh = new FileHandle $config_cf;
    my $wh = new FileHandle "> $tmp";
    if (defined $rh && defined $wh) {
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    if ($buf =~ /^=cut/o) {
		$self->_inject_diff_into_config_cf($wh, $diff);
	    }

	    print $wh $buf;
	}

	$wh->close();
	$rh->close();

	unless (rename($tmp, $config_cf)) {
	    croak("cannot rename $tmp to $config_cf");
	}
    }
}


sub _inject_diff_into_config_cf
{
    my ($self, $wh, $diff) = @_;
    my ($k, $v, $x, $y);

    print $wh "\n";
    print $wh "# BEGIN OF CONFIG CONVERSION\n";
    print $wh "\n";

    use FML::Merge::FML4::config_ph;
    my $config_ph = new FML::Merge::FML4::config_ph;

    for my $k (sort _sort_order keys %$diff) {
	$v = $diff->{ $k };
	$y = $v;
	$y =~ s/\n/\n# /gm;
	print $wh "# $k => $y\n";

	if ($x = $config_ph->translate($k, $v)) {
	    print $wh $x ,"\n";
	}
    }

    print $wh "\n";
    print $wh "# END OF CONFIG CONVERSION\n";
    print $wh "\n";
}


sub _sort_order
{
    my $x = $a;
    my $y = $b;

    $x = "zz_$x"  if $x =~ /^PROC__/o;
    $y = "zz_$y"  if $y =~ /^PROC__/o;
    $x = "zzz_$x" if $x =~ /HOOK/o;
    $y = "zzz_$y" if $y =~ /HOOK/o;

    $x cmp $y;
}


=head1 UTILITIES

=cut


sub old_file_path
{
    my ($self, $file) = @_;
    my $old_home_dir  = $self->{ _src_dir };

    use File::Spec;
    return File::Spec->catfile($old_home_dir, $file);
}


sub new_file_path
{
    my ($self, $file) = @_;
    my $ml_home_dir   = $self->{ _ml_home_dir };

    use File::Spec;
    return File::Spec->catfile($ml_home_dir, $file);
}


sub backup_file_path
{
    my ($self, $file) = @_;
    my $back_up_dir   = $self->{ _backup_dir };

    use File::Spec;
    return File::Spec->catfile($back_up_dir, $file);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
