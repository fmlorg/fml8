#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: htmlify.pm,v 1.4 2001/10/14 00:44:13 fukachan Exp $
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

=head2 makefml usage

For example, make htmlified articles in /var/www/htdocs/mlarchives/elena

   makefml htmlify elena outdir=/var/www/htdocs/mlarchives/elena

=head1 DESCRIPTION

=head1 METHODS

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $command   = $command_args->{ 'command' };
    my $config    = $curproc->{ 'config' };
    my $spool_dir = $config->{ spool_dir };
    my $options   = $command_args->{ options };
    my $dst_dir   = undef;

    for (@$options) {
	if (/outdir=(\S+)/) { $dst_dir = $1;}
    }

    if (defined $dst_dir) {
	unless (-d $dst_dir) {
	    use File::Utils qw(mkdirhier);
	    mkdirhier($dst_dir, 0755);
	}

	use Mail::HTML::Lite;
	&Mail::HTML::Lite::htmlify_dir($spool_dir, { directory => $dst_dir });
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
