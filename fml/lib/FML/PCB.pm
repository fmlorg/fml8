#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: PCB.pm,v 1.14 2003/08/23 04:35:28 fukachan Exp $
#

package FML::PCB;

use strict;
use Carp;
use vars qw(%_fml_PCB); # PCB: Process Control Block (malloc it here)


=head1 NAME

FML::PCB -- hold some information for the current process

=head1 SYNOPSIS

    $pcb = new FML::PCB;
    $pcb->set('lock', 'object', $lockobj);
    $lockobj = $pcb->get('lock', 'object');

=head1 DESCRIPTION

=head2 DATA STRUCTURE

C<$curproc>->C<{ pcb }> area holds some information on the current process.
The hash holds several references to other data structures.

Typically, $curproc is composed like this:

    $curproc = {
		pcb => {
		    key => value,
		},

		incoming_message => $r_msg,
		article          => $r_msg,
		          ... snip ...
		};

=head1 METHODS

=head2 new( $args )

initialize the C<pcb> memory area.
If $args HASH REFERENCE is specified, initialize C<pcb> area by it.

=cut


# Descriptions: constructor. bind object to private hash
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: bind object to internal hash
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;

    unless (defined %_fml_PCB) { %_fml_PCB = ();}
    my $me = \%_fml_PCB;

    # import variables
    if (defined $args) {
	my ($k, $v);
	while (($k, $v) = each %$args) { set($me, $k, $v);}
    }

    return bless $me, $self;
}


=head2 dump_variables()

show all {key => value} for debug.

=head2 get( category, key )

You must specify C<category> and C<key>.

=head2 set( category, key, value)

You must specify C<category>, C<key> and the C<value>.

=cut


# Descriptions: print out hash {key => value}
#    Arguments: NONE
# Side Effects: none
# Return Value: none
sub dump_variables
{
    my ($k, $v);
    while (($k, $v) = each %_fml_PCB) {
	print "${k}: $v\n";
    }
}


# Descriptions: get value for $key in $category
#    Arguments: OBJ($self) STR($category) STR($key)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, $category, $key) = @_;

    if (defined $self->{ $category }->{ $key }) {
	$self->{ $category }->{ $key };
    }
    else {
	undef;
    }
}


# Descriptions: set value for $key in $category
#    Arguments: OBJ($self) STR($category) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub set
{
    my ($self, $category, $key, $value) = @_;
    $self->{ $category }->{ $key } = $value;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::PCB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
