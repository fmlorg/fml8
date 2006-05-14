#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.10 2006/01/07 13:16:41 fukachan Exp $
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


# Descriptions: checksum of mail Envelope part.
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

    # compare sender and envelope sender.
    my $maintainer = $config->{ maintainer } || '';
    if ($maintainer) {
	$maintainer      =~ tr/A-Z/a-z/;
	$envelope_sender =~ tr/A-Z/a-z/;
	if ($maintainer eq $envelope_sender) {
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
    my $curproc = $self->{ _curproc };

    if ($type eq 'md5') {
	$self->{ _type } = $type;
    }
    else {
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
