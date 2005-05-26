#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: clamscan.pm,v 1.4 2004/07/23 15:59:06 fukachan Exp $
#

package FML::Filter::External::clamscan;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::External::clamscan - clamav interface.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

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


# Descriptions: check if the current message looks a virus.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0) (1 if spam)
sub process
{
    my ($self, $curproc) = @_;
    my $config  = $curproc->config();
    my $program = $config->{ path_clamscan } || '';
    my $_opts   = "--quiet --mbox";
    my $opts    = $config->{ article_virus_filter_clamav_options } || $_opts;

    if ($program) {
	if (-x $program) {
	    my $_program = sprintf("%s %s", $program, $opts);
	    return $self->_check($curproc, $_program);
	}
	else {
	    $curproc->logerror("$program not exists");
	}
    }
    else {
	$curproc->logerror("path_clamscan undefined");
    }

    return 0;
}


# Descriptions: check the message through $program.
#    Arguments: OBJ($self) OBJ($curproc) STR($program)
# Side Effects: none
# Return Value: NUM(1 or 0) (1 if virus)
sub _check
{
    my ($self, $curproc, $program) = @_;

    use FileHandle;
    my $tmp_file = $curproc->temp_file_path();
    my $wh       = new FileHandle "> $tmp_file";
    if (defined $wh) {
	$wh->autoflush(1);
	my $msg = $curproc->incoming_message();
	$msg->print($wh);
	$wh->close();

	# XXX-TODO: correct ?
	unless (-f $tmp_file) {
	    return 0;
	}

	my $status = 0;
	system "$program $tmp_file";
	if ($status = $?) {
	    if ($status == 1) {
		my $r = "virus found by clamav";
		$curproc->logerror($r);
		$curproc->filter_state_virus_checker_set_error($r);
	    }
	    else {
		$curproc->logerror("bogofilter error: code=$?");
		return 0;
	    }

	    return 1;
	}
    }

    return 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::External::clamscan appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
