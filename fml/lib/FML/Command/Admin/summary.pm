#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: summary.pm,v 1.1 2003/03/14 03:44:16 fukachan Exp $
#

package FML::Command::Admin::summary;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::summary - show outgoing mail queue.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change delivery mode from real time to digest.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

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


# Descriptions: change delivery mode from real time to digest.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->_summary($curproc, $command_args);
}


# Descriptions: fmlsummary top level dispacher
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _summary
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $argv    = $curproc->command_line_argv();
    my $id_max  = $curproc->article_id_max();
    my $options = $command_args->{ options };

    use FML::Article::Summary;
    my $summary = new FML::Article::Summary $curproc;

    my ($method) =  @$options;

    if ($method eq 'update') {
	croak("update not implemented");
    }
    elsif ($method eq 'rebuild') {
	$summary->rebuild(1, $id_max);
    }
    else {
	my $wh = \*STDOUT;
	$summary->dump($wh);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::summary first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
