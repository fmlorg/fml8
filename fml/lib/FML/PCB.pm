#-*- perl -*-
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $Id$
# $FML$ # 注意: cvs のタグを $FML$ にする
#

package FML::PCB;

use strict;
use Carp;

# PCB: Process Control Block
use vars qw(%_fml_PCB);


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


sub FETCH
{
    my ($self, $key) = @_;
    return $_fml_PCB{$key};
}


sub STORE
{
    my ($self, $key, $value) = @_;
    $_fml_PCB{$key} = $value;
}


sub DELETE
{
    my ($self, $key) = @_;
    delete $_fml_PCB{$key};
}


sub CLEAR
{
    my ($self) = @_;
    undef %_fml_PCB;
}


=head1 NAME

FML::PCB -- fml5 PCBuration holding object

=head1 SYNOPSIS

    $PCB = new FML::PCB;

    # get the current value
    $PCB->{recipient_maps};

    # set the new value
    $PCB->{recipient_maps} = 'mysql:toymodel';

    # function style to get/set the value for the key "recipient_maps"
    $PCB->get('recipient_maps');
    $PCB->set('recipient_maps', 'mysql:toymodel');


=head1 DESCRIPTION


=head1 METHOD

=item  Init( ref_to_curproc )

special method only used in the initialization phase.
This method binds $curproc and the %_fml_PCB memory area.

=item  load_file( filename ) 

read the PCBuration file, split key and value and set them to
%_fml_PCB.

=item  get( key )

=item  set( key, value )

=item  dump_variables()

show all {key => value} for debug.

=head1 DATA STRUCTURE

C<%CurProc> holds the CURrent PROCess information.
The hash holds several references to other data structures,
which are mainly hashes.

    $CurProc = {
		# PCBurations
		PCB => {
		    key => value,
		},

		# emulator mode though fml mode in fact
		emulator => $emulator,

		# struct incoming_mail holds the mail input from STDIN.
		incoming_mail => $r_msg,
		article       => $r_msg,
		};

We use r_variable_name syntax where "r_" implies "reference to" here.
C<$r_msg> is the reference to "struct message".

    $r_msg = {
	r_header => \$header,
	r_body   => \$body,
	info   => {
	    mime-version => 1.0, 
	    content-type => {
		charset      => ISO-2022-JP,
	    },
	    size         => $size,
	},
    };

where $header is the object returned by Mail::Header class (CPAN
module) and the $body is the reference to the mail body region on
memory which locates within FML::Parse name space.

=cut

1;
