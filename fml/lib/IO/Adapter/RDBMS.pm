#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: RDBMS.pm,v 1.10 2001/06/09 08:58:10 fukachan Exp $
#

package IO::Adapter::RDBMS;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

IO::Adapter::RDBMS - talk with SQL servers

=head1 SYNOPSIS

   ... not yet ...

=head1 DESCRIPTION

   ... not yet ...

=head1 METHODS

=head2 C<configure($args)>

Configure object for C<dsn>.

    new({
	driver => 'IO::Adapter::SQL::toymodel',
    });

It forwards the request to the specified driver, 
which knows the sql statement how to add, delete and select.

=cut


# Descriptions: configure the detail between SQL servers
#               all requests are forwarded to the specified sub-class.
#    Arguments: $self $args
# Side Effects: none
# Return Value: subclass object
sub configure
{
    my ($self, $args) = @_;
    my $type   = $args->{ _type   };
    my $schema = $args->{ _schema };

    $type = 'MySQL'      if $type eq 'mysql';
    $type = 'PostgreSQL' if $type eq 'postgresql';
    my $driver = "IO::Adapter::SQL::${type}::${schema}";
    print STDERR "driver = $driver\n" if defined $ENV{'debug'};

    # forward the request to the specified subclass or DBI base class
    eval qq{ require $driver; $driver->import();};
    unless ($@) {
	@ISA = ($driver);
    }
    else {
	return undef;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::RDBMS appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
