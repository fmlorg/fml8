#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Isolate.pm,v 1.1 2008/08/24 08:18:33 fukachan Exp $
#

package FML::Isolate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $count_ok);
use Carp;

=head1 NAME

FML::Isolate - manipulate isolated invalid(spam) mails.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none.
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 rearrange()

rearrange isolated mails to a date based sub directory under
$isolated_queue_dir.

=cut


# Descriptions: rearrange isolated mails to a date based sub directory
#               under $isolated_queue_dir.
#    Arguments: OBJ($self)
# Side Effects: queue rearrnged.
# Return Value: none
sub rearrange
{
    my ($self)    = @_;
    my ($curproc) = $self->{ _curproc };
    my ($config)  = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };

    # 1. open the isolated queue.
    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue {
	directory => $queue_dir,
    };

    # 2. list up isolated queue messages.
    my $q_class = "isolated";
    my $src_dir = $queue->local_dir_path($q_class);
    my $qlist   = $queue->list($q_class);
    for my $qid (@$qlist) {
	my $mtime   = $queue->last_modified_time($qid);
	my $dst_dir = $self->_rearranged_dir_name($mtime);
	my $dst_key = $self->_rearranged_dir_key($mtime);
	$self->_move_queue_file($qid, $src_dir, $dst_dir, $dst_key);
    }

    # 3. log.
    for my $name (keys %$count_ok) {
	my $c = $count_ok->{ $name };
	$curproc->logdebug("isolate: $c messages moved to $name");
    }
}


# Descriptions: return ARRAY_REF(YEAR, MON, DAY) on mtime.
#    Arguments: OBJ($self) NUM($mtime)
# Side Effects: none
# Return Value: ARRAY_REF(NUM, NUM, NUM)
sub _get_mtime_info
{
    my ($self, $mtime) = @_;

    # get YYYY/MM/DD information from $mtime.
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($mtime);
    my $r_year = sprintf("%04d", 1900 + $year);
    my $r_mon  = sprintf("%02d", $mon + 1);
    my $r_day  = sprintf("%02d", $mday);

    # determine the directory path "$isolated_queue_dir/YYYY/MM/DD".
    my (@data) = ($r_year, $r_mon, $r_day);
    return \@data;
}


# Descriptions: return full-path dir name based on mtime.
#    Arguments: OBJ($self) NUM($mtime)
# Side Effects: none
# Return Value: STR
sub _rearranged_dir_name
{
    my ($self, $mtime) = @_;
    my ($curproc) = $self->{ _curproc };
    my ($config)  = $curproc->config();
    my $queue_dir = $config->{ isolated_queue_dir };

    my ($mdata) = $self->_get_mtime_info($mtime);
    my ($year, $mon, $day) = @$mdata;

    # determine the directory path "$isolated_queue_dir/YYYY/MM/DD".
    use File::Spec;
    my $dir = File::Spec->catfile($queue_dir, $year, $mon, $day);
    return $dir;
}


# Descriptions: return YYYY/MM/DD based on mtime.
#    Arguments: OBJ($self) NUM($mtime)
# Side Effects: none
# Return Value: STR
sub _rearranged_dir_key
{
    my ($self, $mtime) = @_;

    my ($mdata) = $self->_get_mtime_info($mtime);
    my ($year, $mon, $day) = @$mdata;
    return sprintf("%04d/%02d/%02d", $year, $mon, $day);
}


# Descriptions: $qid is moved from $src_dir to $dst_dir.
#    Arguments: OBJ($self) STR($qid) STR($src_dir) STR($dst_dir) STR($dst_key)
# Side Effects: $dst_dir created if not exists.
#               $qid is moved from $src_dir to $dst_dir.
# Return Value: none
sub _move_queue_file
{
    my ($self, $qid, $src_dir, $dst_dir, $dst_key) = @_;
    my ($curproc) = $self->{ _curproc };

    unless (-d $dst_dir) {
	$curproc->mkdir($dst_dir);
    }

    use File::Spec;
    my $src_q = File::Spec->catfile($src_dir, $qid);
    my $dst_q = File::Spec->catfile($dst_dir, $qid);

    # ASSERT
    unless (-f $src_q) {
	$curproc->logerror("isolate: no such queue: $qid");
	return undef;	
    }
    if (-f $dst_q) {
	$curproc->logerror("isolate: already exists: $qid");
	return undef;	
    }

    # ok. go move !
    if (-f $src_q && (! -f $dst_q)) {
	if (rename($src_q, $dst_q)) {
	    $count_ok->{ $dst_key }++;
	}
	else {
	    $curproc->logerror("isolate: cannot move queue: $qid");
	}
    }
    else {
	$curproc->logerror("isolate: invalid condition: $qid");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Isolate appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
