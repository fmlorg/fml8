#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: QMail.pm,v 1.21 2004/03/12 04:22:56 fukachan Exp $
#

package FML::Process::QMail;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);


# Descriptions: standard contructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
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

#
# XXX-TODO: NOT YET IMPLERMENTED.
#


# Descriptions: qmail style command extention
#               elena-subscribe@domain implies
#               "mail message body with subscribe to elena-ctl@domain"
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub DotQmailExt
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    # get ?
    my $ext = $ENV{'EXT'};

    unless ($ext) {
	$curproc->log("no extension address");
	return;
    }

    &$curproc->log("dot-qmail-ext[0]: $ext");
    my ($key)    = (split(/\@/, $config->{ article_post_address }))[0];
    my ($keyctl) = (split(/\@/, $config->{ command_mail_address }))[0];

    if ($ext =~ /^($key)$/i) {
	return '';
    }
    elsif ($keyctl&& ($ext =~ /^($keyctl)$/i)) {
	return '';
    }

    $curproc->log("dot-qmail-ext: $ext");
    $ext =~ s/^$key//i;
    $ext =~ s/\-\-/\@/i; # since @ cannot be used
    $ext =~ s/\-/ /g;
    $ext =~ s/\@/-/g;
    $curproc->log("\$ext -> $ext");

    # XXX: "# command" is internal represention
    return sprintf("# %s", $ext);
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

FML::Process::QMail first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
