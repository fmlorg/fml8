#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: DB.pm,v 1.4 2001/11/03 07:42:35 fukachan Exp $
#

package Mail::ThreadTrack::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::ThreadTrack::DB - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 C<db_open()>

open DB.
It uses tie() to bind a hash to a DB file.
Our minimal_states uses several DB files for
C<%thread_id>,
C<%date>,
C<%status>,
C<%sender>,
C<%articles>,
C<%message_id>
and
C<%index>.

=head2 C<db_close()>

untie() corresponding hashes opened by C<db_open()>.

=cut


my @kind_of_databases = qw(thread_id
                           date
			   status
			   sender
			   articles
			   message_id);


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub db_open
{
    my ($self) = @_;
    my $db_type = $self->{ config }->{ db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _db_dir };

    eval qq{ use $db_type; use Fcntl;};
    unless ($@) {
        for my $db (@kind_of_databases) {
            my $file = "$db_dir/${db}";
            my $str  = qq{
                my \%$db = ();
                tie \%$db, \$db_type, \$file, O_RDWR|O_CREAT, 0644;
                \$self->{ _hash_table }->{ _$db } = \\\%$db;
            };
            eval $str;
            croak($@) if $@;
        }

	my %index      = ();
	my $index_file = $self->{ _index_db };
	eval q{
	    tie %index, $db_type, $index_file, O_RDWR|O_CREAT, 0644;
	    $self->{ _hash_table }->{ _index } = \%index;
	};
	croak($@) if $@;
    }
    else {
        croak("cannot use $db_type");
    }

    1;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub db_close
{
    my ($self) = @_;

    for my $db (@kind_of_databases) {
        my $str = qq{ 
            my \$${db} = \$self->{ _hash_table }->{ _$db };
	    untie \%\$${db};
        };
        eval $str;
        croak($@) if $@;
    }

    my $index = $self->{ _hash_table }->{ _index };
    untie %$index;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::ThreadTrack::DB appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
