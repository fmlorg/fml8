#-*- perl -*-
#
#  Copyright (C) 2004,2007,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: bogofilter.pm,v 1.5 2007/01/16 11:24:27 fukachan Exp $
#

package FML::Filter::External::bogofilter;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::External::bogofilter - bogofilter interface.

=head1 SYNOPSIS

use FML::Filter::External::bogofilter;
my $ext_filter = new FML::Filter::External::bogofilter;
$ext_filter->process($curproc, $msg);

=head1 DESCRIPTION

This module checks the specified message $msg by bogofilter.

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


=head2 process($curproc, $msg)

top level dispather.
It checks if the current message $msg looks a spam by bogofilter.

=cut


# Descriptions: check if the current message looks a spam.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($msg)
# Side Effects: none
# Return Value: NUM(1 or 0) (1 if spam)
sub process
{
    my ($self, $curproc, $msg) = @_;
    my $config  = $curproc->config();
    my $program = $config->{ path_bogofilter } || '';
    my $opts    = $config->{ article_spam_filter_bogofilter_options } || '';
    if ($program) {
	if (-x $program) {
	    my $_program = sprintf("%s %s", $program, $opts);
	    return $self->_check($curproc, $msg, $_program);
	}
	else {
	    $curproc->logerror("$program not exists");
	}
    }
    else {
	$curproc->logerror("path_bogofilter undefined");
    }

    return 0;
}


# Descriptions: check the message through $program.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($msg) STR($program)
# Side Effects: none
# Return Value: NUM(1 or 0) (1 if spam)
sub _check
{
    my ($self, $curproc, $msg, $program) = @_;
    my $opts = "-e";

    use FileHandle;
    my $wh = new FileHandle "| $program $opts ";
    if (defined $wh) {
	$wh->autoflush(1);
	$msg->print($wh);
	$wh->close();
	if ($?) {
	    my $code = $?;
	    my $r    = "SPAM determined by bogofilter";
	    $curproc->logerror($r);
	    $curproc->filter_state_spam_checker_set_error($r);
	    return 1;
	}
	else {
	    $curproc->log("not SPAM");
	}
    }

    return 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2007,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::External::bogofilter appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
