#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Param.pm,v 1.7 2001/11/13 15:19:18 fukachan Exp $
#

package FML::Process::CGI::Param;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

# load standard CGI routines
use CGI qw/:standard/;

=head1 NAME

FML::Process::CGI::Param - CGI basic functions

=head1 SYNOPSIS

   use FML::Process::CGI::Param;
   my $obj = new FML::Process::CGI::Param;
   $obj->prepare($args);
      ... snip ...

This new() creates CGI object which wraps C<FML::Process::Param>.

=head1 DESCRIPTION

the base class of CGI programs.
It provides basic functions and flow.

=head1 METHODS

=head2 safe_param(str, filter)

=cut


my $debug = defined $ENV{'debug'} ? 1 : 0;


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
#      History: fml 4.0's SecureP()
# Return Value: none
sub safe_param
{
    my ($self, $key) = @_;

    use FML::Process::SafeData;
    my $safe = new FML::Process::SafeData;
    my $safe_param_regexp  = $safe->cgi_param_regexp();
    my $safe_method_regexp = $safe->cgi_method_regexp();

    print STDERR "\n<!-- check param $key -->\n" if $debug;

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


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
#      History: fml 4.0's SecureP()
# Return Value: none
sub safe_paramlist
{
    my ($self, $numregexp, $key) = @_;
    my (@list) = ();

    use FML::Process::SafeData;
    my $safe = new FML::Process::SafeData;
    my $safe_param_regexp  = $safe->cgi_param_regexp();
    my $safe_method_regexp = $safe->cgi_method_regexp();

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
