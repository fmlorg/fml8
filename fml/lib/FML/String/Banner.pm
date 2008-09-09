#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::String::Banner;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $banner_table);
use Carp;


=head1 NAME

FML::String::Banner - manipulate a banner string.

=head1 SYNOPSIS

    use FML::String::Banner;
    my $banner = new FML::String::Banner;
    $banner->set_string($string);

    # ASCII version.
    my $ascii = $banner->as_ascii();
    printf("\n<pre>[%s]\n\n%s\n</pre>\n", $name_magic, $ascii);

    # PNG version.
    use File::Spec;
    my $png_filename = sprintf("%s.png", $session_id);
    my $image_file   = File::Spec->catfile($html_tmp_dir, $png_filename);

    use FileHandle;
    my $wh = new FileHandle "> $image_file";
    if (defined $wh) {
	$wh->binmode();
	my $png = $banner->as_png();
	$wh->print($png);
	$wh->close();
    }

    my $url_base = $config->{ html_tmp_base_url };
    my $url = sprintf("%s/%s", $url_base, $png_filename);
    printf("\n<p>%s\n\n<image src=\"%s\">\n", $name_magic, $url);

=head1 DESCRIPTION

generate a banner for the specified string. 

The output is either of ascii strings or png format image.

Also, the output is bended. In the case of ascii format, the vertical
position varies randomely within the specified "drift" paremeter (see
set_drift() method). In the case of image (PNG) format, the output
image is vertically varied, bended and be colorful.

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

    srand(time|$$);

    return bless $me, $type;
}


=head2 set_string($string)

set the current string to manipulate.

=head2 get_string()

get the current string to manipulate.

=cut


# Descriptions: set the current string to manipulate.
#    Arguments: OBJ($self) STR($string)
# Side Effects: $self updated.
# Return Value: none
sub set_string
{
    my ($self, $string) = @_;
    $self->{ _string } = $string;
}


# Descriptions: get the current string to manipulate.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_string
{
    my ($self) = @_;
    return($self->{ _string } || '');
}


=head2 set_drift($drift)

set the drift parameter. 

This parameter is a tunable parameter used to shift the letter
position or bend the letter.

=head2 get_drift()

get the drift parameter.

=cut


# Descriptions: set the drift parameter.
#    Arguments: OBJ($self) NUM($drift)
# Side Effects: $self modified.
# Return Value: none
sub set_drift
{
    my ($self, $drift) = @_;
    $self->{ _drift } = $drift;
}


# Descriptions: get the drift parameter.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_drift
{
    my ($self) = @_;
    return($self->{ _drift } || 8);
}


=head2 as_ascii([$string])

generate an ascii based banner string. 

return the generated string image.

=cut


# Descriptions: return a generated banner as an ascii image. 
#    Arguments: OBJ($self) STR($string)
# Side Effects: none
# Return Value: STR
sub as_ascii
{
    my ($self, $string) = @_;
    my ($_string) = $self->get_string() || $string;
    my ($_drift)  = $self->get_drift();

    use FML::String::Banner::Ascii;
    my $banner = new FML::String::Banner::Ascii;
    return $banner->as_ascii($_string, $_drift);
}


=head2 as_png([$string])

generate GD based image as PNG format.

return the generated PNG image format. You need to save it into a
file at the caller side.

=cut


# Descriptions: return a generated banner as a png image. 
#    Arguments: OBJ($self) STR($string)
# Side Effects: none
# Return Value: IMAGE
sub as_png
{
    my ($self, $string) = @_;
    my ($_string) = $self->get_string() || $string;

    use FML::String::Banner::Image;
    my $banner = new FML::String::Banner::Image;
    return $banner->as_png($_string);
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    my $banner = new FML::String::Banner;
    my $string = 'SCX9;AD2';

    $banner->set_string($string);
    my $ascii = $banner->as_ascii();
    my $png   = $banner->as_png($string);
    my $sep   = "-" x 72;
    print $sep, "\n";
    print $ascii;
    print $sep, "\n";
    print $banner->get_string(), "\n";

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

FML::String::Banner appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
