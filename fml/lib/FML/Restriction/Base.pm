#-*- perl -*-
#
# Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Base.pm,v 1.31 2004/07/23 13:09:10 fukachan Exp $
#

package FML::Restriction::Base;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

=head1 NAME

FML::Restriction::Base -- define safe data representations.

=head1 SYNOPSIS

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    if ($safe->regexp_match('address', $data)) {
	# o.k. do something ...
    }

=head1 DESCRIPTION

FML::Restriction::Base provides data regexp considered as safe.

ALL FML MODULES SHOULD USE THIS MODULE if it needs to check whether
a variable is safe or not.

=head1 METHODS

=head2 new($args)

constructor.

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

my $domain_regexp  = '[-A-Za-z0-9\.]+';    # domain of user@domain
my $user_regexp    = '[-A-Za-z0-9\._\+]+'; # user of user@domain
my $command_regexp = '[-A-Za-z0-9_]+';     # command name
my $commail_regexp = '[-A-Za-z0-9_:]+';    # allow e.g. mget last:3
my $file_regexp    = '[-A-Za-z0-9_]+';     # file name
my $dir_regexp     = '[-A-Za-z0-9_]+';     # directory name
my $option_regexp  = '[-A-Za-z0-9]+';      # command option
my $number_regexp  = '\d+';                # number
my $address_regexp = sprintf("%s\@%s", $user_regexp, $domain_regexp);
my %basic_variable =
    (
     # address, user and domain et.al.
     'address'           => $address_regexp,
     'address_specified' => $address_regexp,
     'address_selected'  => $address_regexp,
     'domain'            => $domain_regexp,
     'user'              => $user_regexp,
     'ml_name'           => $user_regexp,
     'ml_name_specified' => $user_regexp,

     # fml specific parameters
     'action'            => $command_regexp,
     'command'           => $command_regexp,
     'navi_command'      => $command_regexp,
     'article_id'        => $number_regexp,

     # file, directory et.al.
     'directory'         => $dir_regexp,
     'file'              => $file_regexp,
     'map'               => $file_regexp,

     # unix command switch
     'command_line_options' => $option_regexp,

     # command mail
     'command_mail_substr'  => $commail_regexp,

     # misc
     'language'             => $option_regexp,
     );


#
# XXX-TODO: remove methods except for regexp_match() ???
#


=head2 basic_variable()

return basic variable regexp list as HASH_REF.

NOT USE THIS OUTSIDE FML::Restiction::* classes.

=cut


# Descriptions: return basic variable regexp list as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub basic_variable
{
    my ($self) = @_;

    return \%basic_variable;
}


=head2 regexp_match( class, string )

check if C<string> matches regexp specified by C<class>.
return 1 or undef.

    my $obj = new FML::Restriction::Base;
    if ($obj->regexp_match( "address", $address ) {
	... do something ...
    }

C<regexp_match> can handle some special class not based on regexp:
C<fullpath>.

=cut


# Descriptions: check the string allowed for $class.
#    Arguments: OBJ($self) STR($class) STR($string)
# Side Effects: none
# Return Value: NUM(1(success) or UNDEF(failure))
sub regexp_match
{
    my ($self, $class, $string) = @_;

    if (defined $class && defined $string) {
	if ($class eq 'fullpath') {
	    return $self->_regexp_match_fullpath($string);
	}

	if (defined $basic_variable{ $class }) {
	    my $regexp = $basic_variable{ $class };

	    if ($string =~ /^($regexp)$/) {
		return 1;
	    }
	    else {
		return undef;
	    }

	}
	else {
	    return undef;
	}
    }

    return undef;
}


# Descriptions: check the string allowed for fullpath class.
#               XXX special handling of fully path-ed directory.
#    Arguments: OBJ($self) STR($string)
# Side Effects: none
# Return Value: 1 or UNDEF
sub _regexp_match_fullpath
{
    my ($self, $string) = @_;
    my $regexp = $basic_variable{ 'directory' };
    my $level  = 0;
    my $ok     = 0;

    # remove volume of M$-DOS style.
    $string =~ s/^[A-Za-z]://;

    for my $dir (split(/\/|\\/, $string)) {
	$level++;

	if ($dir =~ /^($regexp)$/ || $dir =~ /^\s*$/o) {
	    $ok++;
	}
    }

    return( $level == $ok ? 1 : undef );
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

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Configure first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
