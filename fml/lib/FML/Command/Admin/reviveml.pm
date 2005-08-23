#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
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
    $obj->reviveml($curproc, $command_args);

See C<FML::Command> for more details.

=head1 DESCRIPTION

set up a new mailing list.
create mailing list directory,
install config.cf, include, include-ctl et. al.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: set up a new mailing list.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();

    my $ml_home_dir      = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $ml_home_dir_prev = 
	$curproc->ml_home_dir_find_latest_removed_path($ml_name, $ml_domain);

    $curproc->logdebug("ml_name=$ml_name ml_domain=$ml_domain");
    $curproc->logdebug("dir=$ml_home_dir_prev -> $ml_home_dir");

    if (-d $ml_home_dir_prev && ! -d $ml_home_dir) {
	rename($ml_home_dir_prev, $ml_home_dir);
    }

    if (!-d $ml_home_dir_prev && -d $ml_home_dir) {
	$curproc->log("revived ml_home_dir from $ml_home_dir_prev");
    }

    $self->SUPER::set_force_mode($curproc, $command_args);
    $self->SUPER::process($curproc, $command_args);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::reviveml first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
