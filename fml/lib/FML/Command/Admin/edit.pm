#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: edit.pm,v 1.12 2002/09/28 14:42:01 fukachan Exp $
#

package FML::Command::Admin::edit;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::edit - edit config.cf (not yet implemented)

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Tool to edit config.cf.

     not implemented

=head1 METHODS

=head2 C<process($curproc, $command_args)>

C<TODO>:
now we can read and write config.cf, not change it.

=cut


# Descriptions: standard constructor
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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: run "vi" or the specified editor to edit config.cf.
#    Arguments: $self $curproc $command_args
# Side Effects: update config.cf
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config      = $curproc->config();
    my $ml_name     = $curproc->ml_name();
    my $ml_home_dir = $curproc->ml_home_dir( $ml_name );

    use File::Spec;
    my $config_cf   = File::Spec->catfile($ml_home_dir, "config.cf");

    # editor
    my $editor = $ENV{ 'EDITOR' } || 'vi';

    if (-f $config_cf) {
	print STDERR "$editor $config_cf\n";
	system $editor, $config_cf;
    }
    else {
	warn("$config_cf not found\n");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::edit first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
