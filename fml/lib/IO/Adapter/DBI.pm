#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: DBI.pm,v 1.14 2002/02/01 12:03:58 fukachan Exp $
#

package IO::Adapter::DBI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

my $debug = 0;

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
    my $dbh    = $self->{ _dbh };
    my $query  = $args->{  query };
    my $config = $self->{ _config };

    print STDERR "execute query={$query}\n" if $debug;

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

    print STDERR "DBI::open()\n" if $debug;

    # save for restart
    $self->{ _args } = $args;

    # DSN parameters
    my $dsn      = $self->{ _dsn };
    my $user     = $self->{ _sql_user }    || 'fml';
    my $password = $self->{ _sql_password} || '';

    print STDERR "open $dsn\n" if $debug;

    # try to connect
    use DBI;
    my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1 } );
    unless (defined $dbh) {
	$self->error_set( $DBI::errstr );
	return undef;
    }
    else {
	print STDERR "connected to $dsn\n" if $debug;
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
    croak('getline() not implemented');
}


# Descriptions: return key from DBI map
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: none
# Return Value: STR
sub get_next_key
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'key');
}


# Descriptions: return value(s) from DBI map
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: none
# Return Value: STR
sub get_next_value
{
    my ($self, $args) = @_;
    croak('get_net_value() not implemented');
}


# Descriptions: get from DBI map
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: none
# Return Value: STR
sub _get_data_from_cache
{
    my ($self, $args, $mode) = @_;

    # for the first time, get the data and cache it for the later use.
    unless ($self->{ _res }) {
	# reset row information
	undef $self->{ _row_pos };
	undef $self->{ _row_max };

	$self->_fetch_all($args);
    }

    if ($self->{ _res }) {
	# store the row size
	unless (defined $self->{ _row_max }) {
	    $self->{ _row_max } = $self->{ _res }->rows;
	}

	my @row = $self->{ _res }->fetchrow_array;
	$self->{ _row_pos }++;
	if ($mode eq 'key') {
	    return $row[0];
	}
	elsif ($mode eq 'value') {
	    shift @row;
	    return \@row;
	}
	else {
	    warn("DBI: invalid option");
	}
    }
    else {
	$self->error_set( $DBI::errstr );
	undef;
    }
}


# Descriptions: get one entry from DBMS
#               create an SQL query and exetute it
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: update DB via SQL
# Return Value: STR
sub _fetch_all
{
    my ($self, $args) = @_;
    my $config = $self->{ _config };
    my $query  = $config->{ sql_get_next_key };

    $self->execute({ query => $query });
}


=head2 add($addr)

=head2 delete($addr)

=cut


# Descriptions: add $addr
#               create an SQL query and exetute it
#    Arguments: OBJ($self) STR($addr)
# Side Effects: update DB via SQL
# Return Value: STR
sub add
{
    my ($self, $addr) = @_;
    my $config = $self->{ _config };
    my $query  = $config->{ sql_add };

    $query =~ s/\&address/$addr/g;

    $self->execute({ query => $query });
}


# Descriptions: delete $addr
#               create an SQL query and exetute it
#    Arguments: OBJ($self) STR($addr)
# Side Effects: update DB via SQL
# Return Value: STR
sub delete
{
    my ($self, $addr) = @_;
    my $config = $self->{ _config };
    my $query  = $config->{ sql_delete };

    $query =~ s/\&address/$addr/g;

    $self->execute({ query => $query });
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


# Descriptions: search, md = map dependent
#               create an SQL query and exetute it
#    Arguments: OBJ($self) STR($regexp) HASH_REF($args)
# Side Effects: update DB via SQL
# Return Value: STR or ARRAY_REF
sub md_find
{
    my ($self, $regexp, $args) = @_;
    my $case_sensitive = $args->{ case_sensitive } ? 1 : 0;
    my $show_all       = $args->{ all } ? 1 : 0;
    my (@buf, $x);

    my $query = $self->_build_sql_query({
	query  => 'search',
	regexp => $regexp,
    });
    $self->execute({ query => $query });

    if (defined $self->{ _res }) {
	my ($row);
	while (defined ($row = $self->{ _res }->fetchrow_arrayref)) {
	    $x = join(" ", @$row);

	    if ($show_all) {
		if ($case_sensitive) {
		    push(@buf, $x) if $x =~ /$regexp/;
		}
		else {
		    push(@buf, $x) if $x =~ /$regexp/i;
		}
	    }
	    else {
		if ($case_sensitive) {
		    last if $x =~ /$regexp/;
		}
		else {
		    last if $x =~ /$regexp/i;
		}
	    }
	}
    }
    else {
	return undef;
    }

   $show_all ? \@buf : $x;
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
