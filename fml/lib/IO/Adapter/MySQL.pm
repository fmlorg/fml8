#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: MySQL.pm,v 1.13 2001/06/17 08:57:10 fukachan Exp $
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

   use IO::Adapter;
   
   my $map        = 'mysql:toymodel';
   my $map_params = {
       $map => {
   	sql_server    => 'localhost',
   	user          => 'fukachan',
   	user_password => 'uja',
   	database      => 'fml',
   	table         => 'ml',
   	params        => {
   	    ml_name   => 'elena',
   	    file      => 'members',
   	},
       },
   };
   
   my $obj = new IO::Adapter ($map, $map_params);
   $obj->open();
   $obj->add( 'rudo@nuinui.net' );
   $obj->close();

=head1 DESCRIPTION

This module is a top level driver to talk with a MySQL server in SQL
(Structured Query Language).

The model dependent SQL statement is expected to be holded in
C<IO::Adapter::SQL::> modules. 

You can specify your own module name at $args->{ driver } in
new($args). 
It is expected to provdie C<add()>, C<delete()> and
C<get_next_value()> method. 


=head1 METHODS

=head2 C<configure($me, $args)>

IO::Adapter::MySQL specific configuration loader.
It also calles IO::Adapter::SQL::$model module for model specific
customizatoins and functions.

=cut

sub configure
{
    my ($self, $me, $args) = @_;
    my $map    = $me->{ _map };       # e.g. "mysql:toymodel"
    my $config = $args->{ $map };     # { add => 'insert into ..', }
    my $params = $config->{ params }; #

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
    my $pkg = $config->{ driver } || 'IO::Adapter::SQL::toymodel';
    eval qq{ require $pkg; $pkg->import();};

    # $self->{ _driver } is the $config->{ driver } object.
    unless ($@) {
	print STDERR "load $pkg\n" if $ENV{ 'debug' };
	@ISA = ($pkg, @ISA);
	$me->{ _driver } = $pkg;
    }
    else {
	error_set($self, $@);
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
	# $self->{ _driver } is the $config->{ driver } object.
	if ( $self->{ _driver }->can('get_next_value') ) {
	    $self->{ _driver }->get_next_value($args);
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
	$self->error_set( $DBI::errstr );
	undef;
    }
}


=head2 C<add($addr)>

add C<$addr> to the sql server specified at new().
IO::Adapter::SQL::$model provides model specific SQL query statement.
If IO::Adapter::SQL::add() exists, IO::Adapter::SQL::add() is called.

=head2 C<delete($addr)>

delete C<$addr> from the sql server specified at new().
IO::Adapter::SQL::$model provides model specific SQL query statement.
If IO::Adapter::SQL::delete() exists, IO::Adapter::SQL::delete() is called.

=cut


sub add
{
    my ($self, $addr) = @_;

    # $self->{ _driver } is the $config->{ driver } object.
    if ( $self->{ _driver }->can('add') ) {
	$self->{ _driver }->add($addr);
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

    # $self->{ _driver } is the $config->{ driver } object.
    if ( $self->{ _driver }->can('delete') ) {
	$self->{ _driver }->delete($addr);
    }
    else {
	my $query = $self->build_sql_query({ 
	    query   => 'delete',
	    address => $addr,
	});
	$self->execute({ query => $query });
    }
}


=head1 SEE ALSO

L<DBI>,
L<DBD::MySQL>,
L<IO::Adapter::DBI>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::File appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
