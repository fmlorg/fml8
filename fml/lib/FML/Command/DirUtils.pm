#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DirUtils.pm,v 1.19 2004/07/23 04:16:24 fukachan Exp $
#

package FML::Command::DirUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::DirUtils - utilities for directory handlings.

=head1 SYNOPSIS

=head1 DESCRIPTION

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

#
# XXX-TODO: if we can find CPAN module for dir listing, use it.
#

# Descriptions: show the result by executing "ls".
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($du_args)
# Side Effects: none
# Return Value: none
sub dir
{
    my ($self, $curproc, $command_args, $du_args) = @_;
    my $config  = $curproc->config();
    my $path_ls = $config->{ path_ls };
    my $argv    = $du_args->{ argv };
    my $opt_ls  = '';
    my $rm_args = {};

    # inherit reply_message information.
    my $recipient = $command_args->{ recipient } || '';
    if ($recipient) { $rm_args->{ recipient } = $recipient;}

    # option: permit "ls [-A-Za-z]" syntax
    if (defined($du_args->{ opt_ls })) {
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	my $opt  = $du_args->{ opt_ls };
	if ($safe->regexp_match('command_line_options', $opt)) {
	    $opt_ls = $opt;
	}
	else {
	    $curproc->logwarn("deny ls options '$opt'");
	    $opt_ls = '';
	}
    }

    # regexp allowed to use here
    my $safe = $self->{ _safe };

    # chdir the ml's home dir
    my $ml_home_dir = $config->{ ml_home_dir };
    chdir $ml_home_dir || croak("cannot chdir \$ml_home_dir");

    # build safe arguments
    my $y = '';
    for my $x (@$argv) {
	if ($safe->regexp_match('directory', $x) || $x =~ /^\s*$/) {
	    $y .= " ". $x;
	}
    }

    if (-x $path_ls) {
	my $eval = "$path_ls $opt_ls $y";
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

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::DirUtils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
