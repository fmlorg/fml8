#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: CGI.pm,v 1.18 2001/11/07 14:25:55 fukachan Exp $
#

package FML::Process::CGI::Param;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

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


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
#      History: fml 4.0's SecureP()
# Return Value: none
sub safe_param
{
    my ($key, $filter) = @_;
    my $value = param($key);

    if (defined $filter && defined $value) {
	if ($value =~ /^$filter$/) {
	    return $value;
	}
	else {
	    return undef;
	}
    }
    else {
	return undef;
    }
}


=head2 safe_param_xxx()

get and filter param('xxx') via AUTOLOAD().

=cut


my %allow_regexp = (
		    'address' => '[-a-z0-9_]@[-A-Z0-9\.]+',
		    'ml_name' => '[-a-z0-9_]+',
		    'method'  => '[a-z]+',
		    'user'    => '[-a-z0-9_]+',
		    );


sub AUTOLOAD
{
    my ($curproc) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;

    if ($comname =~ /^safe_param_(\S+)/) {
	my $varname = $1;

	# diagnostic
	unless (defined $allow_regexp{ $varname }) {
	    croak("no allow_regexp for $comname");
	}
	return safe_param($varname, $allow_regexp{ $varname });
    }
    else {
	croak("unknown method $comname");
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
