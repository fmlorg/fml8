#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Error.pm,v 1.9 2003/01/03 03:49:30 fukachan Exp $
#

package FML::Error;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


my $debug = 1;


=head1 NAME

FML::Error - front end for the analyze of error messages.

=head1 SYNOPSIS

    use FML::Error;
    my $error = new FML::Error $curproc;

    # analyze error messages and holds the result within the object.
    $error->analyze();

    # remove addresses analyze() determined as bouncers.
    $error->remove_bouncers();

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

usual constructor.

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


=head2 analyze()

open error message cache and 
analyze the data by the analyzer function.
The function is specified by $config->{ error_analyzer_function }.
Available functions are located in C<FML::Error::Analyze>.
C<simple_count> function is used by default if $config->{
error_analyzer_function } is unspecified.

=cut


# Descriptions: open error message cache and analyze the data by
#               the specified analyzer function.
#    Arguments: OBJ($self)
# Side Effects: set up $self->{ _remove_addr_list } used internally. 
# Return Value: none
sub analyze
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    use FML::Error::Cache;
    my $cache = new FML::Error::Cache $curproc;
    my $rdata = $cache->get_all_values_as_hash_ref();

    use FML::Error::Analyze;
    my $analyzer = new FML::Error::Analyze $curproc;
    my $fp       = $config->{ error_analyzer_function } || 'simple_count';
    my $list     = $analyzer->$fp($curproc, $rdata);

    # pass address list to remove
    $self->{ _remove_addr_list } = $list;
}


=head2 remove_bouncers()

delete mail addresses, analyze() determined as bouncers, by deluser()
method.

You need to call analyze() method before calling remove_bouncers() to
list up addresses to remove.

=cut


# Descriptions: delete addresses analyze() determined as bouncers
#    Arguments: OBJ($self)
# Side Effects: update user address lists.
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
    my $addrreg = $safe->regexp( 'address' );

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


=head2 deluser( $address )

delete the specified address by C<FML::Command::Admin::unsubscribe>.

=cut


# Descriptions: delete the specified address.
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
    my $addrreg = $safe->regexp( 'address' );

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
            ; # log nothing.
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

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Error first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
