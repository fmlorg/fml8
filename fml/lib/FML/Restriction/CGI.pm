#-*- perl -*-
#
# Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: CGI.pm,v 1.12 2004/07/23 13:16:43 fukachan Exp $
#

package FML::Restriction::CGI;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Restriction::Base;
@ISA = qw(FML::Restriction::Base);

=head1 NAME

FML::Restriction::CGI -- define safe data regexp for CGI modules.

=head1 SYNOPSIS

    use FML::Restriction::CGI;
    $safe = new FML::Restriction::CGI;
    my $regexp = $safe->method_regexp();

    if ($data =~ /^($regexp)$/) {
	# o.k. do something ...
    }

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



# Descriptions: return a set of basic variable safe expressions as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub param_regexp
{
    my ($self) = @_;
    return $self->basic_variable();
}


# Descriptions: return a set of method safe expressions as HASH_REF.
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


#
# debug
#
if ($0 eq __FILE__) {
    my $safe   = new FML::Restriction::CGI;
    my $regexp = $safe->param_regexp();

    print "-- safe parameter regexp\n";
    for my $k (keys %$regexp) {
	printf "%-20s => %s\n", $k, $regexp->{ $k };
    }

    $regexp = $safe->method_regexp();
    print "\n-- safe method regexp\n";
    for my $k (keys %$regexp) {
	printf "%-20s => %s\n", $k, $regexp->{ $k };
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
