#-*- perl -*-
#
# Copyright (C) 2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Base.pm,v 1.15 2002/09/22 14:56:55 fukachan Exp $
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
    my $regexp = $safe->basic_variable();

    if ($data =~ /^($regexp)$/) {
	# o.k. do something ...
    }

=head1 DESCRIPTION

FML::Restriction::Base provides data regexp considered as safe.

ALL FML MODULES SHOULD USE THIS MODULE if it needs to check whether
a variable is safe or not.

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
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 Basic Parameter Definitions for common use

We permit the variable name representation as a subset of RFC
definitions for conveninece and security.

=head2 domain name

A domain name is case insensitive (see RFC). For example,
   fml.org
   FML.org
   123.f-m-l.org

=head2 user

Very restricted since strict 822 or 2822 representation is very
difficult, so may be insecure in some cases.

By the way, "_" is derived from lotus notes ? Anyway we permit "_" for
convenience.

=head2 mail address

Of cource, "user@domain", described above.

=cut

my $domain_regexp  = '[-A-Za-z0-9\.]+';
my $user_regexp    = '[-A-Za-z0-9\._]+';
my $command_regexp = '[-A-Za-z0-9_]+';
my $file_regexp    = '[-A-Za-z0-9_]+';
my $dir_regexp     = '[-A-Za-z0-9_]+';
my %basic_variable =
    (
     # address, user and domain et.al.
     'address'           => $user_regexp.'\@'.$domain_regexp,
     'address_specified' => $user_regexp.'\@'.$domain_regexp,
     'address_selected'  => $user_regexp.'\@'.$domain_regexp,
     'domain'            => $domain_regexp,
     'user'              => $user_regexp,
     'ml_name'           => $user_regexp,
     'ml_name_specified' => $user_regexp,

     # fml specific parameters
     'action'            => $command_regexp,
     'command'           => $command_regexp,
     'navi_command'      => $command_regexp,
     'article_id'        => '\d+',

     # file, directory et.al.
     'directory'         => $dir_regexp,
     'file'              => $file_regexp,
     'map'               => $file_regexp,
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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
