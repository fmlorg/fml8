#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delete.pm,v 1.1 2002/03/24 11:26:46 fukachan Exp $
#

package FML::Command::Admin::delete;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::delete - delete file operations

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

delete a new address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

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
sub need_lock { 0;}


# Descriptions: delete a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config   = $curproc->{ config };
    my $log_file = $config->{ log_file };
    my $options  = $command_args->{ options };
    my $du_args  = {};
    my @argv     = ();

    # analyze ...
    for my $x (@$options) {
	if ($x =~ /^([A-Za-z0-9]+)$/) {
	    push(@argv, $x);
	}
    }
    $du_args->{ options } = \@argv;

    use FML::Command::FileUtils;
    my $obj = new FML::Command::FileUtils;
    $obj->delete($curproc, $command_args, $du_args);
}


# Descriptions: log a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;

    ;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
