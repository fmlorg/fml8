#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: newml.pm,v 1.1.1.1 2001/08/26 05:43:10 fukachan Exp $
#

package FML::Command::User::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::User::newml - make a new mailing list

=head1 SYNOPSIS

    use FML::Command::User::newml;
    $obj = new FML::Command::User::newml;
    $obj->newml($curproc, $optargs);

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<newml($curproc, $optargs)>

=cut


sub process
{
    my ($self, $curproc, $optargs) = @_;
    my $config        = $curproc->{ config };
    my $main_cf       = $curproc->{ main_cf };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $ml_name       = $optargs->{ ml_name };

    # fundamental check
    croak("\$ml_name is not specified")    unless $ml_name;

    my $ml_home_prefix     = $main_cf->{ ml_home_prefix };
    my $ml_home_dir        = "$ml_home_prefix/$ml_name";

    use File::Utils qw(mkdirhier copy);
    unless (-d $ml_home_dir) {
	mkdirhier( $ml_home_dir, $config->{ default_dir_mode } || 0755 );

	use File::Spec;

	my $default_config_dir = $main_cf->{ default_config_dir };
	my $src = File::Spec->catfile($default_config_dir, "config.cf");
	my $dst = File::Spec->catfile($ml_home_dir, 'config.cf');
	copy($src, $dst);
    }
    else {
	warn("$ml_name already exists");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::newml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
