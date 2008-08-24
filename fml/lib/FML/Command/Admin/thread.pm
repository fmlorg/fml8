#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: thread.pm,v 1.13 2006/10/07 13:05:17 fukachan Exp $
#

package FML::Command::Admin::thread;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::thread - show article thread or update its status.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show status article thread or manipulate it.

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


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'article_thread';}


# Descriptions: thread manipulation interface.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

    # attach thread library.
    use Mail::Message::Thread;
    my $thargs = $curproc->article_thread_init();
    my $thread = new Mail::Message::Thread $thargs;

    $self->_dispatch($curproc, $command_context, $thread);
}


# Descriptions: dispatch thread sub-command.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) OBJ($thread)
# Side Effects: update $recipient_map
# Return Value: none
sub _dispatch
{
    my ($self, $curproc, $command_context, $thread) = @_;
    my $config        = $curproc->config();
    my $options       = $command_context->get_options() || [];
    my $command       = $options->[ 0 ] || 'one_line_summary';
    my $range         = $options->[ 1 ] || '';
    my $default_range = 'last:10';
    my $max_id        = $curproc->article_get_max_id();
    my $th_args       = {
	last_id => $max_id,
    };

    use FML::Article::Thread;
    my $article_thread = new FML::Article::Thread $curproc;
    if ($command eq 'one_line_summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_summary($th_args);
    }
    elsif ($command eq 'outline') {
	print $article_thread->get_outline($range, $th_args);
    }
    elsif ($command eq 'list') {
	$th_args->{ range } = $range || '';
	$article_thread->print_list($th_args);
	$article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'open' || $command eq 'reopen') {
	$th_args->{ range } = $range || '';
	$article_thread->open_thread_status($th_args);
    }
    elsif ($command eq 'close') {
	$th_args->{ range } = $range || '';
	$article_thread->close_thread_status($th_args);
    }
    else {
	my $r = "unknown subcommand: thread $command";
	$curproc->logerror($r);
	$curproc->ui_message("error: $r");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
