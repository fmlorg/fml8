#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Param.pm,v 1.2 2001/11/09 00:07:10 fukachan Exp $
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

my %allow_regexp = (
		    'address'    => '[-a-z0-9_]@[-A-Z0-9\.]+',
		    'ml_name'    => '[-a-z0-9_]+',
		    'action'     => '[a-z]+',
		    'user'       => '[-a-z0-9_]+',
		    'article_id' => '\d+',
		    );


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
#      History: fml 4.0's SecureP()
# Return Value: none
sub safe_param
{
    my ($self, $key) = @_;

    if (defined param($key) && defined $allow_regexp{ $key }) {
	my $value  = param($key);
	my $filter = $allow_regexp{ $key };

	if ($value =~ /^$filter$/) {
	    return $value;
	}
	else {
	    croak("parameter $key has invalid character");
	}
    }
    else {
	croak("parameter $key not permitted");
    }
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
