#-*- perl -*-
#
# Copyright (C) 2002,2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Scheduler.pm,v 1.20 2002/12/18 04:43:52 fukachan Exp $
#

package FML::Process::Scheduler;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

=head1 NAME

FML::Process::Scheduler -- Scheduler utility.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: dummy constructor.
#               avoid the default fml new() since we do not need it.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    my $config = $curproc->config();
    my $qdir   = $config->{ event_queue_dir };

    unless (-d $qdir) {
	$curproc->mkdir($qdir, "mode=public");
    }

    return bless $me, $type;
}


# Descriptions: dummy
#    Arguments: OBJ($self) STR($key)
# Side Effects: none
# Return Value: none
sub queue_in
{
    my ($self, $key) = @_;

    # XXX-TODO: NOT IMPLEMENTED
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub exits
{
    # XXX-TODO: NOT IMPLEMENTED
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Scheduler first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
