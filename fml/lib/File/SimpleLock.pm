#-*- perl -*- 
# 
# Copyright (C) 2000 Ken'ichi Fukamachi 
# 
# $Id$ 
# $FML: SimpleLock.pm,v 1.6 2001/04/03 09:31:27 fukachan Exp $ 
#

package File::SimpleLock;

use vars qw(%LockedFileHandle %FileIsLocked @ISA $Error);
use strict;
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

File::SimpleLock - simple lock by flock(2)

=head1 SYNOPSIS

    use File::SimpleLock;
    my $lockobj = new File::SimpleLock;
    $lockobj->lock( { file => $lock_file } ) || croak "fail to lock";

       ... do someting under locking ...

    $lockobj->unlock( { file => $lock_file } ) || croak "fail to unlock";

=head1 DESCRIPTION

File::SimpleLock module provides simple lock using flock(2).

=head1 METHODS

=head2 C<lock($args)>

flock(2) for $args->{ file };

=head2 C<unlock($args)> 

unlock flock(2) for $args->{ file };

=cut


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


sub lock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    $self->_simple_flock($file);
}


sub unlock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    $self->_simple_funlock($file);
}



sub _simple_flock
{
    my ($self, $file) = @_;

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	$LockedFileHandle{ $file } = $fh;

	my $r = 0; # return value 
	eval q{
	    $r = flock($fh, &LOCK_EX);
	};
	$self->error_set($@) if $@;

	if ($r) {
	    $FileIsLocked{ $file } = 1;
	    return 1;
	}
    }
    else {
	$self->error_set("cannot open $file");
    }

    return 0;
}


sub _simple_funlock
{
    my ($self, $file) = @_;

    return 0 unless $FileIsLocked{ $file };
    return 0 unless $LockedFileHandle{ $file };

    my $fh = $LockedFileHandle{ $file };

    my $r = 0; # return value 
    eval q{
	$r = flock($fh, &LOCK_UN);
    };
    $self->error_set($@) if $@;

    if ($r) {
	delete $FileIsLocked{ $file };
	delete $LockedFileHandle{ $file };
	return 1;
    }

    return 0;
}


=head1 SEE ALSO

L<FileHandle>,
L<ErrorStatus>,

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>

=head1 COPYRIGHT

Copyright (C) 2000,2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::SimpleLock appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
