#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: get.pm,v 1.1.1.1 2001/08/26 08:01:04 fukachan Exp $
#

package FML::Command::Admin::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::Admin::get - what is this

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=cut


sub process
{
    my ($self, $curproc, $optargs) = @_;
    my $options   = $optargs->{ 'options' };
    my $config    = $curproc->{ 'config' };
    my $spool_dir = $config->{ 'spool_dir' };
    my @options   = @$options;
    my $recipient = shift @options;
    my @files;

    for my $id (@options) {
	use File::Spec;
	my $f = File::Spec->catfile($spool_dir, $id);
	if (-f $f) {
	    $curproc->reply_message( {
		type        => "message/rfc822",
		path        => $f,
		filename    => $id,
		disposition => "article $id",
	    });
	}
	else {
	    use FML::Log qw(Log);
	    &Log("article $id not found");
	}
    }

    $curproc->queue_in('reply_message', {
	'sender'  => 'fukachan',
	'subject' => 'get result',
	'recipient' => $recipient,
    });
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::Admin::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
