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

    $me->{ _ml_name }          = $args->{ ml_name }    || '';
    $me->{ _databse }          = $args->{ database }   || 'fml';
    $me->{ _table }            = $args->{ table }      || 'ml';
    $me->{ _sql_server }       = $args->{ sql_server } || 'localhost';
    $me->{ _sql_user }         = $args->{ sql_user }   || 'fml';
    $me->{ _sql_user_password} = $args->{ sql_user_password } || '';

    # load model dependent module specified by $args->{ schema };
    if (defined $args->{ schema }) {
	my $schema = $args->{ schema };
	my $pkg    = "SQL::Schema::${schema}";
	my $obj    = '';
	eval qq{ require $pkg; $pkg->import(); \$obj = $pkg->new(); };
	unless ($@) {
	    $me->{ _schema } = $obj;
	} 
	else {
	    print $@;
	    error_reason($me, $@);
	    return undef;
	}
    }

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
    my $database = $args->{database}   || $self->{_databse} || 'fml';
    my $table    = $args->{table}      || $self->{_table}   || 'ml';
    my $host     = $args->{sql_server} || $self->{_sql_server} || 'localhost';
    my $user     = $args->{sql_user}   || $self->{ _sql_user } || 'fml';
    my $password = 
	$args->{sql_user_password} || $self->{_sql_user_password} || '';

    my $dsn = "DBI:$driver:$database:$host";
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
}


=head2 C<getline()>

return the next address.

=head2 C<get_next_value()>

same as C<getline()> now.

=cut


sub _res_configure
{
    my ($self, $args) = @_;

    unless ($self->{ _res }) {
	my $ml    = $self->{ _ml_name };
	my $file  = $self->{ _file } || 'members';
	my $query = "select address from ml ";
	$query   .= "where ml='$ml' and file='$file' ";
	$self->execute({ query => $query });
    }
    else {
	$self->error_reason( $DBI::errstr );
	return undef;
    }
}


sub getline
{
    my ($self, $args) = @_;

    $self->_res_configure($args) unless $self->{ _res };
    if ($self->{ _res }) {
	my @row = $self->{ _res }->fetchrow_array;
	join(" ", @row);
    }
    else {
	$self->error_reason( $DBI::errstr );
	undef;
    }
}


sub get_next_value
{
    my ($self, $args) = @_;
    $self->getline($args);
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


1;
