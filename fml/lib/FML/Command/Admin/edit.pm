#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: edit.pm,v 1.2 2001/09/22 13:17:11 fukachan Exp $
#

package FML::Command::Admin::edit;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::Admin::edit - edit a new member

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head1 METHODS

=head2 C<process($curproc, $command_args)>

C<TODO>:
now we can read and write config.cf, not change it.

=cut


# Descriptions: edit config.cf
#    Arguments: $self $curproc $command_args 
# Side Effects: update config.cf
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $options       = $command_args->{ options };
    my $address       = $command_args->{ address } || $options->[ 0 ];
    my $myname        = $command_args->{ args }->{ myname };

    # ML's home directory
    use File::Spec;
    my $ml_home_dir   = $command_args->{ 'args' }->{ 'ml_home_dir' };
    my $config_cf     = File::Spec->catfile($ml_home_dir, "config.cf");

    use FML::Config;
    my $c = new FML::Config;

    # read configuration. configuration is holded in FML:Config space.
    $c->read( $config_cf );

    # modify $c (config) object
    # XXX TODO
    # XXX ... snip ... 
    # $c->set('key', 'value');  # set up
    # $c->regist('key');        # add list to write into config.cf

    # ovewrite $config_cf
    # after old $config_cf is backup'ed to $config_cf.bak
    $c->write( $config_cf );
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::Admin::edit appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
