#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#


package Mail::Bounce::DSN;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::DSN - DNS error message format parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


sub analyze
{
    my ($self, $msg) = @_;
    my $m;

    if ($m = $msg->find( { data_type => 'message/delivery-status' } )) {
	# data in the part
	my $data = $m->data;
	print "// ", $m->num_paragraph, " paragraph(s)\n";
	print $data;
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

Mail::Bounce::DSN appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
