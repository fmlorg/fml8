#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: DBI.pm,v 1.30 2004/01/24 09:03:55 fukachan Exp $
#

package IO::Adapter::DBI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

my $debug = 0;


=head1 NAME

IO::Adapter::DBI - DBI abstraction layer.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is a top level driver to talk with a DBI server in SQL
(Structured Query Language).

The model dependent SQL statement is expected to be given as
parameters.

=head1 METHODS

=head2 make_dsn($args)

prepare C<dsn>.

=cut


# Descriptions: prepare DSN for DBI.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub make_dsn
{
    my ($self, $args) = @_;

    # prepare DBI string.
    my $driver   = $args->{ driver };
    my $database = $args->{ database };
    my $host     = $args->{ host };

    return "DBI:$driver:$database:$host";
}


=head2 execute($args)

execute sql query.

    $args->{
	query => sql_query_statment,
    };

=cut


# Descriptions: execute query for DBI.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub execute
{
    my ($self, $args) = @_;
    my $dbh    = $self->{ _dbh };
    my $query  = $args->{  query };
    my $config = $self->{ _config };

    print STDERR "\nexecute query={$query}\n\n" if $debug;

    undef $self->{ _res };

    if (defined $dbh) {
	my $res = $dbh->prepare($query);

	if (defined $res) {
	    # XXX-TODO: error of execute() is discarded?
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
	print STDERR "no dbh\n" if $debug;
	$self->error_set( "cannot take \$dbh" );
	return undef;
    }
}


=head2 open($args)

connected to SQL server specified by C<dsn>.

=head2 close($args)

close connection to SQL server specified by C<dsn>.

=cut


# Descriptions: open DBI map.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create DB? handle
# Return Value: HANDLE (DB? handle)
sub open
{
    my ($self, $args) = @_;

    print STDERR "DBI::open()\n" if $debug;

    # save for restart
    $self->{ _args } = $args;

    # XXX-TODO: croak() if DSN is not specified ?
    # DSN parameters
    my $dsn      = $self->{ _dsn }         || '';
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


# Descriptions: delete DBI map.
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


=head2 getline()

return the next address.

=head2 get_next_key()

return the next key.

=cut


# Descriptions: return a table row as a string sequentially.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub getline
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'getline');
}


# Descriptions: return (key, values, ... ) as ARRAY_REF.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_key_values_as_array_ref
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'key,value');
}


# Descriptions: return the primary key in the table sequentially.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub get_next_key
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'key');
}


# Descriptions: get data from cache obtained from DBI.
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: none
# Return Value: STR
sub _get_data_from_cache
{
    my ($self, $args, $mode) = @_;

    # For the first time, get the data and cache it for the later use.
    # So, $self->{ _res } is initialized by _fetch_all().
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
	elsif ($mode eq 'key,value') {
	    return \@row;
	}
	elsif ($mode eq 'getline') {
	    return join(" ", @row);
	}
	else {
	    warn("DBI: invalid option");
	    return undef;
	}
    }
    else {
	$self->error_set( $DBI::errstr );
	return undef;
    }
}


# Descriptions: get one entry from DBMS.
#               create an SQL query and exetute it.
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


# Descriptions: add $addr.
#               create an SQL query and exetute it.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: update DB via SQL
# Return Value: STR
sub add
{
    my ($self, $addr) = @_;
    my $config = $self->{ _config };
    my $query  = $config->{ sql_add };

    $self->open();

    # XXX-TODO: &address hard-coded.
    $query =~ s/\&address/$addr/g;
    $self->execute({ query => $query });

    $self->close();
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

    $self->open();

    # XXX-TODO: &address hard-coded.
    $query =~ s/\&address/$addr/g;
    $self->execute({ query => $query });

    $self->close();
}


=head2 md_find()

map specific find().

=cut


# Descriptions: search, md = map dependent.
#               create an SQL query and exetute it.
#    Arguments: OBJ($self) STR($regexp) HASH_REF($args)
# Side Effects: update DB via SQL
# Return Value: STR or ARRAY_REF
sub md_find
{
    my ($self, $regexp, $args) = @_;
    my $config         = $self->{ _config };
    my $query          = $config->{ sql_find };
    my $case_sensitive = $args->{ case_sensitive } ? 1 : 0;
    my $want           = $args->{ want } || 'key,value';
    my $show_all       = $args->{ all } ? 1 : 0;
    my (@buf, $x);

    $self->open();

    # XXX-TODO: &regexp hard-coded.
    $query =~ s/\&regexp/$regexp/g;
    $self->execute({ query => $query });

    if (defined $self->{ _res }) {
	my ($row);

      RES:
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
		    last RES if $x =~ /$regexp/;
		}
		else {
		    last RES if $x =~ /$regexp/i;
		}
	    }
	}
    }
    else {
	print STDERR "no _res\n" if $debug;
	return undef;
    }

    $self->close();

    # XXX-TODO: $x = "STR STR STR" ? should be $x => [] ?
    return( $show_all ? \@buf : $x );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::Array first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
