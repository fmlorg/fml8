#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#

package FML::Mailer;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogError);

=head1 NAME

FML::Mailer - Utilities to send mails

=head1 SYNOPSIS

    use FML::Mailer;
    my $obj = new FML::Mailer;
    $obj->send( {
	sender    => 'rudo@nuinui.net',
	recipient => 'kenken@nuinui.net',
	message   => $message,
    });

where C<$message> is a C<Mail::Message> object to be sent. 
If you sent plural recipinets, you can pass the list of recipients by
HASH ARRAY.

    $obj->send( {
	sender     => 'rudo@nuinui.net',
	recipients => [ 'kenken@nuinui.net', 'hitomi@nuinui.net' ],
	message    => $message,
    });


=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 C<send($args)>

method to send the given C<message>.

=cut

sub send
{
    my ($self, $args) = @_;
    my ($config, $maintainer, $fp, $sfp) = ();

    # $curproc is given in usual fml processes.
    # but not in other programs.
    if (defined $args->{ curproc }) {
	$config     = $args->{ curproc }->{ config } || undef;
	$maintainer = $config->{ maintainer };

	$fp  = sub { Log(@_);}; # pointer to the log function
	$sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    }

    # Mail::Message which is sent
    my $message    = $args->{ message } || undef;

    # who is sender
    my $sender     = $args->{ sender } || $maintainer;

    # recipient(s): expected to be given as string or HASH ARRAY
    my $recipient  = $args->{ recipient }  || undef;
    my $recipients = $args->{ recipients } || [ $recipient ] || undef;


    ### main ###
    use Mail::Delivery;
    my $service = new Mail::Delivery {
	log_function       => $fp,
	smtp_log_function  => $sfp,
    };
    if ($service->error) { LogError($service->error); return 0;}

    $service->deliver({
	'smtp_sender'     => $sender,
	'recipient_array' => $recipients,
	'message'         => $message,
    });
    if ($service->error) { LogError($service->error); return 0;}

    return 1;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Mailer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
