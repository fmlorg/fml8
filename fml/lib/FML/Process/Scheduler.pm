#-*- perl -*-
#
# Copyright (C) 2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Scheduler.pm,v 1.14 2002/08/03 10:35:09 fukachan Exp $
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
    my $qdir   = $config->{ scheduler_queue_dir };

    unless (-d $qdir) {
	eval q{
	    use File::Utils qw(mkdirhier);
	    mkdirhier($qdir, $config->{ default_dir_mode } || 0755 );
	};
    }

    return bless $me, $type;
}


# Descriptions:
#    Arguments: OBJ($self) STR($key)
# Side Effects:
# Return Value: none
sub queue_in
{
    my ($self, $key) = @_;
}


# Descriptions:
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects:
# Return Value: none
sub exits
{

}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Scheduler appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
