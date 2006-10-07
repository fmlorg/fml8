#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: spool.pm,v 1.10 2006/03/04 13:48:29 fukachan Exp $
#

package FML::Command::Admin::spool;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::spool - small maintenance jobs on the spool directory.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show spool status or convert the structure.

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
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'article_spool_modify';}


# Descriptions: subcommand dispatch table for "spool" command.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $c_opts  = $curproc->command_line_cui_specific_options() || {};
    my $options = $command_context->get_options();
    my $fp      = $options->[ 0 ] || 'status';

    # prepare arguments on $*_dir directory info.
    my $dst_dir = $c_opts->{ dst_dir } || $config->{ spool_dir };
    my $src_dir = $c_opts->{ src_dir } || $config->{ spool_dir };

    # sanity
    croak("\$src_dir unspecified")       unless $src_dir;
    croak("no such directory: $src_dir") unless -d $src_dir;

    # prepare command specific parameters
    $command_context->{ _src_dir } = $src_dir;
    $command_context->{ _dst_dir } = $dst_dir;
    $command_context->{ _output_channel } = \*STDOUT; # suppose only makefml.

    # here we go.
    print STDERR "converting $src_dir -> $dst_dir\n";
    use FML::Article::Spool;
    my $spool = new FML::Article::Spool $curproc;
    if ($spool->can($fp)) {
	$spool->$fp($curproc, $command_context);
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

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
