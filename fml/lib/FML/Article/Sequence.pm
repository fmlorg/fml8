#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Sequence.pm,v 1.17 2005/06/04 08:51:31 fukachan Exp $
#

package FML::Article::Sequence;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

# XXX_LOCK_CHANNEL: article_sequence
my $lock_channel = 'article_sequence';


=head1 NAME

FML::Article::Sequence - article sequence manipulation.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 increment_id()

increment the sequence number of this article C<$self> and
save it to C<$sequence_file>.

=cut


# Descriptions: determine the next article id (sequence number).
#    Arguments: OBJ($self)
# Side Effects: save and update the current article sequence number.
# Return Value: NUM(sequence identifier) or 0(failed)
sub increment_id
{
    my ($self)   = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $pcb      = $curproc->pcb();
    my $seq_file = $config->{ article_sequence_file };
    my $error    = 0;

    $curproc->lock($lock_channel);

    # XXX-TODO: we should enhance sequence_file to all IO::Adapter classes.
    use IO::Adapter;
    my $io = new IO::Adapter "file:$seq_file";
    my $id = $io->sequence_increment();
    if ($io->error()) {
	my $err = $io->error();
	$curproc->logerror( "article_id: $err" );
	$error = 1;
    }

    $curproc->unlock($lock_channel);

    unless ($error) {
	# XXX-TODO: use $curproc->article_set_id().
	# save $id in pcb (process control block) and return $id
	$pcb->set('article', 'id', $id);

	return $id;
    }
    else {
	return 0;
    }
}


=head2 id()

return the current article sequence number.

=cut

# Descriptions: return the article id (sequence number).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(sequence number)
sub id
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $pcb     = $curproc->pcb();

    # XXX-TODO: use $curproc->article_get_id().
    my $n = $pcb->get('article', 'id');

    # within Process::Distribute
    if ($n) {
	return $n;
    }
    # processes not Process::Distribute
    else {
	my $seq_file = $config->{ article_sequence_file };
	my $map      = sprintf("file:%s", $seq_file);

	return( $self->get_number_from_map($map) || 0 );
    }
}


# Descriptions: get number from map.
#    Arguments: OBJ($self) STR($map)
# Side Effects: none
# Return Value: NUM
sub get_number_from_map
{
    my ($self, $map) = @_;
    my $n = 0;

    use IO::Adapter;
    my $io = new IO::Adapter $map;
    if (defined $io) {
	$io->open();
	$n  = $io->getline() || 0;
	$n =~ s/^\s*//;
	$n =~ s/\s*$//;

	if ($n =~ /^\d+$/o) {
	    return $n;
	}
	else {
	    return 0;
	}
    }
    else {
	warn("cannot open map=$map");
    }

    return 0;
}


#
# XXX-TODO: speculate_max_id([$spool_dir]) NOT USED ?
#


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

    $curproc->logdebug("max_id: scan $spool_dir subdir=$use_subdir");

    if ($use_subdir) {
	use DirHandle;
	my $dh = new DirHandle $spool_dir;

	if (defined $dh) {
	    my $fn         = ''; # file name
	    my $subdir     = '';
	    my $max_subdir = 0;

	  ENTRY:
	    while (defined($fn = $dh->read)) {
		next ENTRY unless $fn =~ /^\d+$/o;

		use File::Spec;
		$subdir = File::Spec->catfile($spool_dir, $fn);

		if (-d $subdir) {
		    my $max_subdir = $max_subdir > $fn ? $max_subdir : $fn;
		}
	    }

	    $dh->close();

	    # XXX-TODO wrong? to speculate max_id in subdir spool?
	    $subdir = File::Spec->catfile($spool_dir, $max_subdir);
	    $curproc->logdebug("max_id: scan $subdir");
	    $curproc->speculate_max_id($subdir);
	}
    }

    use DirHandle;
    my $dh = new DirHandle $spool_dir;
    if (defined $dh) {
	my $max = 0;
	my $fn  = ''; # file name

      ENTRY:
	while (defined($fn = $dh->read)) {
	    next ENTRY unless $fn =~ /^\d+$/o;
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

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article::Sequence appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
