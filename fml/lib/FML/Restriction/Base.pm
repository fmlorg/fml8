#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Base.pm,v 1.6 2002/03/24 11:18:09 fukachan Exp $
#

package FML::Restriction::Base;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

=head1 NAME

FML::Restriction::Base -- define safe data class

=head1 SYNOPSIS

    use FML::Restriction::Base;
    $safe = new FML::Restriction::Base;
    my $regexp = $safe->regexp();

=head1 DESCRIPTION

FML::Restriction::Base provides data type considered as safe.

=head1 METHODS

=head2 C<new($args)>

usual constructor.

=cut


# Descriptions: constructor.
#               avoid default fml new() since we do not need it.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 Basic Parameter Definition for common use

   %basic_variable

=cut


my %basic_variable =
    (
     'address'           => '[-A-Za-z0-9_\.]+\@[-A-Za-z0-9\.]+',
     'address_specified' => '[-A-Za-z0-9_\.]+\@[-A-Za-z0-9\.]+',
     'address_selected'  => '[-A-Za-z0-9_\.]+\@[-A-Za-z0-9\.]+',

     'user'              => '[-A-Za-z0-9_\.]+',
     'ml_name'           => '[-A-Za-z0-9_\.]+',
     'action'            => '[-A-Za-z_]+',
     'command'           => '[-A-Za-z_]+',
     'article_id'        => '\d+',

     # directory
     'directory'         => '[-a-zA-Z0-9]+',
     'file'              => '[-a-zA-Z0-9]+',
     );


# Descriptions: return HASH_REF of basic variable regexp list
#    Arguments: none
# Side Effects: none
# Return Value: HASH_REF
sub basic_variable
{
    return \%basic_variable;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
