#-*- perl -*-
#
# Copyright (C) 2001 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: CGI.pm,v 1.3 2001/12/22 09:21:11 fukachan Exp $
#

package FML::Restriction::CGI;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Restriction::Base;
@ISA = qw(FML::Restriction::Base);

=head1 NAME

FML::Restriction::CGI -- define safe data class for CGI module

=head1 SYNOPSIS

    use FML::Restriction::CGI;
    $safe = new FML::Restriction::CGI;
    my $regexp = $safe->regexp();

=head1 DESCRIPTION

FML::Restriction::CGI provides data type considered as safe.

=head1 METHODS

=head1 Safe Parameter Definition for CGI use

Please extract regexp hash { varname => allowed_regexp } as HASH
REFERENCE via the following access method:

    param_regexp()
    method_regexp()

=cut


my %cgi_methond =
    (
     'threadcgi_change_status' => 'change_status\.(__ml_name_regexp__)\/(\d+)',
     );



# Descriptions: return basic variable safe expression
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub param_regexp
{
    my ($self) = @_;
    return $self->basic_variable();
}


# Descriptions: return metho safe expression
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub method_regexp
{
    my ($self) = @_;
    my $basic_variable = $self->basic_variable();

    # expand __var__regexp__ to regular expression defined in other hash
    for my $key (keys %cgi_methond) {
	my $value = $cgi_methond{ $key };
	if ($value =~ /__/o) {

	    # expand variables defined in %basic_variable HASH
	    for my $regexpkey (keys %$basic_variable) {
		my $x = "__${regexpkey}_regexp__";
		my $y = $basic_variable->{$regexpkey};
		$value =~ s/$x/$y/g;
		$cgi_methond{ $key } = $value;
	    }
	}
    }

    return \%cgi_methond;
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
