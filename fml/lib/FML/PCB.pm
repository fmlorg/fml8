#-*- perl -*-
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $Id$
# $FML$ # 注意: cvs のタグを $FML$ にする
#

package FML::PCB;

use strict;
use Carp;
use vars qw(%_fml_PCB); # PCB: Process Control Block (malloc it here)


=head1 NAME

FML::PCB -- manipulate Process Control Block

=head1 SYNOPSIS

    $pcb = new FML::PCB;
    $pcb->set('lock', 'object', $lockobj);
    $lockobj = $pcb->get('lock', 'object');

=head1 DESCRIPTION

=head2 DATA STRUCTURE

C<$CurProc>->C<{ pcb }> area holds the CURrent PROCess information.
The hash holds several references to other data structures,
which are mainly hashes.

    $CurProc = {
		pcb => {
		    key => value,
		},

		incoming_message => $r_msg,
		article          => $r_msg,

		... snip ...

		};

=head1 METHODS

=head2 C<new( $args )>

initialize the C<pcb> memory area. 
If $args HASH REFERENCE is specified, 
copy the hash content in it to C<pcb> area.

=cut


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


=head2 C<dump_variables()>

show all {key => value} for debug.

=head2 C<get( category, key )>

You must specify C<category> and C<key>.

=head2 C<set( category, key, value)>

You must specify C<category>, C<key> and the C<value>.

=cut


sub dump_variables
{
    my ($k, $v);
    while (($k, $v) = each %_fml_PCB) {
	print "${k}: $v\n";
    }
}


sub get
{
    my ($self, $category, $key) = @_;
    $self->{ $category }->{ $key };
}


sub set
{
    my ($self, $category, $key, $value) = @_;
    $self->{ $category }->{ $key } = $value;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::PCB appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
