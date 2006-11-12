#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Envelope.pm,v 1.2 2006/07/09 12:11:12 fukachan Exp $
#

package FML::Envelope;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Envelope - provide envelope based operations.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 check_envelope_sender()

check if the envelope sender is not our maintainer.

=cut


# Descriptions: check if the envelope sender is not our maintainer.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub check_envelope_sender
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $message = $curproc->incoming_message();
    my $config  = $curproc->config();

    # ASSERT: null envelope sender is invalid.
    my $envelope_sender = $message->envelope_sender() || '';
    unless ($envelope_sender) {
	return 0;
    }

    # compare the envelope sender with our maintainer.
    my $maintainer = $config->{ maintainer } || '';
    if ($maintainer) {
	use FML::Credential;
	my $cred = new FML::Credential $curproc;
	if ($cred->is_same_address($maintainer, $envelope_sender, 128)) {
	    $curproc->logerror("envelope sender == maintainer");
	    return 1;
	}
	else {
	    return 0;
	}
    }

    return 0;
}


=head1 ACCESS METHODS

=head2 set_checksum_type($type)

set checksum method type.

=head2 get_checksum_type()

get checksum method type.
return 'md5' by default.

=cut


my $gloval_default_checksum_type = 'md5';


# Descriptions: set checksum method type.
#    Arguments: OBJ($self) STR($type)
# Side Effects: update $self
# Return Value: none
sub set_checksum_type
{
    my ($self, $type) = @_;

    if ($type eq 'md5') {
	$self->{ _type } = $type;
    }
    else {
	my $curproc = $self->{ _curproc };
	$curproc->logerror("unsupported checksum: $type");
    }
}


# Descriptions: return checksum method type.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_checksum_type
{
    my ($self) = @_;

    return( $self->{ _type } || $gloval_default_checksum_type );
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

FML::Envelope appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
