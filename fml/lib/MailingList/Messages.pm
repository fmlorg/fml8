#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package MailingList::Messages;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    if ($args) { create($me, $args);}
    return bless $me, $type;
}


######################################################################
=head1 NAME

MailingList::Messages -- message manipulators

=head1 SYNOPSIS

    my $m1 = new MailingList::Messages { content => \$body1 };

    my $m2 = new MailingList::Messages;
    $m2->create( { content => \$body2 });

    # make a chain of $m1, $m2, ...
    $m1->chain( $m2 );

    # print the contents in the order:  $m1, $m2, ... 
    $m1->print;

=head1 DESCRIPTION

A message has the content and a header including the next message
pointer, et. al. Out idea is similar to IPv6.

Message Format

   %message = {
                version      => 1.0
                content_type => message/rfc822
                next         => \%next_message
                prev         => \%prev_message
                header       => {
                                    field_name => field_value
                                 }
                content      => \$message_body
               }


=item Function()

=cut


sub create
{
    my ($self, $args) = @_;

    $self->{ version } = $args->{ version } || 1.0; 
    $self->{ type    } = $args->{ type    } || 'message/rfc822';
    $self->{ next    } = $args->{ next    } || undef;
    $self->{ prev    } = $args->{ prev    } || undef;
    $self->{ header  } = $args->{ header  } || undef;
    $self->{ content } = $args->{ content } || '';
}


sub next_chain
{
    my ($self, $ref_next_message) = @_;
    $self->{ next } = $ref_next_message;
}


sub prev_chain
{
    my ($self, $ref_prev_message) = @_;
    $self->{ prev } = $ref_prev_message;
}


sub print
{
    my ($self, $fd) = @_;
    my $msg = $self;

    # if $fd is not given, we use STDOUT.
    unless (defined $fd) { $fd = \*STDOUT;}
    
  MSG:
    while (1) {
	$self->_print($fd, $msg->{ content });
	last MSG unless $msg->{ next };
	$msg = $self->{ next };
    }
}


# Descriptions: send the body part of the message to socket
#               replace "\n" in the end of line with "\r\n" on memory.
#               We should do it to use as less memory as possible.
#               So we use substr() to process each line.
#    Arguments: $self $socket $ref_to_body
# Side Effects: none
# Return Value: none
sub _print
{
    my ($self, $fd, $r_body) = @_;

    my $pp     = 0;
    my $maxlen = length($$r_body);
    my $logfp  = $self->{ _log_function };
    $logfp     = ref($logfp) eq 'CODE' ? $logfp : undef;

    # write each line in buffer
    my ($p, $len, $buf, $pbuf);
  SMTP_IO:
    while (1) {
	$p   = index($$r_body, "\n", $pp);
	$len = $p  - $pp + 1;
	$buf = substr($$r_body, $pp, ($p < 0 ? $maxlen-$pp : $len));
	if ($buf !~ /\r\n$/) { $buf =~ s/\n$/\r\n/;}

	# ^. -> ..
	$buf =~ s/^\./../;

	print $fd    $buf;
	&$logfp($buf) if $logfp;

	last SMTP_IO if $p < 0;
	$pp = $p + 1;
    }
}


sub size
{
    my ($self) = @_;
    my $c = $self->{ content };
    length($$c);
}


sub is_empty
{
    my ($self) = @_;
    my $size   = $self->size;
    my $c      = $self->{ content };

    if ($size == 0) { return 1;}
    if ($size <= 8) {
	if ($$c =~ /^\s*$/) { return 1;}
    }

    # false
    return 0;
}


sub set_log_function
{
    my ($self, $fp) = @_;
    $self->{ _log_function } = $fp; # log function pointer
}


######################################################################
=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

MailingList::Messages.pm appeared in fml5.

=cut

1;
