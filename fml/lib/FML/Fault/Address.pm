#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Address.pm,v 1.2 2006/03/05 08:08:37 fukachan Exp $
#

package FML::Fault::Address;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Fault::Address - fault handler

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
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


=head2 try_subscribe()

check address and subscribe address if it is not a member.

=head2 subscribe($addr)

subscribe $addr.

=cut


# Descriptions: subscribe address if it is not a member.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub try_subscribe
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();
    my $list    = $curproc->get_address_fault_list() || [];

    if (@$list) {
	$curproc->log("address fault requested");
	for my $addr (@$list) {
	    unless ($cred->is_member($addr)) {
		$self->subscribe($addr);
	    }
	    else {
		$curproc->logdebug("$addr is already a member");
	    }
	}
    }
}


# Descriptions: subscribe the specified address.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: none
sub subscribe
{
    my ($self, $addr) = @_;
    my $curproc = $self->{ _curproc };
    my $method  = "subscribe";
    my @options = ($addr);

    $curproc->log("subscribe $addr");

    my $command_context = $curproc->command_context_init("$method $addr");
    $command_context->set_mode("Admin");
    $command_context->set_cooked_command($method);
    $command_context->set_clean_command("$method @options");
    $command_context->set_options(\@options);

    require FML::Command;
    my $obj = new FML::Command;

    if (defined $obj) {
        # execute command ($comname method) under eval().
        eval q{
            $obj->$method($curproc, $command_context);
        };
        unless ($@) {
            ; # not show anything
        }
        else {
            my $r = $@;
            $curproc->logerror("command $method fail");
            $curproc->logerror($r);
            if ($r =~ /^(.*)\s+at\s+/) {
                my $reason = $1;
                $curproc->logerror($reason); # pick up reason
                croak($reason);
            }
        }
    }
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

FML::Fault::Address appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
