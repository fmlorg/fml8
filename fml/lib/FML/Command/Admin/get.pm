#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.24 2004/03/23 06:34:15 fukachan Exp $
#

package FML::Command::Admin::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::SendFile;
@ISA = qw(FML::Command::SendFile);

=head1 NAME

FML::Command::Admin::get - get arbitrary file(s) in $ml_home_dir

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

get arbitrary file(s) in $ml_home_dir.

=head1 METHODS

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
sub need_lock { 0;}


# Descriptions: send arbitrary file(s) in $ml_home_dir by
#               FML::Command::SendFile.
#               XXX we permit arbitrary file for administrator to retrieve.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config      = $curproc->config();
    my $ml_home_dir = $config->{ ml_home_dir };
    my $command     = $command_args->{ command };
    my $options     = $command_args->{ options };
    my $recipient   = '';

    if ($curproc->is_cui_process()) {
	$recipient = $curproc->command_specific_recipient() || '';
	$command_args->{ _recipient } = $recipient;
    }

    # This module is called after
    # FML::Process::Command::_can_accpet_command() already checks the
    # command syntax. $options is raw command as ARRAY_REF such as
    #     $options = [ 'get:3', 1, 100 ];
    # send_file() called below can parse MH style argument.
    for my $filename (@$options) {
	use File::Spec;
	my $filepath = File::Spec->catfile($ml_home_dir, $filename);

	# XXX-TODO: we expect send_file() validates ${filename,filepath}.
	if (-f $filepath) {
	    $curproc->log("send back $filename");

	    $command_args->{ _filename_to_send } = $filename;
	    $command_args->{ _filepath_to_send } = $filepath;

	    $self->send_file($curproc, $command_args);

	    delete $command_args->{ _filename_to_send };
	    delete $command_args->{ _filepath_to_send };
	    delete $command_args->{ _recipient };
	}
	else {
	    $curproc->log("$filename not found");
	    $curproc->reply_message_nl('error.no_such_file',
				       "no such file $filename",
				       {
					   _arg_file => $filename,
				       });
	    croak("no such file $filepath");
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::get first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
