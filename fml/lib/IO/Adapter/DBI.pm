#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
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
other modules in such as C<SQL::Schema::> class.
Each model name is specified at $args->{ schema } in new($args).

=head1 METHODS

=head2 C<make_dsn($args)>

prepare C<dsn>.

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

connected to SQL server specified by C<dsn>.

=head2 C<close($args)>

close connection to SQL server specified by C<dsn>.

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


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::Array appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
