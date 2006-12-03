#-*- perl -*-
#
#  Copyright (C) 2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: reviveml.pm,v 1.4 2006/03/04 13:48:29 fukachan Exp $
#

package FML::Command::Admin::reviveml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::newml;
@ISA = qw(FML::Command::Admin::newml);


=head1 NAME

FML::Command::Admin::reviveml - revive the specified mailing list.

=head1 SYNOPSIS

    use FML::Command::Admin::reviveml;
    $obj = new FML::Command::Admin::reviveml;
    $obj->reviveml($curproc, $command_context);

See C<FML::Command> for more details.

=head1 DESCRIPTION

revive the specified mailing list.
restore the mailing list directory and 
re-setup the ML by running "makefml newml" process.

=head1 METHODS

=head2 process($curproc, $command_context)

main dispatcher to revive the specified mailing list.

This routine restores the mailing list directory and
upcalls "makefml newml" programs to re-setup the ML.

=cut


# Descriptions: revive the specified mailing list.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: create mailing list directory,
#               install config.cf, include, include-ctl et. al.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $ml_name   = $curproc->ml_name()   || '';
    my $ml_domain = $curproc->ml_domain() || '';

    my $ml_home_dir      = $curproc->ml_home_dir($ml_name, $ml_domain);
    my $ml_home_dir_prev =
	$curproc->ml_home_dir_find_latest_deleted_path($ml_name, $ml_domain);

    $curproc->logdebug("ml_name=$ml_name ml_domain=$ml_domain");
    $curproc->logdebug("dir=$ml_home_dir_prev -> $ml_home_dir");

    # ASSERT
    unless ($ml_name)          { croak("ml_name unspecified");}
    unless ($ml_domain)        { croak("ml_domain unspecified");}	
    unless ($ml_home_dir)      { croak("ml_home_dir unspecified");}	
    unless ($ml_home_dir_prev) { croak("ml_home_dir_prev unspecified");}

    # 1. restore the ml_home_dir
    if (-d $ml_home_dir_prev && ! -d $ml_home_dir) {
	if (rename($ml_home_dir_prev, $ml_home_dir)) {
	    use File::Basename;
	    my $prev = basename($ml_home_dir_prev);
	    $curproc->log("revived ml_home_dir from $prev");
	}
	else {
	    $curproc->logerror("cannot rename $ml_home_dir_prev");
	}
    }

    if (!-d $ml_home_dir_prev && -d $ml_home_dir) {
	$curproc->log("use ml_home_dir as itself");
    }

    # 2. re-setup the ML.
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
