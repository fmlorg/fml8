#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: newml.pm,v 1.6 2001/05/27 14:27:54 fukachan Exp $
#

package FML::Command::newml;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::newml - make a new mailing list

=head1 SYNOPSIS

    use FML::Command::newml;
    $obj = new FML::Command::newml;
    $obj->newml($curproc, $optargs);

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<newml($curproc, $optargs)>

=cut


sub newml
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

	my $default_config_dir = $main_cf->{ default_config_dir };
	my $src = $default_config_dir ."/config.cf";
	my $dst = $ml_home_dir . "/" . 'config.cf';
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

FML::Command::newml appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
