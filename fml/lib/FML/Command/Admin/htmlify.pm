#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: htmlify.pm,v 1.16 2002/04/25 04:07:32 fukachan Exp $
#

package FML::Command::Admin::htmlify;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::htmlify - convert text articles to html style

=head1 SYNOPSIS

See C<FML::Command> for more detaihtmlify.

=head1 DESCRIPTION

show user htmlify(s).

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


# Descriptions: show the user htmlify
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to dir module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $args    = $command_args->{ args };
    my $config  = $curproc->{ config };
    my $src_dir = $config->{ spool_dir };
    my $dst_dir = $config->{ html_archive_dir };
    my $debug   = 0;

    unless ($config->yes('use_html_archive')) {
	croak("html archive disabled");
    }

    print STDERR "htmlify\t$src_dir =>\n\t\t$dst_dir\n" if $debug;

    # main converter
    use FML::Command::HTMLify;
    &FML::Command::HTMLify::convert($curproc, $args, {
	src_dir => $src_dir,
	dst_dir => $dst_dir,
    });
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::htmlify appeared in fml5 mailing htmlify driver package.
See C<http://www.fml.org/> for more detaihtmlify.

=cut


1;
