#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: get.pm,v 1.3 2001/09/13 14:45:46 fukachan Exp $
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

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $command     = $command_args->{ 'command' };
    my $config      = $curproc->{ 'config' };
    my $ml_home_dir = $config->{ ml_home_dir };

    use File::Spec;
    my $file = File::Spec->catfile($ml_home_dir, $f);

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
