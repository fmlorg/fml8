#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $Id$
#


package IO::Adapter::MySQL::toymodel;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

IO::Adapter::MySQL::toymodel - toymodel with SQL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
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

    my $driver   = 'mysql';
    my $database = $args->{ database_name }    || 'fml';
    my $host     = $args->{ sql_server }       || 'localhost';
    my $dsn      = "DBI:$driver:$database:$host";
    my $user     = $args->{ sql_user }         || 'fml' || '';
    my $password = $args->{ sql_user_password} || '';

    my $dbh = DBI->connect($dsn, $user, $password);
    unless (defined $dbh) { 
	$args->{'error'} = $DBI::errstr;
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
}


=head2 C<getline()>

=cut

sub getline
{
    my ($self, $args) = @_;

    unless ($self->{ _res }) {
	$self->execute( { query => 'select address from ml' } );
    }

    my @row = $self->{ _res }->fetchrow_array;
    $row[0];
}


=head2 C<execute($args)

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
	$res->execute;

	unless (defined $res) {
	    $self->error_reason( $DBI::errstr );
	    return undef;
	}
	else {
	    $self->{ _res } = $res;
	    return $res;
	}
    }
    else {
	return undef;
    }
}


1;
