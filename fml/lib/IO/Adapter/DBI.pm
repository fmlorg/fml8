#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $Id$
#

package IO::Adapter::DBI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorMessages::Status qw(error_set error error_clear);

=head1 NAME

IO::Adapter::DBI - DBI

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is a top level driver to talk with a DBI server in SQL
(Structured Query Language).

The model dependent SQL statement is expected to be holded in
C<SQL::Schema::> modules. 
Each model name is specified at $args->{ schema } in new($args).

=head1 METHODS

=cut


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
	$self->error_set( $DBI::errstr );
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


1;
