#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DirUtils.pm,v 1.7 2002/08/03 13:13:21 fukachan Exp $
#

package FML::Command::DirUtils;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::DirUtils - utilities for directory handlings

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


# Descriptions: show the result by executing "ls"
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($du_args)
# Side Effects: none
# Return Value: none
sub dir
{
    my ($self, $curproc, $command_args, $du_args) = @_;
    my $config  = $curproc->{ config };
    my $path_ls = $config->{ path_ls };
    my $argv    = $du_args->{ argv };
    my $opt_ls  = '';

    # option: permit "ls [-A-Za-z]" syntax
    if (defined($du_args->{ opt_ls })) {
	my $opt = $du_args->{ opt_ls };
	if ($opt =~ /^-[A-Za-z]+$/) {
	    $opt_ls = $opt;
	}
	else {
	    LogWarn("deny ls options '$opt'");
	}
    }

    # regexp allowed to use here
    my $basic_variable = $self->{ _basic_variable };
    my $dir_regexp     = $basic_variable->{ directory };

    # chdir the ml's home dir
    my $ml_home_dir    = $config->{ ml_home_dir };
    chdir $ml_home_dir || croak("cannot chdir \$ml_home_dir");

    # build a safe argument
    my $y = '';
    for my $x (@$argv) {
	if ($x =~ /^$dir_regexp$/ || $x =~ /^\s*$/) {
	    $y .= " ". $x;
	}
    }

    if (-x $path_ls) {
	Log("$path_ls $opt_ls $y");

	use FileHandle;
	my $fh = new FileHandle "$path_ls $opt_ls $y|";
	if (defined $fh) {
	    while (<$fh>) { $curproc->reply_message($_);}
	    $fh->close();
	}
	else {
	    LogError("tail to run '$path_ls $opt_ls $y'");
	}
    }
    else {
	LogError("\$path_ls is not found");
	croak("\$path_ls is not found");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::DirUtils first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
