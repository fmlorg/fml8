#-*- perl -*-
#
#  Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Rotate.pm,v 1.8 2006/07/09 12:11:12 fukachan Exp $
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

    my $log = new FML::File::Rotate $curproc;
    if ($log->is_time_to_rotate($file)) {
	$log->rotate($file);
    }

=head1 DESCRIPTION

This module provides utility functions for file rotatation.
It turns over the given files under some condition.
Typical condition is given as the number of files, size or how old they are.

C<rotation> renames and rearranges files like this:

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

In old age, a shell script does this but
in modern unix,
some programs such as /usr/bin/newsyslog (MIT athena project) do it.
See newsyslog(8) for more details.

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

=head2 set_size_limit($size)

set the maximum size limit.

When the size of the log file reaches this limit, the log file will be
turned over.

=head2 get_size_limit()

get the maximum size limit.

=head2 set_archive_file_total($num)

set the number of archive log files to be kept besides the log file itself.

=head2 get_archive_file_total()

get the number of archive log files to be kept besides the log file itself.

=cut


# Descriptions: set max_size.
#    Arguments: OBJ($self) NUM($size)
# Side Effects: update $self.
# Return Value: none
sub set_size_limit
{
    my ($self, $size) = @_;
    my $curproc = $self->{ _curproc };

    if (defined $size && $size =~ /^\d+$/o) {
	$self->{ _max_size } = $size;
    }
    else {
	$curproc->logerror("set_size_limit: invalid data: $size");
    }
}


# Descriptions: get max_size. 300K bytes by default.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_size_limit
{
    my ($self) = @_;

    return( $self->{ _max_size } || 300*1024 );
}


# Descriptions: set the number of backlog files.
#    Arguments: OBJ($self) NUM($num)
# Side Effects: update $self
# Return Value: none
sub set_archive_file_total
{
    my ($self, $num) = @_;
    my $curproc = $self->{ _curproc };

    if (defined $num && $num =~ /^\d+$/o) {
	$self->{ _archive_log_total } = $num || 4;
    }
    else {
	$curproc->logerror("set_archive_file_total: invalid data: $num");
    }
}


# Descriptions: get the number of backlog files.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_archive_file_total
{
    my ($self) = @_;

    return( $self->{ _archive_log_total } || 4 );
}


=head2 is_time_to_rotate()

C<stat()> the file correspoinding to the object and
determine whether the time to rotate comes or not.

=cut


# Descriptions: determine if the time to rotate comes.
#    Arguments: OBJ($self) STR($file)
# Side Effects: none
# Return Value: NUM(1 (time comes!) or 0)
sub is_time_to_rotate
{
    my ($self, $file) = @_;
    my $size_limit = $self->get_size_limit();

    use File::stat;
    my $st = stat($file);
    if (defined $st) {
	if ($st->size > $size_limit) {
	    return 1;
	}
	else {
	    my $curproc = $self->{ _curproc } || undef;
	    if (defined $curproc) {
		$curproc->logdebug("not turn over $file: size < $size_limit");
	    }
	}
    }

    return 0;
}


=head2 rotate($file)

rename files to rotate.

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

=cut


# Descriptions: rotate files.
#    Arguments: OBJ($self) STR($file)
# Side Effects: rename in proper way and unlink the oldest file if needed.
# Return Value: none
sub rotate
{
    my ($self, $file) = @_;

    # 1. remove the oldest file if it exists.
    my $max     = $self->get_archive_file_total();
    my $maxfile = sprintf("%s.%s", $file, $max);
    if (-f $maxfile) { unlink $maxfile;}

    # 2. turn over: e.g. mv var/log/file.3 -> var/log/file.4 ...;
    do {
	my $old = sprintf("%s.%s", $file, ($max - 1 > 0 ? $max - 1 : 0));
	my $new = sprintf("%s.%s", $file, $max);
	-f $old && rename($old, $new);
	$max--;
    } while ($max > 0);

    my $bak = sprintf("%s.%s", $file, 0);
    rename($file, $bak);
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    system "touch /tmp/log /tmp/log.0 /tmp/log.1 /tmp/log.2";

    use FML::Process::Debug;
    my $curproc = new FML::Process::Debug;

    my $log = new FML::File::Rotate $curproc;
    $log->set_size_limit(10000);
    $log->set_archive_file_total(3);

    my $file = "/tmp/log";
    if ($log->is_time_to_rotate($file)) {
	$log->rotate($file);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 SEE ALSO

newsyslog(8).

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::File::Rotate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

FML::File::Rotate (2001-2003) is renamed from File::Rotate class in
2004.

=cut


1;
