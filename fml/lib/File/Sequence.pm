#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML: Sequence.pm,v 1.6 2001/04/03 09:31:27 fukachan Exp $
#

package File::Sequence;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use ErrorStatus qw(error_set error error_clear);

=head1 NAME

File::Sequence - maintain the sequence number

=head1 SYNOPSIS

   use File::Sequence;
   my $sfh = new File::Sequence { sequence_file => $seq_file };
   my $id  = $sfh->increment_id;
   if ($sfh->error) { use Carp; carp( $sfh->error ); }

If you divide the $id by some modulus, use

   my $sfh = new File::Sequence { 
       sequence_file => $seq_file,
       modulus       => $modules,
   };
   my $id  = $sfh->increment_id;

For example, if you do new() with modulus 3,

   my $sfh = new File::Sequence { 
       sequence_file => $seq_file,
       modulus       => 3,
   };

$id becomes 0, 1, 2, 0, 1, 2...

=head1 DESCRIPTION

File::Sequence module maintains the sequence number for something, 
for example, the article number.

As an extension, you can generate a cyclic number by this module.
Please specify C<modulus> parameter in new() method if you want to get
a cyclic number.

=head2 C<new($args)>

$args->{ sequence_file } is the file holding the current sequence
number.
$args->{ modulus } is the modulus when you want to get a cyclic
number.

=head2 C<increment_id([$file])>

increment the sequence number.

=cut

require Exporter;
@ISA = qw(Exporter);


# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: object itself holds a few local _variables
# Return Value: object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ _sequence_file } = $args->{ sequence_file };
    $me->{ _modulus }       = $args->{ modulus };
    return bless $me, $type;
}


# Descriptions: increment sequence
#    Arguments: $self [$file]
#               If $file is not specified, 
#               the sequence_file parameter in new().
# Side Effects: the number holded in $file is incremented
# Return Value: number (sequence number)
sub increment_id
{
    my ($self, $file) = @_;
    my $id = 0;
    my $seq_file = $file || $self->{ _sequence_file };

    unless ($seq_file) {
	$self->error_set("the sequence file is not specified");
	return 0;
    };

    # touch the sequence file if it does not exist.
    unless (-f $seq_file) {
	use File::Utils qw(touch);
	touch($seq_file);
    };

    use IO::File::Atomic;
    my ($rh, $wh) = IO::File::Atomic->rw_open($seq_file);

    # read the current sequence number
    if (defined $rh) {
	$id = $rh->getline;
	$rh->close;
    }
    else {
	$self->error_set("cannot open the sequence file");
	return 0;
    }

    # compute the modulus
    if (defined $self->{ _modulus }) {
	my $modulus = $self->{ _modulus };
	$id++;
	$id = $id % $modulus;
    }
    # increment $id. The incremented number is the current article ID.
    else {
	$id++;
    }

    # save $id
    print $wh $id, "\n";
    $wh->close;

    $id;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::Sequence appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
