#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Param.pm,v 1.6 2001/11/13 03:43:07 fukachan Exp $
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

@EXPORT_OK = qw(safe_param %allow_regexp);

my %allow_regexp = 
    (
     'address'    => '[-a-z0-9_]+\@[-A-Za-z0-9\.]+',
     'ml_name'    => '[-a-z0-9_]+',
     'action'     => '[-a-z_]+',
     'command'    => '[-a-z_]+',
     'user'       => '[-a-z0-9_]+',
     'article_id' => '\d+',
     );

my %allow_regexp_list = 
    (
     'threadcgi_change_status' => 'change_status\.(__ml_name_regexp__)\/(\d+)',
     );


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
#      History: fml 4.0's SecureP()
# Return Value: none
sub safe_param
{
    my ($self, $key) = @_;

    if (defined $allow_regexp{ $key }) {
	if (defined param($key)) {
	    my $value  = param($key);
	    my $filter = $allow_regexp{ $key };

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

    # convert $key => regexp
    $key = $allow_regexp_list{ $key };
    for my $regexpkey (keys %allow_regexp) {
	my $x = "__${regexpkey}_regexp__";
	my $y = $allow_regexp{$regexpkey};
	$key =~ s/$x/$y/g;
    }

    # search
    for my $x (param()) {
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
