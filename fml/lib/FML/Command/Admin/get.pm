#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.29 2006/03/04 13:48:28 fukachan Exp $
#

package FML::Command::Admin::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::SendFile;
@ISA = qw(FML::Command::SendFile);

=head1 NAME

FML::Command::Admin::get - get arbitrary file(s) in $ml_home_dir.

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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: send arbitrary file(s) in $ml_home_dir by
#               FML::Command::SendFile.
#               XXX we permit arbitrary file for administrator to retrieve.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config      = $curproc->config();
    my $ml_home_dir = $config->{ ml_home_dir };
    my $options     = $command_context->get_options();
    my $recipient   = '';

    if ($curproc->is_cui_process()) {
	$recipient = $curproc->command_line_cui_specific_recipient() || '';
	$command_context->{ _recipient } = $recipient;
    }

    # This module is called after
    # FML::Process::Command::_can_accpet_command() already checks the
    # command syntax. $options contains only arguments as ARRAY_REF such as
    #     $options = [ 1, 100 ] for command string "get 1,100".
    # send_file() called below can parse MH style argument.
    for my $filename (@$options) {
	use File::Spec;
	my $filepath = File::Spec->catfile($ml_home_dir, $filename);

	# XXX-TODO: we expect send_file() validates ${filename,filepath}.
	if (-f $filepath) {
	    $curproc->log("send back $filename");

	    $command_context->{ _filename_to_send } = $filename;
	    $command_context->{ _filepath_to_send } = $filepath;

	    $self->send_file($curproc, $command_context);

	    delete $command_context->{ _filename_to_send };
	    delete $command_context->{ _filepath_to_send };
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


    if (defined $command_context->{ _recipient }) {
	delete $command_context->{ _recipient };
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::get first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
