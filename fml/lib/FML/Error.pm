#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Error.pm,v 1.2 2002/08/08 03:02:49 fukachan Exp $
#

package FML::Error;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

my $debug = 1;


=head1 NAME

FML::Error - error manipulation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self) HASH_REF($curproc)
# Side Effects: none
# Return Value: none
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


sub analyze
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };

    use FML::Error::Cache;
    my $cache = new FML::Error::Cache $curproc;
    my $rdata = $cache->get_all_values_as_hash_ref();
    my $list  = $self->md_analyze($curproc, $rdata);

    # pass address list to remove
    $self->{ _remove_addr_list } = $list;
}


# *** model specific analyzer ***
# $data = {
#    address => [ 
#           error_string_1,
#           error_string_2, ... 
#    ]
# };

sub md_analyze
{
    my ($self, $curproc, $data) = @_;
    my ($addr, $bufarray, $count);
    my @removelist = ();

    while (($addr, $bufarray) = each %$data) {
	$count = 0;
	if (defined $bufarray) {
	    for my $buf (@$bufarray) {
		$count++;
	    }
	}

	if ($count > 5) {
	    push(@removelist, $addr);
	}
    }

    return \@removelist;
}


# Descriptions: delete addresses analyze() determines as bouncers
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub remove_bouncers
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $list    = $self->{ _remove_addr_list };

    use FML::Credential;
    my $cred = new FML::Credential $curproc;

    use FML::Restriction::Base;
    my $safe    = new FML::Restriction::Base;
    my $regexp  = $safe->basic_variable();
    my $addrreg = $regexp->{ address };

  ADDR:
    for my $addr (@$list) {
	# check if $address is a safe string.
	if ($addr =~ /^($addrreg)$/) {
	    if ($cred->is_member( $addr ) || $cred->is_recipient( $addr )) {
		$self->deluser( $addr );
	    }
	    else {
		Log("remove_bouncers: <$addr> seems not member");
	    }
	}
	else {
	    LogError("remove_bouncers: <$addr> is invalid");
	    next ADDR;
	}
    }
}


# Descriptions: delete the specified address
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: none
sub deluser
{
    my ($self, $address) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };

    use FML::Restriction::Base;
    my $safe    = new FML::Restriction::Base;
    my $regexp  = $safe->basic_variable();
    my $addrreg = $regexp->{ address };

    # check if $address is a safe string.
    if ($address =~ /^($addrreg)$/) {
	Log("deluser <$address>");
    }
    else {
	LogError("deluser: invalid address");
	return;
    }

    # arguments to pass off to each method
    my $method       = 'unsubscribe';
    my $command_args = {
        command_mode => 'admin',
        comname      => $method,
        command      => "$method $address",
        ml_name      => $ml_name,
        options      => [ $address ],
        argv         => undef,
        args         => undef,
    };

    # here we go
    require FML::Command;
    my $obj = new FML::Command;

    if (defined $obj) {
        # execute command ($comname method) under eval().
        eval q{
            $obj->$method($curproc, $command_args);
        };
        unless ($@) {
            ; # not show anything
        }
        else {
            my $r = $@;
            LogError("command $method fail");
            LogError($r);
            if ($r =~ /^(.*)\s+at\s+/) {
                my $reason = $1;
                Log($reason); # pick up reason
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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
