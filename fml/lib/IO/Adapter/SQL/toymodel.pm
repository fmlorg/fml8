#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: toymodel.pm,v 1.1.1.1 2001/08/05 01:55:17 fukachan Exp $
#


package IO::Adapter::SQL::toymodel;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

IO::Adapter::SQL::toymodel - SQL statement dependent on toymodel

=head1 SYNOPSIS

  use IO::Adapter::SQL::toymodel;
  $obj = new IO::Adapter::SQL::toymodel;

=head1 DESCRIPTION

SQL::Schema modules hold SQL statement dependent on each specific
model.

=head1 METHODS

=head2 C<build_sql_query($args)>

    $args = {
	query   => 'add',
	address => 'rudo@nuinui.net',
	_params => {
	    ml_name => 'elena',
	    file    => 'actives',
	},
    }

=cut


sub build_sql_query
{
    my ($self, $args) = @_;
    my $query   = $args->{ query };
    my $address = $args->{ address };

    # inherit parameter from object
    my $ml_name = $self->{ _params }->{ ml_name };
    my $file    = $self->{ _params }->{ file };
    my $table   = $self->{ _table };

    print STDERR "build_sql_query( query=$query )\n" if $ENV{'debug'};

    if ($query eq 'add') {
	"insert into $table values ('$ml_name', '$file', '$address', 0, 0)";
    }
    elsif ($query eq 'delete') {
	"delete from $table where ml='$ml_name' and address='$address'";
    }
    else {
	"select address from $table where ml='$ml_name' and file='$file'";
    }
}


1;
