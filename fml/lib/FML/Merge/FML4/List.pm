#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.3 2004/03/17 04:30:20 fukachan Exp $
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

=head2 C<new()>

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

    return bless $me, $type;
}


# Descriptions: convert list files from fml4 to fml8 format.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $params  = $self->{ _params } || {};

    use FML::Merge;
    my $merge = new FML::Merge $curproc, $params;

    use FML::Merge::FML4::Config;
    my $config = new FML::Merge::FML4::Config;
    my $files  = $config->get_old_list_files();
    my $fp;

    for my $file (@$files) {
	$fp = "_convert_$file";
	$fp =~ s/-/_/g;
	$fp =~ s@/@_@g;
	if ($self->can($fp)) {
	    $self->$fp($merge);
	}
	else {
	    croak("cannot convert $file");
	}
    }
}


# Descriptions: convert fml4 actives to fml8 recipients.
#    Arguments: OBJ($self) OBJ($merge)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_actives
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('actives');
    my $dst = $merge->new_file_path('recipients');

    $self->_write_without_comment($src, $dst);
} 


# Descriptions: convert fml4 members to fml8 members.
#    Arguments: OBJ($self) OBJ($merge)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_members
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('members');
    my $dst = $merge->new_file_path('members');

    $self->_write_without_comment($src, $dst);
} 


# Descriptions: convert fml4 members-admin to fml8 {recipients,members}-admin.
#    Arguments: OBJ($self) OBJ($merge)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_members_admin
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('members-admin');
    my $dst = $merge->new_file_path('members-admin');

    $self->_write_without_comment($src, $dst);

    $dst = $merge->new_file_path('recipients-admin');
    $self->_write_without_comment($src, $dst);
} 


# Descriptions: convert fml4 moderators to fml8 {recipients,members}-moderator.
#    Arguments: OBJ($self) OBJ($merge)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_moderators
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('moderators');
    my $dst = $merge->new_file_path('members-moderator');

    $self->_write_without_comment($src, $dst);

    $dst = $merge->new_file_path('recipients-moderator');
    $self->_write_without_comment($src, $dst);
} 


# Descriptions: convert fml4 etc/passwd to fml8 etc/passwd-admin.
#    Arguments: OBJ($self) OBJ($merge)
# Side Effects: create fml8 file.
# Return Value: none
sub _convert_etc_passwd
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('etc/passwd');
    my $dst = $merge->new_file_path('etc/passwd-admin');

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

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Merge::FML4::List appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
