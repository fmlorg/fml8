#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: config.pm,v 1.1 2004/11/21 05:36:11 fukachan Exp $
#

package FML::Command::Admin::config;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::Command::Admin::config - config config.cf.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Tool to config config.cf.

     NOT IMPLEMENTED.

=head1 METHODS

=head2 process($curproc, $command_args)

C<TODO>:
now we can read and write config.cf, but can not change it.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: run "vi" or the specified configor to config config.cf.
#               If environmental variable EDITOR is specified,
#               try to run "$EDITOR config.cf".
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update config.cf
#               change $ENV{ PATH } withiin running configor.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    use FML::Config::Menu;
    my $menu = new FML::Config::Menu $curproc;
    $menu->run_cui();
    $menu->rewrite_config_cf();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::config first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
