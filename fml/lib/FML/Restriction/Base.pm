#-*- perl -*-
#
# Copyright (C) 2001 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Base.pm,v 1.3 2001/12/22 09:21:11 fukachan Exp $
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
     'address'    => '[-a-z0-9_]+\@[-A-Za-z0-9\.]+',
     'ml_name'    => '[-a-z0-9_]+',
     'action'     => '[-a-z_]+',
     'command'    => '[-a-z_]+',
     'user'       => '[-a-z0-9_]+',
     'article_id' => '\d+',
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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
