#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: FileUtils.pm,v 1.1 2002/03/26 04:01:35 fukachan Exp $
#

package FML::Command::FileUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::FileUtils - utilities for file handling

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    $me->{ _basic_variable } = $safe->basic_variable();

    return bless $me, $type;
}


sub delete
{
    my ($self, @p) = @_;
    $self->remove(@p);
}


# Descriptions: remove files
#    Arguments: OBJ($self) HASH_REF($curproc) HASH_REF($command_args)
#               HASH_REF($du_args)
# Side Effects: none
# Return Value: none
sub remove
{
    my ($self, $curproc, $command_args, $du_args) = @_;
    my $config  = $curproc->{ config };
    my $argv    = $du_args->{ options };
    my $is_warn = 0;

    # regexp
    my $basic_variable = $self->{ _basic_variable };
    my $regexp = $basic_variable->{ file };

    my $ml_home_dir = $config->{ ml_home_dir };
    chdir $ml_home_dir;

    for my $file (@$argv) {
	if ($file =~ /^$regexp$/) {
	    if (-f $file) {
		unlink $file;

		if (-f $file) {
		    LogError("fail to remove $file");
		    $is_warn++;
		}
		else {
		    Log("remove $file");
		    $curproc->reply_message_nl("command.remove_file",
					       "removed $file",
					       { _arg_file => $file } );
		}
	    }
	    else {
		$curproc->reply_message_nl("command.no_such_file",
					   "no such file $file",
					   { _arg_file => $file } );
		LogWarn("no such file $file");
		$is_warn++;
	    }
	}
	else {
	    $curproc->reply_message_nl('command.insecure',
				       "insecure input $file");
	    croak("remove: insecure argument");
	}
    }

    if ($is_warn) {
	croak("remove: something fail.");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::FileUtils appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
