#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Base.pm,v 1.7 2002/03/26 03:59:44 fukachan Exp $
#

package FML::Restriction::Base;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

=head1 NAME

FML::Restriction::Base -- define safe data representations

=head1 SYNOPSIS

    use FML::Restriction::Base;
    $safe = new FML::Restriction::Base;
    my $regexp = $safe->regexp();

=head1 DESCRIPTION

FML::Restriction::Base provides data regexp considered as safe.

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

We permit the variable name representation as a subset of RFC
definitions for conveninece and security.

=head2 domain name

A domain name is case insensitive (see RFC). For example, 
   fml.org
   FML.org
   123.f-m-l.org

=head2 user

Very restricted since strict 822 or 2822 representation is very
difficult and may be insecure in some cases.

By the way, "_" is derived from lotus notes ? Anyway we permit "_" for
convenience.

=head2 mail address

off cource, "user@domain", described above.

=cut

my $domain_regexp  = '[-A-Za-z0-9\.]+';
my $user_regexp    = '[-A-Za-z0-9\._]+';
my %basic_variable =
    (
     # address, user and domain et.al.
     'address'           => $user_regexp.'\@'.$domain_regexp,
     'address_specified' => $user_regexp.'\@'.$domain_regexp,
     'address_selected'  => $user_regexp.'\@'.$domain_regexp,
     'domain'            => $domain_regexp,
     'user'              => $user_regexp,
     'ml_name'           => $user_regexp,

     # fml specific parameters
     'action'            => '[-A-Za-z_]+',
     'command'           => '[-A-Za-z_]+',
     'article_id'        => '\d+',

     # file, directory et.al.
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


#
# debug
#
if ($0 eq __FILE__) {
    for my $k (keys %basic_variable) { 
	printf "%-20s => %s\n", $k, $basic_variable{ $k };
    }
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
