#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: SendFile.pm,v 1.6 2001/12/23 09:20:42 fukachan Exp $
#

package FML::Command::SendFile;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Command::SendFile - utility functions to send back file(s)

=head1 SYNOPSIS

For example, See L<FML::Command::User::get> and
L<FML::Command::Admin::get>..

   sub process
   {
       my ($self, $curproc, $command_args) = @_;
       $self->send_article($curproc, $command_args);
   }

=head1 DESCRIPTION

This module provides several utility functions to send back article
and file in C<$ml_home_dir>.

=head1 METHODS

=head2 C<send_article($curproc, $command_args)>

send back articles.  This is used in C<FML::Command::User> and
C<FML::Command::Admin> modules.

=cut


# Descriptions: send back articles
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub send_article
{
    my ($self, $curproc, $command_args) = @_;
    my $command   = $command_args->{ command };
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $charset   = $config->{ template_file_charset };
    my $is_error  = 0;

    # command buffer = get 1
    # command buffer = get 1,2,3
    # command buffer = get last:3
    my (@files) = split(/\s+/, $command);
    shift @files; # remove get
    for my $fn (@files) {
	my $filelist = $self->_is_valid_argument($curproc, $fn);
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
	# invalid argument
	else {
	    Log("send_article: invalid target: $fn");
	    $is_error = 1;
	}
    }

    if ($is_error) {
	$curproc->reply_message_nl('command.get.invalid.args',
				   "invalid argument");
	croak("send_article() fails");
    }
}


# Descriptions: check the argument and expand it if needed
#    Arguments: OBJ($self) OBJ($curproc) STR($fn)
# Side Effects: none
# Return Value: HASH_ARRAY as [ $fist .. $last ]
sub _is_valid_argument
{
    my ($self, $curproc, $fn) = @_;

    use File::Sequence;
    my $config   = $curproc->{ config };
    my $file     = $config->{ sequence_file };
    my $sequence = new File::Sequence { sequence_file => $file };

    if ($fn =~ /^\d+$/) {
	return [ $fn ];
    }
    elsif ($fn =~ /^[\d,]+$/) {
	my (@fn) = split(/,/, $fn);
	return \@fn;
    }
    elsif ($fn =~ /^(\d+)\-(\d+)$/) {
	my ($first, $last) = ($1, $2);
	return _expand_range($first, $last);
    }
    elsif ($fn eq 'first') {
	return [ 1 ];
    }
    elsif ($fn eq 'last' || $fn eq 'cur') {
	my $last_id = $sequence->get_id();
	return [ $last_id ];
    }
    elsif ($fn =~ /^first:(\d+)$/) {
	my $range = $1;
        return _expand_range(1, 1 + $range);
    }
    elsif ($fn =~ /^last:(\d+)$/) {
	my $range   = $1;
	my $last_id = $sequence->get_id();
        return _expand_range($last_id - $range, $last_id);
    }
    else {
	return undef;
    }
}


# Descriptions: make an array from $fist to $last number
#    Arguments: NUM($first_number) NUM($last_number)
# Side Effects: none
# Return Value: HASH_ARRAY as [ $first .. $last ]
sub _expand_range
{
    my ($first, $last) = @_;

    my (@fn);
    for ($first .. $last) { push(@fn, $_);}
    return \@fn;
}


=head2 C<send_file($curproc, $command_args)>

send back file specified as C<$command_args->{ _file_to_send }>.

=cut


# Descriptions: send arbitrary file in $ml_home_dir.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub send_file
{
    my ($self, $curproc, $command_args) = @_;
    my $what_file = $command_args->{ _file_to_send };
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
