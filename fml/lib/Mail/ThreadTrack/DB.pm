#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: DB.pm,v 1.8 2001/11/04 06:52:33 fukachan Exp $
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

my @kind_of_databases = qw(thread_id date status sender articles
                           message_id);


# Descriptions: 
#    Arguments: $self
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
#    Arguments: $self
# Side Effects: 
# Return Value: none
sub db_clear
{
    my ($self) = @_;
    my $db_dir = '';

    $db_dir = $self->{ _db_dir };
    _db_clear($db_dir) if -d $db_dir;

    $db_dir = $self->{ _db_base_dir };
    _db_clear($db_dir) if -d $db_dir;
}


# Descriptions: 
#    Arguments: $directory
# Side Effects: 
# Return Value: none
sub _db_clear
{
    my ($db_dir) = @_;

    eval q{ 
	use DirHandle;
	use File::Spec;
	my $dh = new DirHandle $db_dir;

	if (defined $dh) {
	    my $f = '';
	    while (defined($f = $dh->read)) {
		next if $f =~ /^\./;
		my $file = File::Spec->catfile($db_dir, $f);
		if (-f $file) {
		    print STDERR "unlink $file\n";
		    unlink $file;
		}
	    }
	    $dh->close;
	}
    };
    croak($@) if $@;
}


# Descriptions: 
#    Arguments: $self
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


=head2 db_mkdb($min, $max)

=cut

my $debug = defined $ENV{'debug'} ? 1 : 0;


sub db_mkdb
{
    my ($self, $min_id, $max_id) = @_;
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };

    use Mail::Message;
    use File::Spec;

    for my $id ( $min_id .. $max_id ) {
	print STDERR "process $id\n" if $debug;

	# XXX overwrite (tricky)
	$self->{ _config }->{ article_id } = $id;

	# analyze
	my $file = File::Spec->catfile($spool_dir, $id);
	my $fh   = new FileHandle $file;
	my $msg  = Mail::Message->parse({ fd => $fh });
	$self->analyze($msg);
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
