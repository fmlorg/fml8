#-*- perl -*-
#
# Copyright (C) 2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Spool.pm,v 1.6 2004/02/01 15:54:45 fukachan Exp $
#

package FML::Article::Spool;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

my $debug = 0;


=head1 NAME

FML::Article::Spool -- utilities to maintain the spool directory

=head1 SYNOPSIS

=head1 DESCRIPTION

This class provides utilitiy functions to maintain the spool directory.

=head1 METHODS

=head2 new($curproc)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;

    # we use methods provided by article object.
    use FML::Article;
    my $article = new FML::Article $curproc;
    my $me      = {
	_curproc => $curproc,
	_article => $article,
    };

    return bless $me, $type;
}


# Descriptions: return lock channel name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_lock_channel_name
{
    my ($self) = @_;
    my $obj = $self->{ _article };

    # inherit lock channel name from FML::Article;
    return $obj->get_lock_channel_name();
}


# Descriptions: convert files from src_dir/ to dst_dir/
#    Arguments: OBJ($self) OBJ($curproc) HASH_RER($command_args)
# Side Effects: none
# Return Value: none
sub convert
{
    my ($self, $curproc, $command_args) = @_;
    my $wh       = $command_args->{ _output_channel } || \*STDOUT;
    my $article  = $self->{ _article };
    my $src_dir  = $command_args->{ _src_dir } || '';
    my $dst_dir  = $command_args->{ _dst_dir } || '';
    my $ml_name  = $command_args->{ ml_name };
    my $channel  = $self->get_lock_channel_name();
    my $use_link = 0;

    $curproc->lock($channel);

    print $wh "convert $ml_name ML spool.\n\n";

    # sanity
    unless ($src_dir) { croak("\$src_dir not defined.");}
    unless ($dst_dir) { croak("\$dst_dir not defined.");}
    unless ($src_dir && -d $src_dir) { croak("\$src_dir not found.");}
    unless ($dst_dir && -d $dst_dir) { croak("\$dst_dir not found.");}
    if ($src_dir eq $dst_dir) {
	$src_dir .= ".old";
	rename($dst_dir, $src_dir);
	$curproc->mkdir($dst_dir, "mode=private");
	$use_link = 1;
    }

    print $wh "converting $dst_dir from $src_dir\n";

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $src_dir;
    if (defined $dh) {
	my $source = '';
	my $dir;

      ENTRY:
	while (defined($dir = $dh->read)) {
	    next ENTRY if $dir =~ /^\./o;

	    $source = File::Spec->catfile($src_dir, $dir);

	    if (-d $source) {
		print $wh "   $source is a subdir.\n";
	    }
	    elsif (-f $source) {
		my $subdirpath = $article->subdirpath($dir);
		my $filepath   = $article->filepath($dir);

		next ENTRY if -f $filepath;

		# may conflict $subdirpath (directory) name with
		# $source file name. e.g. spool/1 (file) vs spool/1 (subdir)
		if (-f $subdirpath) {
		    croak("$subdirpath file/dir conflict");
		}
		else {
		    unless (-d $subdirpath) {
			$curproc->mkdir($subdirpath, "mode=private");
		    }

		    if (-d $subdirpath) {
			if ($use_link) {
			    link($source, $filepath);
			}
			else {
			    use File::Utils qw(copy);
			    copy($source, $filepath);
			}
		    }
		    else {
			croak("cannot mkdir $filepath\n");
		    }
		}

		if (-f $filepath) {
		    print $wh "   $source -> $filepath\n";
		}
		else {
		    print $wh "   Error: fail to move $source -> $filepath\n";
		}
	    }
	}
    }

    print $wh "done.\n\n";

    $curproc->unlock($channel);
}


# Descriptions: show information on spool and articles.
#    Arguments: OBJ($self) OBJ($curproc) HASH_RER($command_args)
# Side Effects: none
# Return Value: none
sub status
{
    my ($self, $curproc, $command_args) = @_;
    my $wh      = $command_args->{ _output_channel } || \*STDOUT;
    my $dst_dir = $command_args->{ _dst_dir };
    my $suffix  = '';

    my ($num_file, $num_dir) = $self->_scan_dir( $dst_dir );

    print $wh "spool directory = $dst_dir\n";

    $suffix = $num_file > 1 ? 's' : '';
    printf $wh "%20d %s\n", $num_file, "file$suffix";

    $suffix = $num_dir > 1 ? 's' : '';
    printf $wh "%20d %s\n", $num_dir, "subdir$suffix";
}


# Descriptions: return directory information.
#    Arguments: OBJ($self) STR($dir)
# Side Effects: none
# Return Value: ARRAY(NUM, NUM)
sub _scan_dir
{
    my ($self, $dir) = @_;
    my $num_dir  = 0;
    my $num_file = 0;

    use File::Spec;
    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my ($file, $entry);

      ENTRY:
	while (defined($entry = $dh->read)) {
	    next ENTRY if $entry =~ /^\./o;

	    $file = File::Spec->catfile($dir, $entry);
	    if (-f $file) {
		$num_file++;
	    }
	    elsif (-d $file) {
		$num_dir++;
		my ($x_num_file, $x_num_dir) = $self->_scan_dir( $file );
		$num_file += $x_num_file;
		$num_dir  += $x_num_dir;
	    }
	}
    }

    return ($num_file, $num_dir);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Core functions of FML::Process::Spool is moved to FML::Article::Spool at
2003/03.

FML::Article::Spool first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
