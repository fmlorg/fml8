#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $Id$
#


package IO::Adapter::MySQL;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

IO::Adapter::MySQL - interface to talk with a MySQL server

=head1 SYNOPSIS



=head1 DESCRIPTION

This module is a top level driver to talk with a MySQL server in SQL
(Structured Query Language).

The model dependent SQL statement is expected to be holded in
C<SQL::Schema::> modules. 
Each model name is specified at $args->{ schema } in new($args).

=head1 METHODS

=head2 C<new($args)>

=cut

sub configure
{
    my ($self, $me, $args) = @_;
    my $map    = $me->{ _map };
    my $config = $args->{ $map }->{ config };
    my $query  = $args->{ $map }->{ query };

    # import basic DBMS parameters
    $me->{ _sql_server }    = $config->{ sql_server }    || 'localhost';
    $me->{ _database }      = $config->{ database }      || 'fml';
    $me->{ _table }         = $config->{ table }         || 'ml';
    $me->{ _user }          = $config->{ user }          || 'fml';
    $me->{ _user_password } = $config->{ user_password } || '';
    $me->{_dsn}             = _get_dsn($me, {
	driver     =>  'mysql',
	database   =>  $me->{ _database },
	host       =>  $me->{ _sql_server },
    });
    
    # we want to pass basic parameters from caller.
    $me->{ _schema }        = $config->{ schema } || 'toymodel';
    $me->{ _query }         = $query || '';
}


sub _get_dsn
{
    my ($self, $args) = @_;
    my $driver   = $args->{ driver };
    my $database = $args->{ database };
    my $host     = $args->{ host };

    return "DBI:$driver:$database:$host";
}


=head2 C<open($args)>

=head2 C<close($args)>

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub open
{
    my ($self, $args) = @_;

    use DBI;
    use DBD::mysql;

    my $dsn      = $self->{ _dsn };
    my $user     = $self->{ _user }        || 'fml';
    my $password = $self->{_user_password} || '';

    # try to connect
    my $dbh = DBI->connect($dsn, $user, $password);
    unless (defined $dbh) { 
	$self->error_reason( $DBI::errstr );
	return undef;
    }

    $self->{ _dbh } = $dbh;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
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


=head2 C<load_schema($args)>

=cut

sub load_schema
{
    my ($self, $args) = @_;

    # load model dependent module specified by $args->{ schema };
    if (defined $self->{ schema }) {
	my $schema = $self->{ schema };
	my $pkg    = "SQL::Schema::${schema}";
	my $obj    = '';
	eval qq{ require $pkg; $pkg->import(); \$obj = $pkg->new(); };
	unless ($@) {
	    $self->{ _schema } = $obj;
	} 
	else {
	    print $@;
	    error_reason($self, $@);
	    return undef;
	}
    }
}


=head2 C<getline()>

return the next address.

=head2 C<get_next_value()>

same as C<getline()> now.

=cut


sub _schema_configure
{
    my ($self, $query_type) = @_;
    my $query  = $self->{ _query }->{ $query_type };

    if (ref($query) eq 'CODE') {
	$query = &$query();
    }
    else {
	$query;
    }
}


sub getline
{
    my ($self, $args) = @_;
    $self->get_next_value($args);
}


sub get_next_value
{
    my ($self, $args) = @_;

    unless ($self->{ _res }) {
	my $query = $self->_schema_configure('get_next_value');
	$self->execute({ query => $query });
    }

    if ($self->{ _res }) {
	my @row = $self->{ _res }->fetchrow_array;
	join(" ", @row);
    }
    else {
	$self->error_reason( $DBI::errstr );
	undef;
    }
}


=head2 C<execute($args)>

execute sql query.

    $args->{ 
	query => sql_query_statment,
    };

=cut


sub execute
{
    my ($self, $args) = @_;
    my $dbh   = $self->{ _dbh };
    my $query = $args->{  query };

    if (defined $dbh) {
	my $res = $dbh->prepare($query);

	if (defined $res) {
	    $res->execute;
	    $self->{ _res } = $res;
	    return $res;
	}
	else {
	    $self->error_reason( $DBI::errstr );
	    return undef;
	}
    }
    else {
	$self->error_reason( $DBI::errstr );
	return undef;
    }
}



=head2 C<error_reason($mesg)>

=head2 C<error()>

=cut

sub error_reason
{
    my ($self, $mesg) = @_;
    $self->{ _error } = $mesg;
}


sub error
{
    my ($self) = @_;
    return $self->{ _error };
}


=head2 C<add()>

=cut

sub add
{
    my ($self, $args) = @_;
    my $query = $self->_schema_configure('add');
    $query = sprintf($query, $args);
    $self->execute({ query => $query });
}


sub delete
{
    my ($self, $args) = @_;
    my $query = $self->_schema_configure('delete');
    $query = sprintf($query, $args);
    $self->execute({ query => $query });
}


1;
