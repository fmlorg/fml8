#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::SequenceFile;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Errors qw(error_reason error error_reset);

=head1 NAME

FML::SequenceFile - maintain the sequence number

=head1 SYNOPSIS

   use FML::SequenceFile;
   my $sfh = new FML::SequenceFile { sequence_file => $seq_file };
   my $id  = $sfh->increment_id;
   if ($sfh->error) { use Carp; carp( $sfh->error ); }

=head1 DESCRIPTION

=head2 C<new($args)>

$args->{ sequence_file } is the file holding the current sequence number.

=head2 C<increment_id([$file])>

increment the sequence number.

=cut

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ _sequence_file } = $args->{ sequence_file };
    return bless $me, $type;
}


sub increment_id
{
    my ($self, $file) = @_;
    my $id = 0;
    my $seq_file = $file || $self->{ _sequence_file };

    unless ($seq_file) {
	$self->error_reason("the sequence file is not specified");
	return 0;
    };

    # touch the sequence file if it does not exist.
    unless (-f $seq_file) {
	use FML::Utils qw(touch);
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
	$self->error_reason("cannot open the sequence file");
	return 0;
    }

    # increment $id. The incremented number is the current article ID.
    $id++;

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

FML::SequenceFile appeared in fml5.

=cut


1;
