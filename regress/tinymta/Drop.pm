#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Drop.pm,v 1.2 2006/06/12 22:53:06 fukachan Exp $
#

package TinyMTA::Drop;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $global_counter);
use Carp;

=head1 NAME

TinyMTA::Drop - mail drop wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($config)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $config) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _config => $config };
    return bless $me, $type;
}


# Descriptions: main routine.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub run
{
    my ($self) = @_;
    my $config = $self->{ _config };

    # 1. prepare queue directory. 
    my $queue_dir = $config->{ queue_dir };
    unless (-d $queue_dir) {
	mkdir $queue_dir, 0730;
	if (-d $queue_dir) {
	    $self->log("$queue_dir created");
	}
	else {
	    $self->logerror("cannot mkdir $queue_dir");
	}
    }

    # 2. drop the message taken from STDIN into a new queue file.
    my ($qid, $qf, $qtmp) = $self->queue_filename();
    my $wh = new FileHandle "> $qtmp";
    if (defined $wh) {
	my $buf;

	$wh->autoflush(1);
      LINE:
	while (sysread(STDIN, $buf, 8192)) {
	    syswrite($wh, $buf, 8192);
	}
	$wh->close();
    }

    if (-s $qtmp) {
	if (rename($qtmp, $qf)) {
	    $self->log("queue-in: $qid");
	}
	else {
	    $self->logerror("cannot create $qf");
	    croak("cannot create $qf\n");
	}
    }
    else {
	$self->logerror("0 byte tmp file: $qtmp");
    }
}


# Descriptions: retrun a new queue file name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY(STR, STR, STR)
sub queue_filename
{
    my ($self)    = @_;
    my $config    = $self->{ _config };
    my $queue_dir = $config->{ queue_dir };

    use FileHandle;
    my $qid = sprintf("%d.%d.%d", time, $$, ++$global_counter);
    my $new = File::Spec->catfile($queue_dir, $qid);
    my $tmp = File::Spec->catfile($queue_dir, ",$qid");

    return($qid, $new, $tmp);
}


# Descriptions: log as normal level.
#    Arguments: OBJ($self) STR($msg)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $msg) = @_;
    &TinyMTA::Log::log($msg);
}


# Descriptions: log as error level.
#    Arguments: OBJ($self) STR($msg)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($self, $msg) = @_;
    &TinyMTA::Log::log("error: $msg");
}


######################################################################
#
# dispatcher
#

# Descriptions: main dispatcher.
#    Arguments: OBJ($main_cf) STR($config_cf_file)
# Side Effects: none
# Return Value: none
sub main::dispatch
{
    my ($main_cf, $config_cf_file) = @_;

    my $config = TinyMTA::Config::load_file($config_cf_file, $main_cf);
    my $obj    = new TinyMTA::Drop $config;
    $obj->run();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

TinyMTA::Drop appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
