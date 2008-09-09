#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::String::Banner::Image;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $banner_table);
use Carp;

use FML::Char::Ascii::Data;
$banner_table = $FML::Char::Ascii::Data::banner_table;


=head1 NAME

FML::String::Banner::Image - generate a banner by using GD library.

=head1 SYNOPSIS

    use FML::String::Banner::Image;
    my $banner = new FML::String::Banner::Image;
    my $png    = $banner->as_png($_string);

    use FileHandle;
    my $wh = new FileHandle "> /var/tmp/test.png";
    if (defined $wh) {
        $wh->binmode();
        $wh->print($png);
        $wh->close();
    }
    else {
        croak("cannot open /var/tmp/test.png");
    }

=head1 DESCRIPTION

See L<FML::String::Banner> CLASS. This class provides the image part
of the class. 

Currently the image format is PNG only (but extensible if needed).

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 as_png($string)

return a generated banner as PNG image.

=cut


# Descriptions: return a generated banner as PNG image.
#    Arguments: OBJ($self) STR($string)
# Side Effects: none
# Return Value: IMAGE
sub as_png
{
    my ($self, $string) = @_;

    $self->_bitmap_string($string);
    $self->_bitmap_merge();
}


# Descriptions: return color table as HASH_REF.
#    Arguments: OBJ($self) OBJ($image)
# Side Effects: none
# Return Value: HASH_REF
sub _bitmap_color_table_example
{
    my ($self, $image) = @_;

    # allocate some colors
    my $white = $image->colorAllocate(255, 255, 255);
    my $black = $image->colorAllocate(  0,   0,   0);
    my $red   = $image->colorAllocate(255,   0,   0);
    my $blue  = $image->colorAllocate(  0,   0, 255);

    my $color_table = {
	white => $white,
	black => $black,
	red   => $red,
	blue  => $blue,
    };

    return $color_table;
}


# Descriptions: build a new image template.
#    Arguments: OBJ($self) NUM($width) NUM($height)
# Side Effects: none
# Return Value: IMAGE
sub _bitmap_new_image
{
    my ($self, $width, $height) = @_;

    # 8*8 x 8*8 dots.
    $width  ||= 64;
    $height ||= 64;

    use GD;
    my $image = new GD::Image($width, $height);
    my $color_table = $self->_bitmap_color_table_example($image);
    $image->transparent($color_table->{ black });
    $image->interlaced('true');
    return $image;
}


# Descriptions: merge character images to one string image.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: IMAGE
sub _bitmap_merge
{
    my ($self) = @_;

    my $image_buffer = $self->{ _image_buffer } || [];
    my $image = $self->_bitmap_new_image(64*8, 64*2);

    my $i = 0;
    for (my $i = 0; $i < 8; $i++) {
	my $im = $image_buffer->[ $i ];
	$image->copyResampled($im,
			      64*$i, int(rand(32)),
			      32, 32,
			      96, 96, 96, 96);
    }

    return $image->png;
}


# Descriptions: create a string image.
#    Arguments: OBJ($self) STR($string)
# Side Effects: $self modified.
# Return Value: none
sub _bitmap_string
{
    my ($self, $string) = @_;
    my (@image_buffer)  = ();

    my $len = length($string);
    for (my $i = 0; $i < $len; $i++) {
	my $c     = substr($string, $i, 1);
	$image_buffer[ $i ] = $self->_bitmap_char($c, $i);
    }

    $self->{ _image_buffer } = \@image_buffer;
}


# Descriptions: create one character and rotate it a little.
#    Arguments: OBJ($self) STR($char) NUM($pos)
# Side Effects: none
# Return Value: IMAGE
sub _bitmap_char
{
    my ($self, $char, $pos) = @_;
    my ($x, $y) = (0, 0);

    my $image = $self->_bitmap_new_image(128, 128);

    # XXX 8 is the magic number
    # XXX since each letter of the ascii banner_table is 8x8 dots.
    my $banner = $banner_table->{ $char };
    for my $line (@$banner) {
	++$x;
	for (my $i = 0; $i < 8; $i++) {
	    my $c = substr($line, $i, 1);
	    $y = $i + 1;
	    if ($c =~ /^\S+$/) {
		$self->_create_sub_image($image, $x, $y);
	    }
	}
    }

    # rotate the image.
    my $rt_image = $self->_bitmap_new_image(128, 128);
    my $angle    = $self->_random_drift(8);
    $rt_image->copyRotated($image,
			   64, 64,
			   0, 0,
			   128, 128, $angle);
    return $rt_image;
}


# Descriptions: create a part of a character image.
#    Arguments: OBJ($self) OBJ($image) NUM($x) NUM($y)
# Side Effects: none
# Return Value: none
sub _create_sub_image
{
    my ($self, $image, $x, $y) = @_;
    my $color_table = $self->_bitmap_color_table_example($image);

    # drift the end position a little.
    my ($r0, $r1, $r2, $r3) = ($self->_random_drift(),
			       $self->_random_drift(),
			       $self->_random_drift(),
			       $self->_random_drift());

    # region
    my ($c0, $c1, $c2, $c3) = ($y*8 + $r0 + 32,
			       $x*8 + $r1 + 32,
			       $y*8 + 8 + $r2 + 32,
			       $x*8 + 8 + $r3 + 32);


    my $type = int(rand(4)) % 4;
    $image->setThickness($type);

    $type = int(rand(4)) % 4;
    if ($type == 0) {
	$image->filledRectangle($c0, $c1, $c2, $c3, $color_table->{ red });
    }
    elsif ($type == 1) {
	$image->filledRectangle($c0, $c1, $c2, $c3, $color_table->{ blue });
    }
    elsif ($type == 2) {
	$image->filledArc($c0 +4, $c1 +4, 8, 8, 0, 360, $color_table->{black});
    }
    elsif ($type == 3) {
	$image->filledArc($c0 +4, $c1 +4, 9, 9, 0, 360, $color_table->{ red });
    }
    else {
	$image->filledRectangle($c0, $c1, $c2, $c3, $color_table->{ black });
    }
}


# Descriptions: return a randomized drift parameter.
#    Arguments: OBJ($self) NUM($max)
# Side Effects: none
# Return Value: NUM
sub _random_drift
{
    my ($self, $max) = @_;

    my $shift = int(rand($max || 2));

    my $pm = int(rand(2)) % 1;
    if ($pm == 1) {
	return( -1 * $shift );
    }
    else {
	return( $shift );
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::String::Banner::Image appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
