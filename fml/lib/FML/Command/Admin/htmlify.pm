#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: htmlify.pm,v 1.10 2002/03/31 03:39:13 fukachan Exp $
#

package FML::Command::Admin::htmlify;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::htmlify - convert $spool_dir to html files

=head1 SYNOPSIS

See C<FML::Command>.

=head1 DESCRIPTION

=head1 METHODS

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
sub need_lock { 1;}


# Descriptions: htmlify articles
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $command   = $command_args->{ 'command' };
    my $config    = $curproc->{ 'config' };
    my $src_dir   = $config->{ spool_dir };
    my $options   = $command_args->{ options };
    my $dst_dir   = undef;

    for (@$options) {
	if (/\-\-outdir=(\S+)/) { $dst_dir = $1;}
	if (/\-\-dstdir=(\S+)/) { $dst_dir = $1;}
	if (/\-\-srcdir=(\S+)/) { $src_dir = $1;}
    }

    if (defined $dst_dir) {
	unless (-d $dst_dir) {
	    use File::Utils qw(mkdirhier);
	    mkdirhier($dst_dir, 0755);
	}

	use Mail::Message::ToHTML;
	&Mail::Message::ToHTML::htmlify_dir($src_dir, { 
	    directory => $dst_dir,
	});
    }
    else {
	croak("no destination directory\n");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::htmlify appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
