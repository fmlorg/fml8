#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: summary.pm,v 1.10 2005/08/17 12:08:44 fukachan Exp $
#

package FML::Command::Admin::summary;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::summary - maintain article summary file.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

maintain article summary file.

=head1 METHODS

=head2 process($curproc, $command_context)

maintain article summary file.

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
sub lock_channel { return 'article_spool_modify';}


# Descriptions: top level dispatcher to maintain article summary file.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

    $self->_summary($curproc, $command_context);
}


# Descriptions: fmlsummary top level dispacher.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _summary
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $max_id  = $curproc->article_get_max_id();
    my $options = $command_context->get_options() || [];

    use FML::Article::Summary;
    my $summary = new FML::Article::Summary $curproc;

    my ($method) =  @$options;
    if ($method eq 'update') {
	croak("update not implemented");
    }
    elsif ($method eq 'rebuild') {
	$summary->rebuild(1, $max_id);
    }
    else {
	# XXX-TODO: STDOUT hard coded. ok?
	my $wh = \*STDOUT;
	$summary->dump($wh);
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

FML::Command::Admin::summary first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
