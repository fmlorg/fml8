#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package IO::Adapter::PCRE;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $Counter %LockedFileHandle %FileIsLocked);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

my $debug = 0;

use IO::Adapter::File;
push(@ISA, 'IO::Adapter::File'); 


=head1 NAME

IO::Adapter::PCRE - IO functions for a pcre file.

=head1 SYNOPSIS

    $map = 'pcre:/var/spool/ml/elena/sender_check';

To read list

    use IO::Adapter;
    $obj = new IO::Adapter $map;
    $obj->open || croak("cannot open $map");
    $obj->find($address);

=head1 DESCRIPTION

This module provides real IO functions for a file used in
C<IO::Adapter>.
The map is the fully path-ed file name or a file name with 'pcre:'
prefix.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: search, md = map dependent.
#    Arguments: OBJ($self) STR($regexp) HASH_REF($args)
# Side Effects: update cache on memory.
# Return Value: STR or ARRAY_REF
sub md_find
{
    my ($self, $regexp, $args) = @_;
    my $case_sensitive = $args->{ case_sensitive } ? 1 : 0;
    my $want           = $args->{ want } || 'key,value';
    my $show_all       = $args->{ all } ? 1 : 0;
    my (@buf, $x);

    if ($debug) {
	eval q{
	    use Data::Dumper;
	    print "pcre_md_find($regexp,\n";
	    print "\t";
	    print Dumper($args);
	    print ")\n";
	};
    }

    my $pcre;
  LINE:
    while ($pcre = $self->get_next_key()) {
	print "($regexp =~ /$pcre/)\n";

	if ($show_all) {
            if ($case_sensitive) {
		if ($regexp =~ /$pcre/) {
		    push(@buf, $regexp);
		}
	    }
	    else {
		if ($regexp =~ /$pcre/i) {
		    push(@buf, $regexp);
		}
	    }
	}
	else {
            if ($case_sensitive) {
		if ($regexp =~ /$pcre/) {
		    $x = $regexp;
		    last LINE;
		}
	    }
	    else {
		if ($regexp =~ /$pcre/i) {
		    $x = $regexp;
		    last LINE;
		}
	    }
	}
    }

    return( $show_all ? \@buf : $x );
}


=head1 SEE ALSO

L<IO::Adapter>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::PCRE first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
