#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.7 2004/07/23 15:59:08 fukachan Exp $
#

package FML::Merge::FML4::List;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Merge::FML4::List - convert member list files.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($m_config)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $m_config) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {
	_curproc  => $curproc,
	_m_config => $m_config,
    };

    return bless $me, $type;
}


# Descriptions: convert list files from fml4 to fml8 format.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($self)   = @_;
    my $m_config = $self->{ _m_config };

    use FML::Merge::FML4::Config;
    my $config = new FML::Merge::FML4::Config;
    my $files  = $config->get_old_list_files();
    my $fp;

    for my $file (@$files) {
	$fp = "_convert_$file";
	$fp =~ s/-/_/g;
	$fp =~ s@/@_@g;
	if ($self->can($fp)) {
	    $self->$fp($m_config);
	}
	else {
	    croak("cannot convert $file");
	}
    }
}


# Descriptions: convert fml4 actives to fml8 recipients file.
#    Arguments: OBJ($self) OBJ($m_config)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_actives
{
    my ($self, $m_config) = @_;
    my $src = $m_config->backup_file_path('actives');
    my $dst = $m_config->new_file_path('recipients');

    $self->_write_without_comment($src, $dst);
}


# Descriptions: convert fml4 members to fml8 members file.
#    Arguments: OBJ($self) OBJ($m_config)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_members
{
    my ($self, $m_config) = @_;
    my $src = $m_config->backup_file_path('members');
    my $dst = $m_config->new_file_path('members');

    $self->_write_without_comment($src, $dst);
}


# Descriptions: convert fml4 members-admin to
#               fml8 {recipients,members}-admin file.
#    Arguments: OBJ($self) OBJ($m_config)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_members_admin
{
    my ($self, $m_config) = @_;
    my $src = $m_config->backup_file_path('members-admin');
    my $dst = $m_config->new_file_path('members-admin');

    $self->_write_without_comment($src, $dst);

    $dst = $m_config->new_file_path('recipients-admin');
    $self->_write_without_comment($src, $dst);
}


# Descriptions: convert fml4 moderators to
#               fml8 {recipients,members}-moderator file.
#    Arguments: OBJ($self) OBJ($m_config)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_moderators
{
    my ($self, $m_config) = @_;
    my $src = $m_config->backup_file_path('moderators');
    my $dst = $m_config->new_file_path('members-moderator');

    $self->_write_without_comment($src, $dst);

    $dst = $m_config->new_file_path('recipients-moderator');
    $self->_write_without_comment($src, $dst);
}


# Descriptions: convert fml4 etc/passwd to fml8 etc/passwd-admin.
#    Arguments: OBJ($self) OBJ($m_config)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_etc_passwd
{
    my ($self, $m_config) = @_;
    my $src = $m_config->backup_file_path('etc/passwd');
    my $dst = $m_config->new_file_path('etc/passwd-admin');

    # XXX-TODO: NOT YET IMPLEMENTED
    print STDERR "warning: etc/passwrd conversion not yet implemented\n";
}


# Descriptions: filter output by removing comment line.
#    Arguments: OBJ($self) STR($src) STR($dst)
# Side Effects: create $dst file.
# Return Value: none
sub _write_without_comment
{
    my ($self, $src, $dst) = @_;
    my $tmp = sprintf("%s.new.%s", $dst, $$);

    unless (-f $src) {
	print STDERR "warning: $src not found, so not converted.\n";
	return;
    }

    print STDERR "creating $dst\n";
    print STDERR "    from $src\n";

    use FileHandle;
    my $rh = new FileHandle $src;
    my $wh = new FileHandle "> $tmp";
    if (defined $rh && defined $wh) {
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    next LINE if $buf =~ /^\#/o;
	    print $wh $buf;
	}
	$wh->close();
	$rh->close();

	unless (rename($tmp, $dst)) {
	    croak("cannot rename $tmp $dst");
	}
    }
    else {
	croak("cannot open $src") unless defined $rh;
	croak("cannot open $tmp") unless defined $wh;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge::FML4::List appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
