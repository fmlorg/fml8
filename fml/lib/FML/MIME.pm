#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::MIME;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
my ($self) = @_;
my ($type) = ref($self) || $self;
my $me     = {};
return bless $me, $type;
}


sub mime_decode_string
{
    my ($str, $type) = @_;

}


sub mime_encode_string
{
    my ($str, $type) = @_;

}


# original idea comes from
# import fml-support: 02651 (hirono@torii.nuie.nagoya-u.ac.jp)
# import fml-support: 03440, Masaaki Hirono <hirono@highway.or.jp>
my $MimeBEncPat = 
	'=\?[Ii][Ss][Oo]-2022-[Jj][Pp]\?[Bb]\?([A-Za-z0-9\+\/]+)=*\?=';

my $MimeQEncPat = 
	'=\?[Ii][Ss][Oo]-2022-[Jj][Pp]\?[Qq]\?([\011\040-\176]+)=*\?=';

#  s/$MimeBEncPat/&kconv(&base64decode($1))/geo;
#  s/$MimeQEncPat/&kconv(&MimeQDecode($1))/geo;
# sub MimeQDecode
# {
#    local($_) = @_;
#    s/=*$//;
#    s/=(..)/pack("H2", $1)/ge;
#    $_;
#}



=head1 NAME

FML::MIME.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut


1;


1;
