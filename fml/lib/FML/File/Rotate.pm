#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Rotate.pm,v 1.4 2004/07/23 12:39:17 fukachan Exp $
#

package FML::File::Rotate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

BEGIN {}
END   {}

=head1 NAME

FML::File::Rotate - file rotatation utilities.

=head1 SYNOPSIS

    my $logrotate = new FML::File::Rotate $curproc;
    if ($logrotate->is_time_to_rotate($file)) {
	$logrotate->rotate($file);
    }

=head1 DESCRIPTION

Utility functions for file rotate operations.
It turns over the given C<file> by some condition.
Typical condition is given as the number of files or how old they are.

C<rotation> renames and rearranges files like this:

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

In old age, shell script does this but
in modern unix,
some programs such as /usr/bin/newsyslog (MIT athena project) do.

=head1 METHODS

=head2 new($curproc)

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
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head1 PARAMETERS

=head2 set_max_size($size)

set max_size.

=head2 get_max_size()

get max_size.

=head2 set_num_backlog($num)

set number of backlog files.

=head2 get_num_backlog()

get number of backlog files.

=cut


# Descriptions: set max_size.
#    Arguments: OBJ($self) NUM($size)
# Side Effects: update $self.
# Return Value: none
sub set_max_size
{
    my ($self, $size) = @_;
    my $curproc = $self->{ _curproc };

    if (defined $size && $size =~ /^\d+$/o) {
	$self->{ _max_size } = $size;
    }
    else {
	$curproc->logerror("set_max_size: invalid data: $size");
    }
}


# Descriptions: get max_size.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_max_size
{
    my ($self) = @_;

    return( $self->{ _max_size } || 300*1024 );
}


# Descriptions: set number of backlog files.
#    Arguments: OBJ($self) NUM($num)
# Side Effects: update $self
# Return Value: none
sub set_num_backlog
{
    my ($self, $num) = @_;
    my $curproc = $self->{ _curproc };

    if (defined $num && $num =~ /^\d+$/o) {
	$self->{ _num_backlog } = $num || 4;
    }
    else {
	$curproc->logerror("set_num_backlog: invalid data: $num");
    }
}


# Descriptions: get number of backlog files.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_num_backlog
{
    my ($self) = @_;

    return( $self->{ _num_backlog } || 4 );
}


=head2 is_time_to_rotate()

C<stat()> the file correspoinding to the object and
determine whether the time to do comes or not.

=cut


# Descriptions: determine if the time to rotate comes.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: NUM(1 (time comes!) or 0)
sub is_time_to_rotate
{
    my ($self, $file) = @_;
    my $size = $self->get_max_size();

    use File::stat;
    my $st = stat($file);

    return 1 if $st->size > $size;
    return 0;
}


=head2 rotate($file)

rename files to rotate it.

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

=cut


# Descriptions: rotate file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: rename in proper way and unlink the oldest file if needed.
# Return Value: none
sub rotate
{
    my ($self, $file) = @_;
    my $size = $self->get_max_size();
    my $max  = $self->get_num_backlog();

    # remove oldest file
    my $maxfile = sprintf("%s.%s", $file, $max);
    if (-f $maxfile) { unlink $maxfile;}

    # mv var/log/file.3 -> var/log/file.4 ...;
    do {
	my $old = sprintf("%s.%s", $file, ($max - 1 > 0 ? $max - 1 : 0));
	my $new = sprintf("%s.%s", $file, $max);
	-f $old && rename($old, $new);
	$max--;
    } while ($max > 0);

    my $bak = sprintf("%s.%s", $file, 0);
    rename($file, $bak);
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

FML::File::Rotate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

FML::File::Rotate (2001-2003) is renamed from File::Rotate class in
2004.

=cut


1;
