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

IO::Adapter::MySQL - IO by SQL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new($args)>

   $args->{
       ml_name,
       db
       mysql_toymodel_getline_query => ''
   }

=cut

sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _ml_name } = $args->{ ml_name };

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
    my $database = $args->{ database } || $self->{ _databse } || 'fml';
    my $table    = $args->{ table }    || $self->{ _table }   || 'ml';
    my $host     = $args->{ sql_server } || $self->{ _sql_server } || 'localhost';
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


sub _res_configure
{
    my ($self, $args) = @_;

    unless ($self->{ _res }) {
	my $ml   = $self->{ _ml_name };
	my $file = $self->{ _file } || 'members';
	my $query = "select address from ml ";
	$query   .= "where ml='$ml' and file='$file' ";
	$self->execute({ query => $query });
    }
}


sub getline
{
    my ($self, $args) = @_;
    $self->_res_configure($args) unless $self->{ _res };
    my @row = $self->{ _res }->fetchrow_array;
    join(" ", @row);
}


sub get_next_value
{
    my ($self, $args) = @_;
    $self->_res_configure($args) unless $self->{ _res };
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
