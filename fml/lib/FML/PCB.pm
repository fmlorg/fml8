#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: PCB.pm,v 1.21 2005/05/27 03:03:32 fukachan Exp $
#

package FML::PCB;

use strict;
use Carp;

# PCB: Process Control Block (malloc it here)
use vars qw(%_fml_PCB $current_context);


# XXX context switching must be needed for listserv style emulator,
# XXX not fml4 emulation nor fml8 itself.
# XXX we set $current_context as $ml_name@$ml_domain for lisetserv.
$current_context = '__default__';


=head1 NAME

FML::PCB -- hold some information for the current process.

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
		    __default__  => {
			key => value,
		    },
		    $ml_addresss => {
			key => value,
		    },
		},

		incoming_message => $r_msg,
		article          => $r_msg,
		          ... snip ...
		};

=head1 METHODS

=head2 new( $pcb_args )

initialize the C<pcb> memory area.
If $pcb_args HASH REFERENCE is specified, initialize C<pcb> area by it.

=cut


# Descriptions: constructor.
#               bind object to private hash.
#    Arguments: OBJ($self) HASH_REF($pcb_args)
# Side Effects: bind object to internal hash
# Return Value: OBJ
sub new
{
    my ($self, $pcb_args) = @_;

    # XXX-TODO: PCB is needed to prepare for each ml_name@ml_domain ?
    unless (defined %_fml_PCB) { %_fml_PCB = ();}
    my $me = {};

    # import variables
    if (defined $pcb_args) {
	my ($k, $v);
	while (($k, $v) = each %$pcb_args) { set($me, $k, $v);}
    }

    bless $me, $self;

    $_fml_PCB{ $current_context } = $me;

    return $me;
}


=head2 dump_variables()

show all {key => value} for debug.

=head2 get( category, key )

You must specify C<category> and C<key>.

=head2 set( category, key, value)

You must specify C<category>, C<key> and the C<value>.

=cut


# Descriptions: print out hash {key => value}.
#    Arguments: NONE
# Side Effects: none
# Return Value: none
sub dump_variables
{
    my $pcb = $_fml_PCB{ $current_context } || {};

    my ($k, $v, $xk, $xv);
    while (($k, $v) = each %$pcb) {
	while (($xk, $xv) = each %$v) {
	    printf "%-21s => {\n", $current_context;
	    printf "   %-18s => {\n", $k;
	    printf "      %-15s => %-15s\n", $xk, $xv;
	    printf "   }\n"; 
	    printf "}\n\n"; 
	}
    }
}


# Descriptions: get value for $key in $category.
#    Arguments: OBJ($self) STR($category) STR($key)
# Side Effects: none
# Return Value: STR
sub get
{
    my ($self, $category, $key) = @_;

    if (defined $_fml_PCB{ $current_context }->{ $category }->{ $key }) {
	return $_fml_PCB{ $current_context }->{ $category }->{ $key };
    }
    else {
	return undef;
    }
}


# Descriptions: set value for $key in $category
#    Arguments: OBJ($self) STR($category) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub set
{
    my ($self, $category, $key, $value) = @_;

    $_fml_PCB{ $current_context }->{ $category }->{ $key } = $value;
}


=head1 CONTEXT SWITCH

=head2 set_current_context($context)

switch the current context.

=head2 get_current_context()

get the current context name.

=cut


# Descriptions: switch the current context.
#    Arguments: OBJ($self) STR($context)
# Side Effects: overload $current_context. 
# Return Value: none
sub set_current_context
{
    my ($self, $context) = @_;

    $current_context = $context;
}


# Descriptions: get the current context.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub get_current_context
{
    my ($self) = @_;

    return $current_context;
}


#
# debug
#
if ($0 eq __FILE__) {
    my $category = "category";
    my $ml       = 'elena@home.fml.org';
    my $key      = "key";
    my $value    = "value";

    my $pcb = new FML::PCB;
    $pcb->set($category, "ml_name", "test");
    $pcb->dump_variables();

    $pcb->set_current_context($ml);
    $pcb->set($category, "ml_name", "elena");
    $pcb->dump_variables();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::PCB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
