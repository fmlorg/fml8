#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Sequence.pm,v 1.3 2003/08/23 04:35:28 fukachan Exp $
#

package FML::Article::Sequence;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

# XXX_LOCK_CHANNEL: article_sequence
my $lock_channel = 'article_sequence';


=head1 NAME

FML::Article::Sequence - article sequence manipulation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 increment_id()

increment the sequence number of this article C<$self> and
save it to C<$sequence_file>.

This routine uses C<File::Sequence> module.

=cut


# Descriptions: determine article id (sequence number)
#    Arguments: OBJ($self)
# Side Effects: save and update the current article sequence number
# Return Value: NUM(sequence identifier)
sub increment_id
{
    my ($self) = @_;
    my $curproc  = $self->{ curproc };
    my $config   = $curproc->config();
    my $pcb      = $curproc->pcb();
    my $seq_file = $config->{ sequence_file };

    $curproc->lock($lock_channel);

    # XXX-TODO we should enhance IO::Adapter module to handle
    # XXX-TODO sequential number.
    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    if ($sfh->error) { LogError( $sfh->error ); }

    # save $id in pcb (process control block) and return $id
    $pcb->set('article', 'id', $id);

    $curproc->unlock($lock_channel);

    return $id;
}


=head2 id()

return the current article sequence number.

=cut

# Descriptions: return the article id (sequence number)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(sequence number)
sub id
{
    my ($self) = @_;
    my $curproc  = $self->{ curproc };
    my $config   = $curproc->config();
    my $pcb      = $curproc->pcb();

    my $n = $pcb->get('article', 'id');

    # within Process::Distribute
    if ($n) {
	return $n;
    }
    # processes not Process::Distribute
    else {
	my $seq_file = $config->{ sequence_file };
	my $n        = 0;

	use File::Sequence;
	my $sfh = new File::Sequence { sequence_file => $seq_file };
	if (defined $sfh) {
	    $n = $sfh->get_id() || 0;
	}

	return $n;
    }
}


=head2 speculate_max_id([$spool_dir])

scan the spool_dir and get the max number among files in it. It must
be the max (latest) article number in its folder.

=cut


# Descriptions: scan the spool_dir and get max number among files in it.
#               It must be the max (latest) article number in its folder.
#    Arguments: OBJ($curproc) STR($spool_dir)
# Side Effects: none
# Return Value: NUM(sequence number) or undef
sub speculate_max_id
{
    my ($curproc, $spool_dir) = @_;
    my $config     = $curproc->config();
    my $use_subdir = $config->{ spool_type } eq 'subdir' ? 1 : 0;

    unless (defined $spool_dir) {
	$spool_dir = $config->{ spool_dir };
    }

    $curproc->log("max_id: (debug) scan $spool_dir subdir=$use_subdir");

    if ($use_subdir) {
	use DirHandle;
	my $dh = new DirHandle $spool_dir;

	if (defined $dh) {
	    my $fn         = ''; # file name
	    my $subdir     = '';
	    my $max_subdir = 0;

	  ENTRY:
	    while (defined($fn = $dh->read)) {
		next ENTRY unless $fn =~ /^\d+$/;

		use File::Spec;
		$subdir = File::Spec->catfile($spool_dir, $fn);

		if (-d $subdir) {
		    my $max_subdir = $max_subdir > $fn ? $max_subdir : $fn;
		}
	    }

	    $dh->close();

	    # XXX-TODO wrong? to speculate max_id in subdir spool?
	    $subdir = File::Spec->catfile($spool_dir, $max_subdir);
	    $curproc->log("max_id: (debug) scan $subdir");
	    $curproc->speculate_max_id($subdir);
	}
    }

    use DirHandle;
    my $dh = new DirHandle $spool_dir;
    if (defined $dh) {
	my $max = 0;
	my $fn  = ''; # file name

	while (defined($fn = $dh->read)) {
	    next unless $fn =~ /^\d+$/;
	    $max = $max < $fn ? $fn : $max;
	}

	$dh->close();

	return( $max > 0 ? $max : undef );
    }

    return undef;
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

FML::Article::Sequence appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
