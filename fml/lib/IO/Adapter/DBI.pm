#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: DBI.pm,v 1.11 2002/01/27 09:21:52 fukachan Exp $
#

package IO::Adapter::DBI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

=head1 NAME

IO::Adapter::DBI - DBI

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is a top level driver to talk with a DBI server in SQL
(Structured Query Language).

The model dependent SQL statement is expected to be holded in
other modules in such as C<IO::Adapter::SQL::> class.
Each model name is specified at $args->{ schema } in new($args).

=head1 METHODS

=head2 C<make_dsn($args)>

prepare C<dsn>.

=cut


# Descriptions: prepare DSN for DBI
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub make_dsn
{
    my ($self, $args) = @_;
    my $driver   = $args->{ driver };
    my $database = $args->{ database };
    my $host     = $args->{ host };

    return "DBI:$driver:$database:$host";
}


=head2 C<execute($args)>

execute sql query.

    $args->{
	query => sql_query_statment,
    };

=cut


# Descriptions: execute query for DBI
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub execute
{
    my ($self, $args) = @_;
    my $dbh   = $self->{ _dbh };
    my $query = $args->{  query };

    print STDERR "execute query={$query}\n" if $ENV{'debug'};

    undef $self->{ _res };

    if (defined $dbh) {
	my $res = $dbh->prepare($query);

	if (defined $res) {
	    $res->execute;
	    $self->{ _res } = $res;
	    return $res;
	}
	else {
	    $self->error_set( $DBI::errstr );
	    return undef;
	}
    }
    else {
	$self->error_set( $DBI::errstr );
	return undef;
    }
}


=head2 C<open($args)>

connected to SQL server specified by C<dsn>.

=head2 C<close($args)>

close connection to SQL server specified by C<dsn>.

=cut


# Descriptions: open DBI map
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create DB? handle
# Return Value: HANDLE (DB? handle)
sub open
{
    my ($self, $args) = @_;

    # save for restart
    $self->{ _args } = $args;

    # DSN parameters
    my $dsn      = $self->{ _dsn };
    my $user     = $self->{ _user }        || 'fml';
    my $password = $self->{_user_password} || '';

    use DBI;
    if ($dsn =~ /DBD:mysql/) {
	eval q{ use DBD::mysql; };
	if ($@) {
	    $self->error_set( $@ );
	    return undef;
	}
    }

    # try to connect
    my $dbh = DBI->connect($dsn, $user, $password);
    unless (defined $dbh) {
	$self->error_set( $DBI::errstr );
	return undef;
    }

    $self->{ _dbh } = $dbh;
}


# Descriptions: delete DBI map
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: delete DB? handle
# Return Value: none
sub close
{
    my ($self, $args) = @_;
    my $res = $self->{ _res };
    my $dbh = $self->{ _dbh };

    $res->finish     if defined $res;
    $dbh->disconnect if defined $dbh;
    delete $self->{ _res };
    delete $self->{ _dbh };
}


=head2 C<getline()>

return the next address.

=head2 C<get_next_value()>

same as C<getline()> now.

=cut


# Descriptions: get from DBI map
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub getline
{
    my ($self, $args) = @_;
    $self->get_next_value($args);
}


# Descriptions: get from DBI map
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub get_next_value
{
    my ($self, $args) = @_;

    # for the first time
    unless ($self->{ _res }) {
	# reset row information
	undef $self->{ _row_pos };
	undef $self->{ _row_max };

	if ( $self->can('fetch_all') ) {
	    $self->fetch_all($args);
	}
	else {
	    croak "cannot get next value\n";
	}
    }

    if ($self->{ _res }) {
	# store the row size
	unless (defined $self->{ _row_max }) {
	    $self->{ _row_max } = $self->{ _res }->rows;
	}

	my @row = $self->{ _res }->fetchrow_array;
	$self->{ _row_pos }++;
	join(" ", @row);
    }
    else {
	$self->error_set( $DBI::errstr );
	undef;
    }
}


=head2 C<replace($regexp, $value)>

=cut


# Descriptions: replace value
#    Arguments: OBJ($self) STR($regexp) STR($value)
# Side Effects: update map
# Return Value: none
sub replace
{
    my ($self, $regexp, $value) = @_;
    my (@addr);

    # firstly, get list matching /$regexp/i;
    my $a = $self->find($regexp, { want => 'key', all => 1});

    # secondarly double check: get list matchi /$regexp/;
    for my $addr (@$a) {
	push(@addr, $addr) if ($addr =~ /$regexp/);
    }

    # thirdly, replace it
    for my $addr (@addr) {
	$self->delete( $addr );
	$self->add( $value );
    }

}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::Array appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
