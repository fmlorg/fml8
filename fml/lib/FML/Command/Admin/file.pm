#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: file.pm,v 1.17 2004/01/01 23:52:12 fukachan Exp $
#

package FML::Command::Admin::file;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::file - functions for file operations.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 process($curproc, $command_args)

dispatch functions for file operations.

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
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: needs "command subcommand parameters" style or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub is_subcommand_style { 1;}


# Descriptions: dispatcher of file subcommand operations.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: file is created, renamed and removed
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config   = $curproc->config();
    my $log_file = $config->{ log_file };
    my $options  = $command_args->{ options } || [];
    my $du_args  = {};
    my @argv     = ();

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;

    # argv = command subcommand args ... = command options
    my ($subcommand, @args)= @$options;

    if ($subcommand eq 'remove' ||
	$subcommand eq 'delete' ||
	$subcommand eq 'unlink') {
	for my $x (@args) {
	    if ($safe->regexp_match('file', $x)) {
		# XXX-TODO: we shoul allow plural ?
		push(@argv, $x);
	    }
	}
	$du_args->{ options } = \@argv;

	use FML::Command::FileUtils;
	my $obj = new FML::Command::FileUtils;
	$obj->remove($curproc, $command_args, $du_args);
    }
    else {
	croak("Admin::file: unknown subcommand");
    }
}


# Descriptions: show cgi menu (dummy).
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;

    # XXX-TODO: dummy.?
    ;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
