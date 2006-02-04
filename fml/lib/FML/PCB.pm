#-*- perl -*-
#
#  Copyright (C) 2000,2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: PCB.pm,v 1.23 2006/01/09 14:00:53 fukachan Exp $
#

package FML::PCB;

use strict;
use Carp;

# PCB: Process Control Block (malloc it here)
use vars qw($_fml_pool $_fml_PCB $current_context);


# XXX context switching must be needed for listserv style emulator,
# XXX not fml4 emulation nor fml8 itself.
# XXX we set $current_context as $ml_name@$ml_domain for lisetserv.
$current_context = '__default__';

# init HASH_REF.
{
    unless (defined $_fml_pool) { $_fml_pool = {};}
    $_fml_pool->{ $current_context }->{ _fml_PCB } = {};
    $_fml_PCB = $_fml_pool->{ $current_context }->{ _fml_PCB };
}


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
    my $me = $_fml_PCB;

    # import variables
    if (defined $pcb_args) {
	my ($k, $v);
	while (($k, $v) = each %$pcb_args) { set($me, $k, $v);}
    }

    bless $me, $self;

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
    my $pcb = $_fml_PCB || {};

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

    if (defined $_fml_PCB->{ $category }->{ $key }) {
	return $_fml_PCB->{ $category }->{ $key };
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

    $_fml_PCB->{ $category }->{ $key } = $value;
}


=head1 CONTEXT SWITCHING

=head2 set_context($context)

set up context identifier.

=head2 get_context

return context identifier.

=cut


# Descriptions: set up context.
#    Arguments: OBJ($self) STR($context)
# Side Effects: update $current_context variable.
# Return Value: none
sub set_context
{
    my ($self, $context) = @_;

    $current_context = $context;

    unless (defined $_fml_pool->{ $current_context }->{ _fml_PCB }) {
	$_fml_pool->{ $current_context }->{ _fml_PCB } = {};
    }
    $_fml_PCB = $_fml_pool->{ $current_context }->{ _fml_PCB };
}


# Descriptions: get context.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_context
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
    print STDERR "1. default context\n";
    $pcb->set($category, "ml_name", "test");
    $pcb->dump_variables();

    print STDERR "2. context switch\n";
    my $saved_context = $pcb->get_context();
    $pcb->set_context($ml);
    $pcb->set($category, "ml_name", "elena");
    $pcb->dump_variables();

    print STDERR "3. back again to default context\n";
    $pcb->set_context($saved_context);
    $pcb->dump_variables();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::PCB first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
