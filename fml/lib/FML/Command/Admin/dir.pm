#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: dir.pm,v 1.5 2002/09/11 23:18:07 fukachan Exp $
#

package FML::Command::Admin::dir;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::dir - show "ls" results

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show "ls" results

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


# Descriptions: show the result by "ls -l"
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

    use FML::Restriction::Base;
    my $safe   = new FML::Restriction::Base;
    my $regexp = $safe->basic_variables();
    my $dirreg = $regexp->{ directory };

    # analyze ...
    for my $x (@$options) {
	# restrict the file name
	if ($x =~ /^($dirreg)$/) {
	    $du_args->{ opt_ls } = $1;
	}
	else {
	    push(@argv, $x);
	}
    }
    $du_args->{ options } = \@argv;

    use FML::Command::DirUtils;
    my $obj = new FML::Command::DirUtils;
    $obj->dir($curproc, $command_args, $du_args);
}


# Descriptions: cgi menu (dummy)
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;

    ;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
