#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: spool.pm,v 1.2 2003/03/16 10:56:00 fukachan Exp $
#

package FML::Command::Admin::spool;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::spool - small maintenance jobs on the spool directory

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show spool status or convert the structure.

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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'article_spool_modify';}


# Descriptions: subcommand dispatch table for "spool" command.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $options = $command_args->{ options };
    my $fp      = $options->[ 0 ] || 'status';

    # XXX-TODO: makefml $ml spool ... what arguments is appropriate ?
    #           use $dst_dir as $src_dir if --srcdir=DIR not specified.
    #           you can specify the spool type by --style=subdir ?
    #           but only "subdir" is supported now :) ?

    # prepare arguments on $*_dir directory info.
    my $dst_dir = $config->{ spool_dir };
    my $src_dir = $dst_dir;
    $command_args->{ _src_dir } = $src_dir;
    $command_args->{ _dst_dir } = $dst_dir;

    # output channel (we suppose only makefml here).
    $command_args->{ _output_channel } = \*STDOUT;

    use FML::Article::Spool;
    my $spool = new FML::Article::Spool $curproc;
    if ($spool->can($fp)) {
	$spool->$fp($curproc, $command_args);
    }
    else {
	croak("no such method: $fp");
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

FML::Command::Admin::spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
