#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Command.pm,v 1.9 2003/03/06 09:31:53 fukachan Exp $
#

package FML::Restriction::Command;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Restriction::Command - safe regexp allowed as a command

=head1 SYNOPSIS

collection of utility functions used in command routines.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: $s looks secure as a command ?
#    Arguments: OBJ($self) STR($s)
# Side Effects: none
#      History: fml 4.0's SecureP()
# Return Value: NUM(1 or 0)
sub _is_secure_command_string
{
   my ($self, $s) = @_;

   # 0. clean up
   $s =~ s/^\s*\#\s*//o; # remove ^#

   # 1. trivial case
   # 1.1. empty
   if ($s =~ /^\s*$/o) {
       return 1;
   }

   # 2. allow
   #           command = [-\d\w]+
   #      mail address = [-_\w]+@[\w\-\.]+
   #   command options = last:30
   #
   # XXX sync w/ mailaddress regexp in FML::Restriction::Base ?
   # XXX hmm, it is difficult.
   #
   if ($s =~/^[-\d\w]+\s*$/o) {
       return 1;
   }
   elsif ($s =~/^[-\d\w]+\s+[\s\w\_\-\.\,\@\:]+$/o) {
       return 1;
   }

   return 0;
}


# Descriptions: incremental regexp match for the given data.
#    Arguments: OBJ($self) VAR_ARGS($data)
# Side Effects: none
# Return Value: NUM(>0 or 0)
sub command_regexp_match
{
    my ($self, $data) = @_;
    my $r = 0;

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;

    if (ref($data)) {
	if (ref($data) eq 'ARRAY') {
	  DATA:
	    for my $x (@$data) {
		next DATA unless $x;

		unless ($safe->regexp_match('command', $x)) {
		    $r = 0;
		    last DATA;
		}
		else {
		    $r++;
		}
	    }
	}
	else {
	    croak("FML::Restriction::Command: wrong data");
	}
    }
    else {
	$r = $safe->regexp_match('command', $data);
    }

    return $r;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Restriction::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
