#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: FileUtils.pm,v 1.4 2002/07/02 12:04:57 fukachan Exp $
#

package FML::Command::FileUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::FileUtils - utilities to handle files

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


# Descriptions: remove files
#    Arguments: OBJ($self) ... varargs ...
# Side Effects: remove files
# Return Value: same as remove()
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
    my $config   = $curproc->{ config };
    my $argv     = $du_args->{ options };
    my $is_error = 0;

    # regexp
    my $basic_variable = $self->{ _basic_variable };
    my $file_regexp    = $basic_variable->{ file };
    my $ml_home_dir    = $config->{ ml_home_dir };

    # chdir $ml_home_dir firstly. return ASAP if failed.
    chdir $ml_home_dir || croak("cannot chdir \$ml_home_dir");

    for my $file (@$argv) {
	# If $file is a safe pattern, o.k. Try to remove it!
	if ($file =~ /^$file_regexp$/) {
	    if (-f $file) {
		unlink $file;

		if (-f $file) {
		    LogError("fail to remove $file");
		    $is_error++;
		}
		else {
		    Log("remove $file");
		    $curproc->reply_message_nl("command.remove_file",
					       "removed $file",
					       { _arg_file => $file } );
		}
	    }
	    else {
		LogWarn("no such file $file");
		$curproc->reply_message_nl("command.no_such_file",
					   "no such file $file",
					   { _arg_file => $file } );
		$is_error++;
	    }
	}
	# $file filename is unsafe. stop.
	else {
	    LogError("<$file> is insecure");
	    $curproc->reply_message_nl('command.insecure',
				       "insecure input");
	    croak("remove: insecure argument");
	}
    }

    if ($is_error) {
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

FML::Command::FileUtils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
