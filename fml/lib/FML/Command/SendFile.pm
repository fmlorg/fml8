#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: SendFile.pm,v 1.1 2001/10/13 12:17:49 fukachan Exp $
#

package FML::Command::SendFile;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Command::SendFile - utility functions to send back specified file

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=head2 C<send_article($curproc, $optargs)>

send back articles.

used in 
C<FML::Command::User>
and
C<FML::Command::Admin>
modules.

=cut

# Descriptions: send back articles
#    Arguments: $self $curproc $optargs
# Side Effects: none
# Return Value: none
sub send_article
{
    my ($self, $curproc, $optargs) = @_;
    my $command   = $optargs->{ command };
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $charset   = $config->{ template_file_charset };

    # command buffer = get 1
    # command buffer = get 1,2,3
    # command buffer = get last:3
    my (@files) = split(/\s+/, $command);
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


=head2 C<send_file($curproc, $optargs)>

send back file specified as C<$optargs->{ _file_to_send }>.

=cut

# Descriptions: 
#    Arguments: $self $curproc $optargs
# Side Effects: none
# Return Value: none
sub send_file
{
    my ($self, $curproc, $optargs) = @_;
    my $what_file = $optargs->{ _file_to_send };
    my $config    = $curproc->{ config };
    my $charset   = $config->{ reply_message_charset };

    # template substitution: kanji code, $varname expansion et. al.
    my $params = {
	src         => $what_file,
	charset_out => $charset,
    };
    my $xxxx_template = $curproc->prepare_file_to_return( $params ); 

    if (-f $xxxx_template) {
	$curproc->reply_message( {
	    type        => "text/plain; charset=$charset",
	    path        => $xxxx_template,
	    filename    => "help",
	    disposition => "help",
	});
    }
    else {
	croak("$what_file not found\n");
    }

}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::SendFile appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
