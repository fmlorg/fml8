#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Filter.pm,v 1.8 2006/10/22 14:18:05 fukachan Exp $
#

package FML::Command::Filter;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $debug);
use Carp;


# XXX_LOCK_CHANNEL: auth_map_modify
my $lock_channel = "auth_map_modify";


=head1 NAME

FML::Command::Filter - command mail specific filters.

=head1 SYNOPSIS

use FML::Command::Filter;
my $_msg   = $curproc->incoming_message_body();
my $obj    = new FML::Command::Filter $curproc;
my $reason = $obj->check_command_limit($_msg);

=head1 DESCRIPTION

This class provides command mail specific filters.

check_command_limit() checks the number of command requests in one
command mail.

check_line_length_limit() checks the line length of each line in a
command mail.

=head1 METHODS

=head2 new()

constructor.

=head2 reject()

dummy.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: virtual reject handler, just return __LAST__ :-).
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: STR (__LAST__, a special upcall)
sub reject
{
    my ($self, $msg) = @_;

    return '__LAST__';
}


# Descriptions: check the number of command requests in one mail.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: admin password modified.
# Return Value: STR( NULL if fail )
sub check_command_limit
{
    my ($self, $msg) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $limit   = $config->{ command_mail_valid_command_limit } || 1024;
    my $lines   = $msg->message_text_as_array_ref();
    my $count   = 0;

  LINE:
    for my $buf (@$lines) {
	$count++ if $buf =~ /^\w+$|^\w+\s+/o;
	last LINE if $count > $limit;
    }

    if ( $count > $limit ) {
	$curproc->logerror("command_limit: $count > $limit");
    }

    my $r = "number of commands per mail exceeds limit $limit";
    return( $count > $limit ? $r : '' );
}


# Descriptions: check the length of one command request (one line).
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: admin password modified.
# Return Value: STR( NULL if fail )
sub check_line_length_limit
{
    my ($self, $msg) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $limit   = $config->{ command_mail_line_length_limit } || 999;
    my $lines   = $msg->message_text_as_array_ref();
    my $match   = 0;
    my $len;

  LINE:
    for my $buf (@$lines) {
	$len = length($buf);

	if ($len > $limit) {
	    $match++;
	}
    }

    if ($match) {
	$curproc->logerror("line_length_limit: $match times (\$len > $limit)");
    }

    my $r = "too long command (> $limit bytes)\n";
    return( $match ? $r : '' );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Filter first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
