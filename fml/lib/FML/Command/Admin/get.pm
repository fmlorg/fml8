#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.6 2001/12/23 03:50:06 fukachan Exp $
#

package FML::Command::Admin::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Command::SendFile;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::SendFile FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::Admin::get - get arbitrary file in $ml_home_dir

=head1 SYNOPSIS

   ... NOT IMPLEMENTED ...

See C<FML::Command> for more details.

=head1 DESCRIPTION

get arbitrary file in $ml_home_dir

=head1 METHODS

=cut


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: send arbitrary file in $ml_home_dir by
#               FML::Command::SendFile.
#               XXX we permit arbitrary file for administrator to retrieve.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $command     = $command_args->{ 'command' };
    my $config      = $curproc->{ 'config' };
    my $ml_home_dir = $config->{ ml_home_dir };
    my $options     = $command_args->{ options };

    # This module is called after
    # FML::Process::Command::_can_accpet_command() already checks the
    # command syntax. $options is raw command as ARRAY_REF such as
    #     $options = [ 'get:3', 1, 100 ];
    # send_file() called below can parse MH style argument.
    for my $f (@$options) {
	use File::Spec;
	my $file = File::Spec->catfile($ml_home_dir, $f);

	Log("send back $file"); # XXX but return to whom ?

	if (-f $file) {
	    Log("send back $file");
	    $command_args->{ _file_to_send } = $file;
	    $self->send_file($curproc, $command_args);
	    delete $command_args->{ _file_to_send };
	}
	else {
	    $curproc->reply_message_nl('error.no_such_file',
				       "no such file $file",
				       {
					   _arg_file => $f,
				       });
	    croak("no such file $file");
	}
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
