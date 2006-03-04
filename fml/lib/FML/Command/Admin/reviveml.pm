#-*- perl -*-
#
#  Copyright (C) 2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: reviveml.pm,v 1.3 2006/02/15 13:44:03 fukachan Exp $
#

package FML::Command::Admin::reviveml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::newml;
@ISA = qw(FML::Command::Admin::newml);


=head1 NAME

FML::Command::Admin::reviveml - set up a new mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::reviveml;
    $obj = new FML::Command::Admin::reviveml;
    $obj->reviveml($curproc, $command_context);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list.
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 process($curproc, $command_context)

=cut


# Descriptions: set up a new mailing list.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();

    my $ml_home_dir      = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $ml_home_dir_prev =
	$curproc->ml_home_dir_find_latest_deleted_path($ml_name, $ml_domain);

    $curproc->logdebug("ml_name=$ml_name ml_domain=$ml_domain");
    $curproc->logdebug("dir=$ml_home_dir_prev -> $ml_home_dir");

    if (-d $ml_home_dir_prev && ! -d $ml_home_dir) {
	rename($ml_home_dir_prev, $ml_home_dir);
    }

    if (!-d $ml_home_dir_prev && -d $ml_home_dir) {
	$curproc->log("revived ml_home_dir from $ml_home_dir_prev");
    }

    $self->SUPER::set_force_mode($curproc, $command_context);
    $self->SUPER::process($curproc, $command_context);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::reviveml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
