#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.5 2001/12/22 09:21:03 fukachan Exp $
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


# Descriptions: send file in $ml_home_dir
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

    for my $f (@$options) {
	use File::Spec;
	my $file = File::Spec->catfile($ml_home_dir, $f);

	print STDERR "send back $file (debug)\n";

	next;

	if (-f $file) {
	    $command_args->{ _file_to_send } = $file;
	    $self->send_file($curproc, $command_args);
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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
