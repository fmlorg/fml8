#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: QMail.pm,v 1.10 2001/12/23 07:04:30 fukachan Exp $
#

package FML::Process::QMail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 NAME

FML::Process::QMail - emulate C<qmail-ext> address such as elena-subscribe@

=head1 SYNOPSIS

C<NOT YET IMPLERMENTED>.

=head1 DESCRIPTION

C<NOT YET IMPLERMENTED>.

=head1 TODO

   XXX
   XXX MEMO on TODO
   XXX

   we should not use "# command" representation even though internally.

   check $ext more restrictly.

=head1 METHODS

=cut


# Descriptions: qmail style command extention
#               elena-subscribe@domain implies
#               "mail message body with subscribe to elena-ctl@domain"
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub DotQmailExt
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    # get ?
    my $ext = $ENV{'EXT'};

    unless ($ext) {
	Log("no extension address");
	return;
    }

    &Log("dot-qmail-ext[0]: $ext");
    my ($key)    = (split(/\@/, $config->{ address_for_post }))[0];
    my ($keyctl) = (split(/\@/, $config->{ address_for_command }))[0];

    if ($ext =~ /^($key)$/i) {
	return '';
    }
    elsif ($keyctl&& ($ext =~ /^($keyctl)$/i)) {
	return '';
    }

    &Log("dot-qmail-ext: $ext");
    $ext =~ s/^$key//i;
    $ext =~ s/\-\-/\@/i; # since @ cannot be used
    $ext =~ s/\-/ /g;
    $ext =~ s/\@/-/g;
    &Log("\$ext -> $ext");

    # XXX: "# command" is internal represention
    return sprintf("# %s", $ext);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::QMail appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
