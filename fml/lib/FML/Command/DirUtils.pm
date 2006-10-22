#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DirUtils.pm,v 1.23 2006/03/05 09:50:42 fukachan Exp $
#

package FML::Command::DirUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::DirUtils - utilities for directory handlings.

=head1 SYNOPSIS

    use FML::Command::DirUtils;
    my $obj = new FML::Command::DirUtils;
    $obj->dir($curproc, $command_context, $du_args);

=head1 DESCRIPTION

This class provides utilities for directory handlings.

=head1 METHODS

=head2 new()

constructor.

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

    use FML::Restriction::Base;
    $me->{ _safe } = new FML::Restriction::Base;

    return bless $me, $type;
}


=head2 dir($curproc, $command_context, $du_args)

show the result by executing "ls".

=cut


#
# XXX-TODO: if we can find CPAN module for dir listing, use it.
#

# Descriptions: show the result by executing "ls".
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($du_args)
# Side Effects: none
# Return Value: none
sub dir
{
    my ($self, $curproc, $command_context, $du_args) = @_;
    my $config = $curproc->config();

    # inherit reply_message information.
    my $rm_args   = {};
    my $recipient = $command_context->{ recipient } || '';
    if ($recipient) { $rm_args->{ recipient } = $recipient;}

    # option: permit "ls [-A-Za-z]" syntax
    my $safe_opt_ls  = '';
    if (defined($du_args->{ opt_ls })) {
	my $opt  = $du_args->{ opt_ls };
	my $safe = $self->{ _safe };
	if ($safe->regexp_match('command_line_options', $opt)) {
	    $safe_opt_ls = $opt;
	}
	else {
	    $curproc->logwarn("deny ls options '$opt'");
	    $safe_opt_ls = '';
	}
    }

    # regexp allowed to use here
    my $safe = $self->{ _safe };

    # chdir the ml's home dir
    my $ml_home_dir = $config->{ ml_home_dir };
    chdir $ml_home_dir || croak("cannot chdir \$ml_home_dir");

    # build safe arguments
    my $safe_args = '';
    my $argv      = $du_args->{ argv };
    for my $x (@$argv) {
	if ($safe->regexp_match('directory', $x) || $x =~ /^\s*$/) {
	    $safe_args .= " $x";
	}
    }

    # execute ls command.
    my $path_ls = $config->{ path_ls };
    if (-x $path_ls) {
	my $eval = "$path_ls $safe_opt_ls $safe_args";
	$curproc->log("dir: run \"$eval\"");

	use FileHandle;
	my $fh = new FileHandle "$eval|";
	if (defined $fh) {
	    my $buf = undef;
	    while ($buf = <$fh>) { $curproc->reply_message($buf, $rm_args);}
	    $fh->close();
	}
	else {
	    $curproc->logerror("fail to run '$eval'");
	}
    }
    else {
	$curproc->logerror("\$path_ls not found");
	croak("\$path_ls not found");
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

FML::Command::DirUtils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
