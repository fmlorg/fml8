#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Journal.pm,v 1.4 2003/12/31 03:49:15 fukachan Exp $
#

package FML::Cache::Journal;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Cache::Journal - interface into Tie::JournaledDir.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new($curproc)

=head2 open($cache_dir, $class)

=head2 close()

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: create object
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    return bless $me, $type;
}


# Descriptions: open database via Tie::JournaledDir.
#    Arguments: OBJ($self) STR($cache_dir) STR($class)
# Side Effects: open database, mkdir if needed
# Return Value: HASH_REF to dabase
sub open
{
    my ($self, $cache_dir, $class) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $mode    = $config->{ directory_private_mode } || 0700;
    my (%db)    = ();

    use File::Spec;
    my $dir = File::Spec->catfile($cache_dir, $class);
    unless (-d $dir) {
	$curproc->mkdir($dir, $mode);
    }

    use Tie::JournaledDir;
    tie %db, 'Tie::JournaledDir', { dir => $dir };

    $self->{ _db } = \%db;

    return \%db;
}


# Descriptions: close database.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub close
{
    my ($self) = @_;
    my $db = $self->{ _db };
    if (defined $db) {
	untie %$db;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Cache::Journal appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
