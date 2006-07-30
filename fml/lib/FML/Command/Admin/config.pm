#-*- perl -*-
#
#  Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: config.pm,v 1.3 2006/03/04 13:48:28 fukachan Exp $
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

=head2 new()

constructor.

=head2 need_lock()

need lock or not.

=head2 lock_channel()

return lock channel name.

=head2 verify_syntax($curproc, $command_context)

provide command specific syntax checker.

=head2 process($curproc, $command_context)

main command specific routine.

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


# Descriptions: run "vi" or the specified editor to config config.cf.
#               If environmental variable EDITOR is specified,
#               try to run "$EDITOR config.cf".
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update config.cf
#               change $ENV{ PATH } withiin running configor.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

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

Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::config first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
