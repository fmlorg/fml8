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

use IO::Adapter::DBI;
@ISA = qw(IO::Adapter::DBI);

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

=head2 C<configure($me, $args)>

=cut

sub configure
{
    my ($self, $me, $args) = @_;
    my $map    = $me->{ _map };
    my $config = $args->{ $map }->{ config };
    my $params = $args->{ $map }->{ params };

    # import basic DBMS parameters
    $me->{ _config }        = $config;
    $me->{ _params }        = $params;
    $me->{ _sql_server }    = $config->{ sql_server }    || 'localhost';
    $me->{ _database }      = $config->{ database }      || 'fml';
    $me->{ _table }         = $config->{ table }         || 'ml';
    $me->{ _user }          = $config->{ user }          || 'fml';
    $me->{ _user_password } = $config->{ user_password } || '';
    $me->{_dsn}             = $self->SUPER::make_dsn( {
	driver     =>  'mysql',
	database   =>  $me->{ _database },
	host       =>  $me->{ _sql_server },
    });
    
    # load model specific library
    my $schema = $config->{ schema } || 'toymodel';
    my $pkg    = "SQL::Schema::". $schema;
    eval qq{ require $pkg; $pkg->import();};
    print $@;
    unless ($@) {
	@ISA = ($pkg, @ISA);
	$me->{ _schema } = $pkg;
    }
    else {
	error_reason($self, $@);
	return undef;
    }
}


=head2 C<getline()>

return the next address.

=head2 C<get_next_value()>

same as C<getline()> now.

=cut


sub getline
{
    my ($self, $args) = @_;
    $self->get_next_value($args);
}


sub get_next_value
{
    my ($self, $args) = @_;

    # for the first time
    unless ($self->{ _res }) {
	if ( $self->{ _schema }->can('get_next_value') ) {
	    $self->{ _schema }->get_next_value($args);
	}
	else {
	    my $query = $self->build_sql_query({ 
		query   => 'get_next_value',
	    });
	    $self->execute({ query => $query });
	}
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


=head2 C<add($addr)>

=head2 C<delete($addr)>

=cut


sub add
{
    my ($self, $addr) = @_;

    if ( $self->{ _schema }->can('add') ) {
	$self->{ _schema }->add($addr);
    }
    else {
	my $query = $self->build_sql_query({ 
	    query   => 'add',
	    address => $addr,
	});
	$self->execute({ query => $query });
    }
}


sub delete
{
    my ($self, $addr) = @_;

    if ( $self->{ _schema }->can('delete') ) {
	$self->{ _schema }->delete($addr);
    }
    else {
	my $query = $self->build_sql_query({ 
	    query   => 'delete',
	    address => $addr,
	});
	$self->execute({ query => $query });
    }
}


1;
