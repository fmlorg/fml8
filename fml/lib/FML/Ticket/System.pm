#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Ticket::System;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Base::Errors qw(error_reason error error_reset);

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub increment_id
{
    my ($self, $seq_file) = @_;

    use FML::SequenceFile;
    my $sfh = new FML::SequenceFile { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    $self->error_reason( $sfh->error );

    $id;
}


sub update_ticket_trace_cache
{
    my ($self, $curproc) = @_;
    my $config    = $curproc->{ config };
    my $db_dir    = $config->{ ticket_db_dir };
    my $ml_name   = $config->{ ml_name };
    my $cachefile = $db_dir. $ml_name;
    my $umask     = $config->{ default_umask } || 0022;

    printf "%o\n", (0777 & $umask);

    unless (-d $db_dir) {
	use Base::File qw(mkdirhier);
	mkdirhier($db_dir, 0755);
	$self->error_reason( Base::File->error() );
	return;
    }

    use FileHandle;
    my $fh = new FileHandle ">> $cachefile";
    if (defined $fh) {
	print $fh "";
	close($fh);
    }
    else {
	$self->error_reason("cannot open ticket cache");
    }
}


sub AUTOLOAD
{
    my ($self) = @_;

    eval q{
	use FML::Log;
	Log("FYI: unknown method $AUTOLOAD is called");
    };
}


=head1 NAME

Ticket::System.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut


1;
