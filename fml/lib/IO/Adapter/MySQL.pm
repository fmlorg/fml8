#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: MySQL.pm,v 1.22 2002/09/11 23:18:20 fukachan Exp $
#


package IO::Adapter::MySQL;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

use IO::Adapter::DBI;
push(@ISA, 'IO::Adapter::DBI');


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
This module inherits C<IO::Adapter::DBI> class.

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


# Descriptions: initialize MySQL specific configuration
#    Arguments: OBJ($self) HASH_REF($me) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub configure
{
    my ($self, $me, $args) = @_;
    my $map    = $me->{ _map };       # e.g. "mysql:toymodel"
    my $config = $args->{ "[$map]" };

    # import variables
    for my $key (qw(sql_server
		    sql_database
		    sql_table
		    sql_user
		    sql_password)) {
	$me->{ "_$key" } = $config->{ $key };
    }

    use IO::Adapter::DBI;
    my $dsn = IO::Adapter::DBI->make_dsn( {
	driver   => 'mysql',
	database => $config->{ sql_database },
	host     => $config->{ sql_server },
    });

    # save the current DSN
    $me->{ _dsn } = $dsn;

    # save map specific configuration
    $me->{ _config } = $config;
}


=head2 C<setpos($pos)>

MySQL does not support rollack, so we close and open this transcation.
After re-opening, we moved to the specified $pos.

=cut


# Descriptions: set position in database handle
#    Arguments: OBJ($self) NUM($pos)
# Side Effects: none
# Return Value: none
sub setpos
{
    my ($self, $pos) = @_;
    my $i = 0;

    # requested position $pos is later here
    if ($pos > $self->{ _row_pos }) {
	$i = $pos - $self->{ _row_pos } - 1;
    }
    else {
	# hmm, rollback() is not supported on mysql.
	# we need to restart this session.
	my $args = $self->{ _args };
	$self->close($args);
	$self->open($args);
	$i = $pos - 1;
    }

    # discard
    while ($i-- > 0) { $self->get_next_key();}
}


=head2 C<getpos()>

=cut


# Descriptions: get position in database handle
#    Arguments: OBJ($self) NUM($pos)
# Side Effects: none
# Return Value: NUM
sub getpos
{
    my ($self) = @_;
    return $self->{ _row_pos };
}


=head2 C<eof()>

=cut


# Descriptions: EOF or not?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub eof
{
    my ($self) = @_;
    $self->{ _row_pos } < $self->{ _row_max } ? 0 : 1;
}


=head1 SEE ALSO

L<DBI>,
L<DBD::MySQL>,
L<IO::Adapter::DBI>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::File first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
