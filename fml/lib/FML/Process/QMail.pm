#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Process::QMail;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 NAME

NOT YET MERGED - qmail-ext

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASSES

=head1 METHODS

=item C<new()>

... what is this ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::QMail appeared in fml5.

=cut


sub DotQmailExt
{
    local(*e) = @_;
    local($ext, $key, $keyctl);

    # get ?
    ($ext = $ENV{'EXT'}) || return $NULL;

    &Log("dot-qmail-ext[0]: $ext") if $debug_qmail;

    $key    = (split(/\@/, $MAIL_LIST))[0];
    $keyctl = (split(/\@/, $CONTROL_ADDRESS))[0];

    if ($ext =~ /^($key)$/i) {
	return $NULL;
    }
    elsif ($keyctl&& ($ext =~ /^($keyctl)$/i)) {
	return $NULL;
    }

    &Log("dot-qmail-ext: $ext") if $debug_qmail;
    $ext =~ s/^$key//i;
    $ext =~ s/\-\-/\@/i; # since @ cannot be used
    $ext =~ s/\-/ /g;
    $ext =~ s/\@/-/g;
    &Log("\$ext -> $ext");

    # XXX: "# command" is internal represention
    $e{'Body'} = sprintf("# %s", $ext);
}

1;
