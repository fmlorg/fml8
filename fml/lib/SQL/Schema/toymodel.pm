#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $Id$
#


package SQL::Schema::toymodel;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

SQL::Schema::toymodel - SQL statement dependent on toymodel

=head1 SYNOPSIS

  use SQL::Schema::toymodel;
  $obj = new SQL::Schema::toymodel;

=head1 DESCRIPTION

SQL::Schema modules hold SQL statement dependent on each specific
model.

=head1 METHODS

=cut

sub new
{
}

1;
