#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HTMLify.pm,v 1.28 2005/08/17 12:08:45 fukachan Exp $
#


package FML::Command::HTMLify;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

my $debug = 0;


=head1 NAME

FML::Command::HTMLify - utility functions to convert text to html.

=head1 SYNOPSIS

use FML::Command::HTMLify;
&FML::Command::HTMLify::convert($curproc, {
    src_dir => $src_dir,
    dst_dir => $dst_dir,
});

=head1 DESCRIPTION

This module provides several utility functions to convert text file to
html format one.

=head1 METHODS

=head2 convert($optargs)

convert articles from text to html style.

=cut


# Descriptions: convert text to html style.
#    Arguments: OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($curproc, $optargs) = @_;
    my $src_dir = $optargs->{ src_dir };
    my $dst_dir = $optargs->{ dst_dir };

    # ASSERT
    croak("src_dir not defined") unless defined $src_dir;
    croak("src_dir not exists")  unless -d $src_dir;
    croak("dst_dir not defined") unless defined $dst_dir;
    croak("dst_dir not exists")  unless -d $dst_dir;

    # debug
    print STDERR "  convert\n\t$src_dir =>\n\t$dst_dir\n" if $debug;

    # XXX-TODO: $curproc->article_thread_init() returns HTML config CLASS ?
    # fix parameters: output_dir = ~fml/public_html/mlarchive/$domain/$ml/
    my $htmlifier_args = $curproc->article_thread_init();
    $htmlifier_args->{ output_dir } = $dst_dir;

    my ($is_subdir_exists, $subdirs) = _check_subdir_exists($src_dir);
    if ($is_subdir_exists) { $curproc->logdebug("looks subdir exists");}

    if (defined $dst_dir) {
        unless (-d $dst_dir) {
            $curproc->mkdir($dst_dir, "mode=public");
        }

	if ($is_subdir_exists) {
	    my (@subdir_list) = sort _sort_subdirs @$subdirs;
	    print STDERR "   subdirs: @subdir_list\n" if $debug;
	    for my $subdir (@subdir_list) {
		# XXX-TODO: hmm, naming ? $obj->htmlify_dir(...).
		eval q{
		    use Mail::Message::ToHTML;
		    my $obj = new Mail::Message::ToHTML $htmlifier_args;
		    $obj->htmlify_dir($subdir, $htmlifier_args);
		};
		croak($@) if $@;
	    }
	}
	else {
	    print STDERR "   hmm, looks not subdir style.\n" if $debug;
	    eval q{
		use Mail::Message::ToHTML;
		my $obj = new Mail::Message::ToHTML $htmlifier_args;
		$obj->htmlify_dir($src_dir, $htmlifier_args);
	    };
	    croak($@) if $@;
	}
    }
    else {
        croak("no destination directory\n");
    }
}


# Descriptions: sort subdirs by the last dirname.
#    Arguments: implicit ($a, $b)
# Side Effects: none
# Return Value: NUM(-1, 0, 1)
sub _sort_subdirs
{
    my ($xa, $xb);

    if ($a =~ /(\d+)$/o) { $xa = $1;}
    if ($b =~ /(\d+)$/o) { $xb = $1;}

    $xa <=> $xb;
}

# Descriptions: check whether $src_dir has sub-directories in it.
#    Arguments: STR($src_dir)
# Side Effects: none
# Return Value: ARRAY( STR, ARRAY_REF )
sub _check_subdir_exists
{
    my ($src_dir) = @_;
    my $status    = 0;
    my $subdir    = '';
    my @subdir    = ();

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	my $e;

      ENTRY:
	while (defined($e = $dh->read)) {
	    next ENTRY if $e =~ /^\./o;

	    $subdir = File::Spec->catfile($src_dir, $e);
	    if (-d $subdir) {
		push(@subdir, $subdir);
		$status = 1;
	    }
	}
    }

    return( $status, \@subdir );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::HTMLify first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
