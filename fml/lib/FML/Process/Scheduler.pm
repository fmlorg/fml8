#-*- perl -*-
#
# Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Scheduler.pm,v 1.24 2004/01/02 16:08:39 fukachan Exp $
#

package FML::Process::Scheduler;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Config;

=head1 NAME

FML::Process::Scheduler -- scheduler.

=head1 SYNOPSIS

    use FML::Process::Scheduler;
    my $scheduler = new FML::Process::Scheduler $curproc;
    $curproc->{ scheduler } = $scheduler;

=head1 DESCRIPTION

This class provides utility functions for scheduler.
However this module is dummy now.

=head1 METHODS

=head2 new($curproc)

constructor. mkdir $event_queue_dir if needed.

=cut


# Descriptions: constructor. mkdir $event_queue_dir if needed.
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


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Scheduler first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
