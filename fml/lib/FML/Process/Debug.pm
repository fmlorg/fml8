#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.7 2003/01/01 02:06:22 fukachan Exp $
#

package FML::Process::Debug;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Debug - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

=head2 C<dump_curproc($curproc)>

dump curproc structure.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: dump the curproc structure.
#    Arguments: OBJ($self) OBJ($curproc) 
# Side Effects: non
# Return Value: none
sub dump_curproc
{
    my ($self, $curproc) = @_;
 
    print "CURPROC_BEGIN\n";
    my (@c) = sort keys %$curproc;
    for my $k (@c) {
	my $x = $curproc->{ $k };
	if (ref($x) eq 'HASH') {
	    printf "%-20s => HASH {\n", $k;
	    for my $v (sort keys %$x) {
		my $y = $x->{ $v };
		if (ref($y)) {
		    printf "%-20s   %-20s => %s\n", "", $v, ref($y);
		}
		else {
		    printf "%-20s   %s\n", "", $v;
		}
	    }
	    printf "%-20s }\n", "", $k;
	}
	elsif (ref($x)) {
	    printf "%-20s => %s\n", $k, ref($x);
	}
	else {
	    printf "%-20s => %s\n", $k, "SCALAR";
	}

	print "\n";
    }
    print "CURPROC_END\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi 

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Debug appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
