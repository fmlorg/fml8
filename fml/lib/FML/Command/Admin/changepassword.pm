#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: changepassword.pm,v 1.4 2003/03/18 10:42:42 fukachan Exp $
#

package FML::Command::Admin::changepassword;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::changepassword - change admin password

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

password a new address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: change the admin password.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: NUM
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $myname  = $curproc->myname();
    my $options = $command_args->{ options };

    # XXX The arguments differ for the cases.
    # 1. command mail: admin changepassword [$USER] $PASSWORD
    # 2. command line: makefml changepassword $ML $ADDR $PASSWORD
    #                  fml $ML changepassword     $ADDR $PASSWORD
    if ($myname eq 'makefml' || $myname eq 'fml' ||
	$myname eq 'loader' ||
	$myname eq 'command' || $myname eq 'fml.pl') {
	my ($address, $password);

	if ($options->[2]) {
	    croak("wrong arguments");
	}
	elsif ($options->[0] && $options->[1]) {
	    $address  = $options->[ 0 ];
	    $password = $options->[ 1 ];
	}
	elsif ($options->[0]) {
	    # XXX special treatment only for command mails.
	    if ($myname eq 'command' || $myname eq 'fml.pl') {
		my $cred  = $curproc->{ credential };
		$address  = $cred->sender(); # From: in the header
		$password = $options->[ 0 ];
	    }
	    else {
		croak("wrong arguments");
	    }
	}
	else {
	    croak("wrong arguments");
	}

	$self->_change_password($curproc, $command_args, $address, $password);
    }
    else {
	LogError("myname=$myname unknown program");
    }
}


# Descriptions: change the admin password.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
#               STR($address) STR($password)
# Side Effects: update *admin_member_password_maps
# Return Value: NUM
sub _change_password
{
    my ($self, $curproc, $command_args, $address, $password) = @_;
    my $config  = $curproc->config();
    my $pri_map = $config->{ primary_admin_member_password_map };
    my $up_args = {
	map      => $pri_map,
	address  => $address,
	password => $password,
    };
    my $r = '';

    eval q{
	use FML::Command::Auth;
	my $passwd = new FML::Command::Auth;
	$passwd->change_password($curproc, $command_args, $up_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: rewrite buffer to hide the password phrase in $rbuf
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR_REF($rbuf)
# Side Effects: none
# Return Value: none
sub rewrite_prompt
{
    my ($self, $curproc, $command_args, $rbuf) = @_;

    if (defined $rbuf) {
	$$rbuf =~ s/^(.*(password|pass)\s+).*/$1 ********/;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::changepassword
first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
