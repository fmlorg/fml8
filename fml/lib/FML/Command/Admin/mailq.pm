#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mailq.pm,v 1.10 2004/09/03 12:43:55 fukachan Exp $
#

package FML::Command::Admin::mailq;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::mailq - show outgoing mail queue.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

list up outgoing mail queue.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor.
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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: show outgoing mail queue.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    $self->_list_up_queue($curproc);
}


# Descriptions: show outgoing mail queue.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _list_up_queue
{
    my ($self, $curproc) = @_;
    my $config    = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };
    my $count     = 0;
    my $format    = "%-20s   %s\n";

    use Mail::Delivery::Queue;
    my $queue   = new Mail::Delivery::Queue { directory => $queue_dir };
    my $ra_list = $queue->list_all();

    for my $qid (@$ra_list) {
	my $info = $queue->getidinfo($qid);

	my $q = new Mail::Delivery::Queue {
	    id        => $qid,
	    directory => $queue_dir,
	};

	if ($q->is_valid_queue()) {
	    # 1. the first line is "queue-id sender".
	    printf $format, $qid, $info->{sender};
	    
	    # 2. list up recipients after 2nd lines.
	    my $rq = $info->{ recipients };
	    for my $r (@$rq) {
		printf $format, "", $r;
	    }
	    print "\n";

	    $count++;
	}
    }

    if ($count) {
	$curproc->ui_message("-- $count requests.");
    }
    else {
	$curproc->ui_message("Mail queue is empty");
    }
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

FML::Command::Admin::mailq first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
