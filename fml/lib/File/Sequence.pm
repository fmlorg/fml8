#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Sequence.pm,v 1.24 2002/07/02 12:51:39 fukachan Exp $
#

package File::Sequence;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use ErrorStatus qw(error_set error error_clear);

my $debug = 0;

=head1 NAME

File::Sequence - maintain the sequence number

=head1 SYNOPSIS

To get the latest $article_id,

   use File::Sequence;
   my $sfh = new File::Sequence { sequence_file => $seq_file };
   my $id  = $sfh->et_id;
   if ($sfh->error) { use Carp; carp( $sfh->error ); }

to increment $article_id and get it

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
for example, the article number typically.

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

=head2 C<get_id([$file])>

get the sequence number from specified C<$file>.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: object itself holds a few local _variables
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ _sequence_file } = $args->{ sequence_file };
    $me->{ _modulus }       = $args->{ modulus };
    return bless $me, $type;
}


# Descriptions: increment the sequence number
#    Arguments: OBJ($self) [STR($file)]
#               If $file is not specified,
#               the sequence_file parameter in new().
# Side Effects: the number holded in $file is incremented
# Return Value: NUM(sequence number)
sub increment_id
{
    my ($self, $file) = @_;
    my $id       = 0;
    my $seq_file = defined $file ? $file : $self->{ _sequence_file };

    unless (defined $seq_file) {
	$self->error_set("the sequence file is undefined");
	return 0;
    };

    unless ($seq_file) {
	$self->error_set("the sequence file is not specified");
	return 0;
    };

    # touch the sequence file if it does not exist.
    unless (-f $seq_file) {
	eval q{
	    use File::Utils qw(touch);
	    touch($seq_file);
	};
    };

    use IO::Adapter::AtomicFile;
    my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($seq_file);

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
    if (defined $wh) {
	print $wh $id, "\n";
	$wh->close;
    }
    else {
	$self->error_set("cannot save id");
    }

    $id;
}


# Descriptions: get sequence
#    Arguments: OBJ($self) [STR($file)]
#               If $file is not specified,
#               the sequence_file parameter in new().
# Side Effects: the number holded in $file is incremented
# Return Value: NUM(sequence number)
sub get_id
{
    my ($self, $file) = @_;
    my $id       = 0;
    my $seq_file = defined $file ? $file : $self->{ _sequence_file };

    unless (defined $seq_file) {
	$self->error_set("the sequence file is undefined");
	return 0;
    };

    unless ($seq_file) {
	$self->error_set("the sequence file is not specified");
	return 0;
    };

    # touch the sequence file if it does not exist.
    unless (-f $seq_file) {
	$self->error_set("the sequence file not found");
	return 0;
    };

    use IO::Adapter::AtomicFile;
    my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($seq_file);

    # read the current sequence number
    if (defined $rh) {
	$id = $rh->getline;
	$rh->close;
    }
    else {
	$self->error_set("cannot open the sequence file");
	return 0;
    }

    return $id;
}


=head2 search_max_id($args)

To search max_id in hash key,

    $self->search_max_id( { hash => \%hash_table });

to search max_id among all keys,

    $self->search_max_id( {
	hash => \%hash_table,
	full_search => 1,
    });

=cut


# Descriptions: search max id number
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub search_max_id
{
    my ($self, $args) = @_;

    # full search
    if (defined $args->{ hash } && defined $args->{ full_search } ) {
	my $hash = $args->{ hash };
	my $max  = 0;

	my ($k, $v);
	while (($k, $v) = each %$hash) {
	    $max = $max > $k ? $max : $k;
	}

	return $max;
    }
    # old style, search max from bottom or top (e.g. 0 or 1)
    elsif (defined $args->{ hash }) {
    	if ($self->get_id() > 0) {
	    $self->_search_max_id_from_top($args);
	}
	else {
	    $self->_search_max_id_from_bottom($args);
	}
    }
    else {
	warn("no argument");
    }
}


# Descriptions: search max id number from the bottom
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub _search_max_id_from_bottom
{
    my ($self, $args) = @_;
    my ($pebot, $k, $v);
    my $unit = 50;

    if (defined $args->{ hash }) {
	my $hash = $args->{ hash };
	($pebot, $v) = each %$hash;

	print STDERR "0. ", $pebot, "\n" if $debug;

      PEBOT_SEARCH:
	while (1) {
	    last PEBOT_SEARCH unless defined $hash->{ $pebot + $unit };
	    $pebot += $unit;
	    print STDERR "1. ", $pebot, "\n" if $debug;
	}

	# increment by 1.
	do {
	    $pebot++;
	    print STDERR "2. ", $pebot, "\n" if $debug;
	} while (defined $hash->{ $pebot + 1 });

	return $pebot;
    }
    else {
	warn("no argument");
    }
}

# Descriptions: search max id number from the top
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub _search_max_id_from_top
{
    my ($self, $args) = @_;
    my ($pebot, $k, $v);
    my $unit  = 50;
    my $debug = 1;

    $pebot = $self->get_id();
    print STDERR "get_id ", $pebot, "\n" if $debug;

    if (defined $args->{ hash }) {
	my $hash = $args->{ hash };

	print STDERR "0. ", $pebot, "\n" if $debug;

      PEBOT_SEARCH:
	while ($pebot > 0) {
	    last PEBOT_SEARCH if defined $hash->{ $pebot - $unit };
	    last PEBOT_SEARCH if(($pebot - $unit) <= 0);
	    $pebot -= $unit;
	}

	# decrement by 1.
	while(! defined $hash->{ $pebot - 1 }) {
	    $pebot--;
	    return 0 if($pebot <= 0);
	}

	return $pebot;

    }
    else {
	warn("no argument");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

File::Sequence appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
