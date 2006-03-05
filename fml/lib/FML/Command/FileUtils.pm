#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: FileUtils.pm,v 1.19 2006/03/05 08:08:36 fukachan Exp $
#

package FML::Command::FileUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::FileUtils - utilities to handle files.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    use FML::Restriction::Base;
    $me->{ _safe } = new FML::Restriction::Base;

    return bless $me, $type;
}


=head2 delete($curproc, $command_context, $du_aregs)

same as remove() below.

=head2 remove($curproc, $command_context, $du_aregs)

remove files specified in $du_args->{ options }
if the file exsits and the file name matches safe file regexp defined
in FML::Restriction class.

=cut


# Descriptions: remove files.
#    Arguments: OBJ($self) VARARGS(@p)
# Side Effects: remove files
# Return Value: same as remove()
sub delete
{
    my ($self, @p) = @_;
    $self->remove(@p);
}


# Descriptions: remove files.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($du_args)
# Side Effects: none
# Return Value: none
sub remove
{
    my ($self, $curproc, $command_context, $du_args) = @_;
    my $config   = $curproc->config();
    my $argv     = $du_args->{ options };
    my $is_error = 0;

    # regexp allowed here for file
    my $safe = $self->{ _safe };

    # chdir $ml_home_dir firstly. return ASAP if failed.
    my $ml_home_dir = $config->{ ml_home_dir };
    chdir $ml_home_dir || croak("cannot chdir \$ml_home_dir");

    for my $file (@$argv) {
	# If $file is a safe pattern, o.k. Try to remove it!
	if ($safe->regexp_match('file', $file)) {
	    if (-f $file) {
		unlink $file;

		if (-f $file) {
		    $curproc->logerror("fail to remove $file");
		    $is_error++;
		}
		else {
		    $curproc->log("remove $file");
		    $curproc->reply_message_nl("command.remove_file",
					       "removed $file",
					       { _arg_file => $file } );
		}
	    }
	    else {
		$curproc->logwarn("no such file $file");
		$curproc->reply_message_nl("command.no_such_file",
					   "no such file $file",
					   { _arg_file => $file } );
		$is_error++;
	    }
	}
	# $file filename is unsafe. stop.
	else {
	    $curproc->logerror("<$file> is insecure");
	    $curproc->reply_message_nl('command.insecure',
				       "insecure input");
	    croak("remove: insecure argument");
	}
    }

    if ($is_error) {
	croak("remove: something fail.");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::FileUtils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
