#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.8 2004/01/01 07:29:27 fukachan Exp $
#

package FML::Filter::External::spamc;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::External::spamc - SpamAssassin interface.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

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


# Descriptions: check if the current message looks a spam.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($msg)
# Side Effects: none
# Return Value: NUM(1 or 0) (1 if spam)
sub process
{
    my ($self, $curproc, $msg) = @_;
    my $config  = $curproc->config();
    my $program = $config->{ path_spamc } || '';
    my $opts    = $config->{ article_spam_filter_spamc_options } || '';
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
	$curproc->logerror("path_spamc undefined");
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

    use FileHandle;
    my $wh = new FileHandle "| $program";
    if (defined $wh) {
	$wh->autoflush(1);
	$msg->print($wh);
	$wh->close();
	if ($?) {
	    $curproc->logerror("determined as SPAM (exit code = $?)");
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

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::External::spamc appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
