#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: List.pm,v 1.1.1.1 2004/03/16 12:58:20 fukachan Exp $
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


sub _convert_actives
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('actives');
    my $dst = $merge->new_file_path('recipients');

    $self->_write_without_comment($src, $dst);
} 


sub _convert_members
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('members');
    my $dst = $merge->new_file_path('members');

    $self->_write_without_comment($src, $dst);
} 


sub _convert_members_admin
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('members-admin');
    my $dst = $merge->new_file_path('members-admin');

    $self->_write_without_comment($src, $dst);

    $dst = $merge->new_file_path('recipients-admin');
    $self->_write_without_comment($src, $dst);
} 


sub _convert_moderators
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('moderators');
    my $dst = $merge->new_file_path('members-moderator');

    $self->_write_without_comment($src, $dst);

    $dst = $merge->new_file_path('recipients-moderator');
    $self->_write_without_comment($src, $dst);
} 


sub _convert_etc_passwd
{
    my ($self, $merge) = @_;
    my $src = $merge->backup_file_path('etc/passwd');
    my $dst = $merge->new_file_path('etc/passwd-admin');

    print STDERR "warning: etc/passwrd conversion not yet implemented\n";
} 


sub _write_without_comment
{
    my ($self, $src, $dst) = @_;
    my $tmp = sprintf("%s.new.%s", $dst, $$);

    unless (-f $src) {
	print STDERR "ignore $src -> $dst\n";
	return;
    }

    print STDERR "cat $src > $dst\n";

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
