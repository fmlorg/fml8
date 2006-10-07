#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: dir.pm,v 1.22 2006/03/04 13:48:28 fukachan Exp $
#

package FML::Command::Admin::dir;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::dir - show "ls -l" results.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show "ls -l" results.

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


# Descriptions: show the result by "ls -l".
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map and $recipient_map.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config    = $curproc->config();
    my $options   = $command_context->get_options() || [];
    my $du_args   = {};
    my @argv      = ();
    my $recipient = '';

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;

    # XXX-TODO analyze arguments. ???
    for my $x (@$options) {
	# XXX-TODO: correct? we restrict the "ls" option pattern here.
	if ($safe->regexp_match('directory', $x)) {
	    # XXX-TODO: we should allow plural directories as options ?
	    $du_args->{ opt_ls } = $x;
	}
	else {
	    push(@argv, $x);
	}
    }

    if ($curproc->is_cui_process()) {
	# --send-to option.
	$recipient = $curproc->command_line_cui_specific_recipient() || '';
	$command_context->{ _recipient } = $recipient;
    }

    if (@argv) {
	my $buf = join(" ", @argv);
	my $rm_args = { _arg_argv => $buf };
	$curproc->reply_message_nl("error.ignore",
				   "\"buf\" ignored.",
				   $rm_args);
    }

    # XXX-TODO: $dir = new FML::Command::DirUtils $dir_string; $dir->list(). ?
    use FML::Command::DirUtils;
    my $obj = new FML::Command::DirUtils;
    $obj->dir($curproc, $command_context, $du_args);
}


# Descriptions: cgi menu (dummy).
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;

    ;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
