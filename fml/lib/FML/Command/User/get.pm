#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: get.pm,v 1.2 2001/08/26 07:59:03 fukachan Exp $
#

package FML::Command::User::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::User::get - what is this

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


sub process
{
    my ($self, $curproc, $optargs) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $optargs->{ options };
    my $address       = $optargs->{ address } || $options->[ 0 ];

    my $command       = $optargs->{ command };
    my $ml_name       = $config->{ ml_name };
    my $spool_dir     = $config->{ spool_dir };
    my $charset       = $config->{ template_file_charset };

    # command buffer = get 1
    # command buffer = get 1,2,3
    # command buffer = get last:3
    my (@files) = split(/\s+/, $optargs->{ command });
    for my $fn (@files) {
	my $filelist = _is_valid_argument($fn);
	if (defined $filelist) {
	    for my $fn (@$filelist) {
		my $file = "$spool_dir/$fn";
		if (-f $file) {
		    Log("send back article $fn");
		    $curproc->reply_message( {
			type        => "message/rfc822; charset=$charset",
			path        => $file,
			filename    => $fn,
			disposition => "$ml_name ML article $fn",
		    });
		}
		else {
		    Log("no such file: $file");
		}
	    }
	}
    }
}


sub _is_valid_argument
{
    my ($fn) = @_;

    if ($fn =~ /^\d+$/) {
	return [ $fn ];
    }
    elsif ($fn =~ /^[\d,]+$/) {
	my (@fn) = split(/,/, $fn);
	return \@fn;
    }
    elsif ($fn =~ /^(\d+)\-(\d+)$/) {
	my ($first, $last) = ($1, $2);
	my (@fn);
	for ($first .. $last) { push(@fn, $_);}
	return \@fn;
    }
    else {
	return undef;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
