#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: SafeData.pm,v 1.5 2001/11/23 02:52:24 fukachan Exp $
#

package FML::Process::SafeData;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

=head1 NAME

FML::Process::SafeData -- define safe data class

=head1 SYNOPSIS

    use FML::Process::SafeData;
    $safe = new FML::Process::SafeData;
    my $regexp = $safe->regexp();

=head1 DESCRIPTION

FML::Process::SafeData provides data type considered as safe.

=head1 METHODS

=head2 C<new($args)>

usual constructor.

=cut


# avoid default fml new() since we do not need it.
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


=head1 Safe Parameter Definition for programs kicked by MTA

not defined yet.

Please extract regexp hash { varname => allowed_regexp } as HASH
REFERENCE via the following access method:

    ?

=head1 Safe Parameter Definition for CGI use

Please extract regexp hash { varname => allowed_regexp } as HASH
REFERENCE via the following access method:

    cgi_param_regexp()
    cgi_method_regexp()

=cut


my %cgi_methond = 
    (
     'threadcgi_change_status' => 'change_status\.(__ml_name_regexp__)\/(\d+)',
     );



sub cgi_param_regexp
{ 
    my ($self) = @_;

    return \%basic_variable;
}


sub cgi_method_regexp
{ 
    my ($self) = @_;

    # expand __var__regexp__ to regular expression defined in other hash
    for my $key (keys %cgi_methond) {
	my $value = $cgi_methond{ $key };
	if ($value =~ /__/o) {

	    # expand variables defined in %basic_variable HASH
	    for my $regexpkey (keys %basic_variable) {
		my $x = "__${regexpkey}_regexp__";
		my $y = $basic_variable{$regexpkey};
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
