#-*- perl -*- 
# 
# Copyright (C) 2000 Ken'ichi Fukamachi 
# 
# $Id$ 
# $FML$ 
#

package File::SimpleLock;

use vars qw(%LockedFileHandle %FileIsLocked @ISA $Error);
use strict;
use Carp;

=head1 NAME

File::SimpleLock - simple lock by flock(2)

=head1 SYNOPSIS

    require File::SimpleLock;
    my $lockobj = new File::SimpleLock;
    $lockobj->lock( { file => $lock_file } ) || croak "fail to lock";

       ... do someting under locking ...

    $lockobj->unlock( { file => $lock_file } ) || croak "fail to unlock";

=head1 DESCRIPTION

File::SimpleLock.pm contains several interfaces for several files,
for example, Lockfiles, sysLock() (not yet implemented).

=item Lock( $message )

The argument is the message to Lock.

=cut

require Exporter;
@ISA = qw(Exporter);


# constants
use POSIX qw(EAGAIN ENOENT EEXIST O_EXCL O_CREAT O_RDONLY O_WRONLY); 
sub LOCK_SH {1;}
sub LOCK_EX {2;}
sub LOCK_NB {4;}
sub LOCK_UN {8;}


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub _error_reason
{
    my $msg = @_;
    $Error = $msg;
}


sub error
{
    my ($self) = @_;
    $Error;
}


sub lock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    _simple_flock($file);
}


sub unlock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    _simple_funlock($file);
}



sub _simple_flock
{
    my ($file) = @_;

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	$LockedFileHandle{ $file } = $fh;

	my $r = 0; # return value 
	eval q{
	    $r = flock($fh, &LOCK_EX);
	};
	_error_reason($@) if $@;

	if ($r) {
	    $FileIsLocked{ $file } = 1;
	    return 1;
	}
    }
    else {
	_error_reason("cannot open $file");
    }

    return 0;
}


sub _simple_funlock
{
    my ($file) = @_;

    return 0 unless $FileIsLocked{ $file };
    return 0 unless $LockedFileHandle{ $file };

    my $fh = $LockedFileHandle{ $file };

    my $r = 0; # return value 
    eval q{
	$r = flock($fh, &LOCK_UN);
    };
    _error_reason($@) if $@;

    if ($r) {
	delete $FileIsLocked{ $file };
	delete $LockedFileHandle{ $file };
	return 1;
    }

    return 0;
}


=head1 SEE ALSO

L<FileHandle>

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>

=head1 COPYRIGHT

Copyright (C) 2000 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::SimpleLock appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
