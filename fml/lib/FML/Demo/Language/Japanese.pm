#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.10 2006/01/07 13:16:41 fukachan Exp $
#

package FML::Demo::Language::Japanese;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Demo::Language::Japanese - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

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


# Descriptions: return mark.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_mark
{
    my ($self) = @_;

    return '¢£';
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Demo::Language::Japanese appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
