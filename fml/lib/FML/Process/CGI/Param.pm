#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Param.pm,v 1.10 2001/12/22 09:21:10 fukachan Exp $
#

package FML::Process::CGI::Param;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

# load standard CGI routines
use CGI qw/:standard/;

=head1 NAME

FML::Process::CGI::Param - CGI input restriction

=head1 SYNOPSIS

See FML::CGI:: on usage.

=head1 DESCRIPTION

cleaner for data.

=head1 METHODS

=head2 safe_param(str, key)

return value for key if the value is appropriate.

=cut


# Descriptions: return value for key if the value is appropriate.
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
#      History: similar to fml 4.0's SecureP() and libcgi_cleanup.pl
# Return Value: STR
sub safe_param
{
    my ($self, $key) = @_;

    use FML::Restriction::CGI;
    my $safe = new FML::Restriction::CGI;
    my $safe_param_regexp  = $safe->param_regexp();
    my $safe_method_regexp = $safe->method_regexp();

    if (defined $safe_param_regexp->{ $key }) {
	if (defined param($key)) {
	    my $value  = param($key);
	    my $filter = $safe_param_regexp->{ $key };

	    if ($value =~ /^$filter$/) {
		return $value;
	    }
	    else {
		croak("CGI parameter $key has invalid character");
	    }
	}
	else {
	    # accpeptable but not defined, so return undef anyway
	    return undef;
	}
    }
    else {
	croak("CGI parameter $key is undefined");
    }
}


=head2 safe_paramlist($self, $numregexp, $key)

return HASH_ARRAY for $key.

=cut


# Descriptions: return HASH_ARRAY for key if the value is appropriate.
#    Arguments: OBJ($self) NUM($numregexp) STR($key)
# Side Effects: none
#      History: similar to fml 4.0's SecureP() and libcgi_cleanup.pl
# Return Value: HASH_ARRAY
sub safe_paramlist
{
    my ($self, $numregexp, $key) = @_;
    my (@list) = ();

    use FML::Restriction::CGI;
    my $safe = new FML::Restriction::CGI;
    my $safe_param_regexp  = $safe->param_regexp();
    my $safe_method_regexp = $safe->method_regexp();

    # match method and return HASH ARRAY with matching values
    $key = $safe_method_regexp->{ $key };
    for my $x (param()) {
	print STDERR "\n<!-- check param: $x =~ /^$key$/ -->\n";
	if ($x =~ /^$key$/) {
	    my $value = defined param($x) ? param($x) : '';
	    if ($numregexp == 1) { push(@list, [ $1, $value ] );}
	    if ($numregexp == 2) { push(@list, [ $1, $2, $value ] );}
	    if ($numregexp == 3) { push(@list, [ $1, $2, $3, $value ] );}
	}
    }

    return \@list;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Param appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
