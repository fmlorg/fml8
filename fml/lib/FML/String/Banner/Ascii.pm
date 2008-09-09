#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::String::Banner::Ascii;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $banner_table);
use Carp;

use FML::Char::Ascii::Data;
$banner_table = $FML::Char::Ascii::Data::banner_table;


=head1 NAME

FML::String::Banner::Ascii - generate an ascii bannner.

=head1 SYNOPSIS

    use FML::String::Banner::Ascii;
    my $banner = new FML::String::Banner::Ascii;
    print $banner->as_ascii("TRIAL_PASSWORD", 8);

=head1 DESCRIPTION

See L<FML::String::Banner> CLASS. This class provides the ascii part
of the class.

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


=head2 as_ascii($string, $drift)

return an ascii banner string. The string is specificed by the
argument $string. The vertical position of each character in the
$string is shifted randomly within the $drift characters.

=cut


# Descriptions: return an ascii banner string. The string is
#               specificed by the argument $string. The vertical 
#               position of each character in the $string is shifted 
#               randomly within the $drift characters.
#    Arguments: OBJ($self) STR($string) NUM($drift)
# Side Effects: none
# Return Value: STR
sub as_ascii
{
    my ($self, $string, $drift) = @_;
    my (@banner)  = ();

    srand(time|$$);

    my ($_seed)   = $drift || 8; 
    my ($strlen)  = length($string);
    for (my $i = 0; $i < $strlen; $i++) {
	my $c = substr($string, $i, 1);
	my $t = $banner_table->{ $c };

	# stuff the banner into the final buffer with random height position;
	my $height_begin = int(rand($drift));
	for (my $h = 0, my $j = 0; $h < 8 + $drift; $h++) {
	    if ($h < $height_begin || $h >= $height_begin + 8) {
		$banner[ $h ] .= "       ";
	    }
	    else {
		$banner[ $h ] .= $t->[ $j++ ];
	    }
	    $banner[ $h ] .= "  ";
	}
    }

    my $r = join("\n", @banner);
    return sprintf("%s\n", $r);
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

FML::String::Banner::Ascii appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
