#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Checksum;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA = qw(Exporter);

sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _init($me, $args);

    return bless $me, $type;
}


sub _init
{
    my ($self, $args) = @_;

    if (defined $args->{ program }) {
	$self->{ _program } = $args->{ program };
    }

    my $pkg = 'MD5';
    eval qq{ require $pkg; $pkg->import();};

    unless ($@) {
	$self->{ _type } = 'native';
    }
    else {
	use FML::Utils qw(search_program);
	my $prog = search_program('md5') || search_program('md5sum');
	if (defined $prog) {
	    $self->{ _program } = $prog;
	} 
    }
}


sub md5
{
    my ($self, $r_data) = @_;

    if ($self->{ _type } eq 'native') {
	$self->_md5_native($r_data);
    }
    else {
	$self->_md5_by_program($r_data);
    }

}


sub _md5_native
{
    my ($self, $r_data) = @_;
    my ($buf, $p, $pe);

    $pe = length($$r_data);

    my $md5;
    eval q{ $md5 = new MD5;};
    $md5->reset();

    $p = 0;
    while (1) {
	last if $p > $pe;
	$_  = substr($$r_data, $p, 128);
	$p += 128;
	$md5->add($_);
    }

    $md5->hexdigest();
}


sub _md5_by_program
{
    my ($self, $r_data) = @_;

    if (defined $self->{ _program }) {
	my $program = $self->{ _program };
	
	use FileHandle;
	my ($rh, $wh) = FileHandle::pipe;

	use IPC::Open2;
	my $pid = open2($rh, $wh, $self->{ _program });
	if (defined $pid) {
	    print $wh $$r_data;
	    close($wh);
	    my $cksum = 0;
	    sysread($rh, $cksum, 1024);
	    $cksum =~ s/[\s\n]*$//;
	    close($rh);
	    return $cksum if $cksum;
	}
    }

    undef;
}



=head1 NAME

FML::Checksum - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASSES

=head1 METHODS

=item C<new()>

... what is this ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Checksum appeared in fml5.

=cut

1;
