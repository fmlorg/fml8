#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: DB.pm,v 1.2 2001/11/03 00:18:01 fukachan Exp $
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
			   info
                           date
			   status
			   sender
			   articles
			   message_id
			   index);
                

sub db_open
{
    my ($self) = @_;
    my $db_type = $self->{ config }->{ thread_db_type } || 'AnyDBM_File';
    my $db_dir  = $self->{ _db_dir };

    my $index_file      = $self->{ _index_db };

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
    }
    else {
        croak("cannot use $db_type");
    }

    1;
}


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
