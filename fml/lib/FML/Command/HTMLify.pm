#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HTMLify.pm,v 1.23 2004/04/23 04:10:30 fukachan Exp $
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

=head1 DESCRIPTION

This module provides several utility functions to convert text file to
html format.

=head1 METHODS

=cut


# Descriptions: convert text to html style.
#    Arguments: OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($curproc, $optargs) = @_;
    my $config  = $curproc->config();
    my $ml_name = $config->{ ml_name };
    my $udb_dir = $config->{ udb_base_dir };
    my $src_dir = $optargs->{ src_dir };
    my $dst_dir = $optargs->{ dst_dir };
    my $charset = $curproc->language_of_html_file();

    croak("src_dir not defined") unless defined $src_dir;
    croak("src_dir not exists")  unless -d $src_dir;
    croak("dst_dir not defined") unless defined $dst_dir;
    croak("dst_dir not exists")  unless -d $dst_dir;

    # XXX-TODO: NOT NEED THIS CHECK ? No, it it soon that
    # XXX-TODO: we can convert MH folder to HTML format files.
    #     unless ($curproc->is_config_cf_exist()) {
    #		croak("invalid ML");
    #    }

    print STDERR "  convert\n\t$src_dir =>\n\t$dst_dir\n" if $debug;

    unless (-d $udb_dir) { $curproc->mkdir($udb_dir);}

    my $index_order    = $config->{ html_archive_index_order_type };
    my $htmlifier_args = {
	charset        => $charset,

	output_dir     => $dst_dir,  # ~fml/public_html/mlarchive/$domain/$ml/
	db_base_dir    => $udb_dir,  # /var/spool/ml/@udb@
	db_name        => $ml_name,  # elena

	index_order    => $index_order, # normal/reverse
    };

    my ($is_subdir_exists, $subdirs) = _check_subdir_exists($src_dir);
    if ($is_subdir_exists) { $curproc->log("looks subdir exists");}

    if (defined $dst_dir) {
        unless (-d $dst_dir) {
            $curproc->mkdir($dst_dir, "mode=public");
        }

	if ($is_subdir_exists) {
	    my (@x) = sort _sort_subdirs @$subdirs;
	    print STDERR "   subdirs: @x\n" if $debug;
	    for my $xdir (@x) {
		# XXX-TODO: hmm, naming ? $obj->htmlify_dir(...).
		eval q{
		    use Mail::Message::ToHTML;
		    my $obj = new Mail::Message::ToHTML $htmlifier_args;
		    $obj->htmlify_dir($xdir, $htmlifier_args);
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

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::HTMLify first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
