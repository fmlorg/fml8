#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::String::Random;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::String::Random - create a random string.

=head1 SYNOPSIS

    my $random = new FML::String::Random;
    my $magic = $random->magic_string();
    my $id    = $random->identifier($magic);

=head1 DESCRIPTION

This class generates a magic string and the identifier used for the
session ID.

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


=head2 magic_string()

generate a random magic string.

Currently, the string is a combination of

    qw(a b c d e f g h k m n p r s t x y z 2 3 4 5 6 8);

letters.

=cut


# Descriptions: generate a random magic string.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub magic_string
{
    my ($self) = @_;

    # XXX Crypt::RandPasswd may be too slow sometimes.

    my (@string) = qw(a b c d e f g h k m n p r s t x y z 2 3 4 5 6 8);
    my ($strlen) = $#string;
    my (@result) = ();

    srand(time|$$);
    for (my $i = 0; $i < 8; $i++) {
	my $j = int(rand($strlen));
	$result[ $i ] = $string[ $j ];
    }

    return join("", @result);
}


=head2 identifier($buf)

generate an identifier from $buf. It is used for the session ID.

=cut


# Descriptions: generate an identifier from $buf.
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: STR
sub identifier
{
    my ($self, $buf) = @_;

    my ($id_01) = sprintf("%s %s %s", rand(time), $$, $buf);
    my ($id_02) = sprintf("%s %s %s", $$, $buf, rand(time));

    use Mail::Message::Checksum;
    my $cksum  = new Mail::Message::Checksum;
    my $sum    = $cksum->md5( \$id_01 );
    my $sum_ya = $cksum->md5( \$id_02 );
    my $pebot  = int(rand(32));
    my $sum_l  = substr($sum, 0, $pebot -1);
    my $sum_r  = substr($sum, $pebot + 1, 32 - $pebot);
    return sprintf("%s%s%s", $sum_r, $sum_ya, $sum_l);
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    my $random = new FML::String::Random;
    my $magic = $random->magic_string();
    my $id    = $random->identifier($magic);
    printf("magic string = %s\n", $magic);
    printf("identifier   = %s\n", $id);
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

FML::String::Random appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
