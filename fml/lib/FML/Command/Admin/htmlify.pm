#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: htmlify.pm,v 1.3 2001/12/22 09:21:03 fukachan Exp $
#

package FML::Command::Admin::htmlify;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::Admin::htmlify - htmlify $spool_dir

=head1 SYNOPSIS

See C<FML::Command>.

=head1 DESCRIPTION

=head2 makefml usage

For example, make HTMLified articles in
/var/www/htdocs/mlarchives/elena

   makefml htmlify elena \
    srcdir=/var/spool/ml/elena/spool \
    outdir=/var/www/htdocs/mlarchives/elena

C<XXX>
This options format is irregular, isn't it?
We should normalized it in the following way?

   makefml htmlify elena \
    --srcdir=/var/spool/ml/elena/spool \
    --outdir=/var/www/htdocs/mlarchives/elena

Hmm, ... but it is strange.

=head1 METHODS

=cut


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
	if (/outdir=(\S+)/) { $dst_dir = $1;}
	if (/srcdir=(\S+)/) { $src_dir = $1;}
    }

    if (defined $dst_dir) {
	unless (-d $dst_dir) {
	    use File::Utils qw(mkdirhier);
	    mkdirhier($dst_dir, 0755);
	}

	use Mail::HTML::Lite;
	&Mail::HTML::Lite::htmlify_dir($src_dir, { directory => $dst_dir });
    }
    else {
	croak("no destination directory\n");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::htmlify appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
