#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#
# $FML: SimpleLock.pm,v 1.18 2003/01/11 15:16:33 fukachan Exp $
#

package File::SimpleLock;

use vars qw(%LockedFileHandle %FileIsLocked @ISA $Error);
use strict;
use Carp;
use ErrorStatus qw(error_set error error_clear);


#
# XXX-TODO: merge this module into IO::Adapter.
#

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

=head2 lock($args)

flock(2) for $args->{ file };

=head2 unlock($args)

unlock flock(2) for $args->{ file };

=cut


use Fcntl qw(:DEFAULT :flock);


# Descriptions: standard constructor.
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


# Descriptions: lock
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub lock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    $self->_simple_flock($file);
}


# Descriptions: unlock
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub unlock
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    $self->_simple_funlock($file);
}



# Descriptions: try flock(2) for $file
#    Arguments: OBJ($self) STR($file)
# Side Effects: flock for $file
# Return Value: 1 or 0
sub _simple_flock
{
    my ($self, $file) = @_;

    use FileHandle;
    my $fh = new FileHandle ">> $file";

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


# Descriptions: try unlock by flock(2) for $file
#    Arguments: OBJ($self) STR($file)
# Side Effects: flock for $file
# Return Value: 1 or 0
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

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

File::SimpleLock first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
