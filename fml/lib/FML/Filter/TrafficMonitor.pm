#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: TrafficMonitor.pm,v 1.4 2002/01/16 13:43:20 fukachan Exp $
#

package FML::Filter::TrafficMonitor;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::TrafficMonitor - Mail Traffic Information

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut

use File::CacheDir;
@ISA = qw(File::CacheDir);


# Descriptions: 
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: open cache and return C<File::CacheDir> object.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: 
# Return Value: none
sub _open_cache
{
    my ($self, $db, $args) = @_;
    my $dir  = $args->{ 'directory' };
    my $mode = 'temporal';
    my $days = 14;

    if ($dir) {
        my $obj = new File::CacheDir {
            directory  => $dir,
            cache_type => $mode,
            expires_in => $days,
        };

        $self->{ _obj } = $obj;
        return $obj;
    }

    undef;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::TrafficMonitor appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
