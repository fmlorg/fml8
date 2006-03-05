#-*- perl -*-
#
#  Copyright (C) 2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: moderate.pm,v 1.2 2006/03/04 13:48:29 fukachan Exp $
#

package FML::Command::Admin::moderate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::moderate - moderate submitted articles.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 process($curproc, $command_context)

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


# Descriptions: dummy.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub verify_syntax
{
    my ($self, $curproc, $command_context) = @_;
}


# Descriptions: moderate submmited article.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $options = $command_context->get_options() || [];
    my $address = $command_context->get_data() || $options->[ 0 ];
    my $confirm_id = $command_context->{ _confirm_id } || undef;

    use FML::Confirm;
    my $cache_dir = $config->{ db_dir };
    my $keyword   = $config->{ confirm_command_prefix };
    my $command   = 'moderate';
    my $class     = 'moderate';
    my $confirm = new FML::Confirm $curproc, {
            keyword   => $keyword,
            cache_dir => $cache_dir,
            class     => $class,
            address   => $address,
            buffer    => $command,
        };
    my $queue_id = $confirm->get($confirm_id, "queue_id");
    $curproc->log("moderation confirmed: qid=$queue_id");

    use FML::Moderate;
    my $moderation = new FML::Moderate $curproc;
    $curproc->log("distribute article qid=$queue_id");
    $moderation->distribute_article($queue_id);
}


# Descriptions: dummy.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::moderate first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
