#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: SendFile.pm,v 1.41 2004/07/23 13:16:35 fukachan Exp $
#

package FML::Command::SendFile;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

my $debug = 0;


=head1 NAME

FML::Command::SendFile - utility functions to send back file(s).

=head1 SYNOPSIS

For example, See L<FML::Command::User::get> and
L<FML::Command::Admin::get> on the usage detail.

   sub process
   {
       my ($self, $curproc, $command_args) = @_;
       $self->send_article($curproc, $command_args);
   }

=head1 DESCRIPTION

This module provides several utility functions to send back article(s)
and file(s) in C<$ml_home_dir>.

=head1 METHODS

=head2 send_article($curproc, $command_args)

send back articles where C<article> is a file named as /^\d+$/ in the
ml spool $spool_dir.  This is used in C<FML::Command::User> and
C<FML::Command::Admin> modules.

=cut


# Descriptions: return the number of files specified in $command_args.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: NUM
sub num_files_in_send_article_args
{
    my ($self, $curproc, $command_args) = @_;
    my $command = $command_args->{ command };
    my $count   = 0;

    # command buffer = get 1
    # command buffer = get 1,2,3
    # command buffer = get last:3
    my (@files) = split(/\s+/, $command);
    shift @files; # remove prepended "get" string.
    for my $fn (@files) {
	my $filelist = $self->_get_valid_article_list($curproc, $fn);
	if (defined $filelist) {
	    $count = $#$filelist + 1;
	}
    }

    return $count;
}


# Descriptions: send back articles.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub send_article
{
    my ($self, $curproc, $command_args) = @_;
    my $command   = $command_args->{ command };
    my $recipient = $command_args->{ _recipient } || '';
    my $config    = $curproc->config();
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $is_error  = 0;

    # command buffer = get 1
    # command buffer = get 1,2,3
    # command buffer = get last:3
    my (@files) = split(/\s+/, $command);
    shift @files; # remove get
    for my $fn (@files) {
	my $filelist = $self->_get_valid_article_list($curproc, $fn);
	if (defined $filelist) {
	    for my $filename (@$filelist) {
		use FML::Article;
		my $article  = new FML::Article $curproc;
		my $filepath = $article->filepath($filename);
		if (-f $filepath) {
		    my $rm_args = {
			type        => "message/rfc822",
			path        => $filepath,
			filename    => $filename,
			disposition => "$ml_name ML article $filename",
		    };
		    if ($recipient) { $rm_args->{ recipient } = $recipient;}

		    $curproc->log("send back article $filename");
		    $curproc->reply_message($rm_args, $rm_args);
		}
		else {
		    $curproc->reply_message_nl('command.no_such_article',
					       "no such article $filename",
					       {
						   _arg_article => $filename,
					       }
					       );
		    $curproc->logerror("no such file: $filepath");
		}
	    }
	}
	# invalid argument
	else {
	    $curproc->logerror("send_article: invalid argument $fn");
	    $is_error = 1;
	}
    }

    if ($is_error) {
	$curproc->reply_message_nl('command.get_invalid_args',
				   "invalid argument");
	croak("send_article() fails");
    }
}


# Descriptions: check the argument and expand it if needed.
#    Arguments: OBJ($self) OBJ($curproc) STR($fn)
# Side Effects: none
# Return Value: ARRAY_REF as [ $fist .. $last ]
sub _get_valid_article_list
{
    my ($self, $curproc, $fn) = @_;

    # cheap sanity
    unless (defined $fn) {
	return [];
    }

    use Mail::Message::MH;
    my $mh      = new Mail::Message::MH;
    my $last_id = $curproc->article_max_id();

    # XXX expand() validates $fn. o.k.
    # XXX we assume min_id = 1, but not correct always.
    return $mh->expand($fn, 1, $last_id);
}


=head2 send_file($curproc, $command_args)

send back file specified as C<$command_args->{ _filepath_to_send }>.

=cut


# Descriptions: send arbitrary file in $ml_home_dir.
#               XXX we permit arbitrary file for admin to get.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub send_file
{
    my ($self, $curproc, $command_args) = @_;
    my $filename  = $command_args->{ _filename_to_send };
    my $filepath  = $command_args->{ _filepath_to_send };
    my $recipient = $command_args->{ _recipient } || '';
    my $config    = $curproc->config();

    # XXX get_charset() take Accpet-Language: header field into account.
    my $charset   = $curproc->get_charset("reply_message");

    # XXX-TODO: who validate $filename and $filepath ?
    $curproc->log("send_file: $filepath");

    # template substitution: kanji code, $varname expansion et.al.
    # we prepare file to send back which has proper kanji code et.al.
    my $params = {
	src         => $filepath,
	charset_out => $charset,
    };
    my $xxxx_template = $curproc->prepare_file_to_return( $params );

    if (-f $xxxx_template) {
	my $rm_args = {
	    type        => "text/plain; charset=$charset",
	    path        => $xxxx_template,
	    filename    => $filename,
	    disposition => $filename,
	};
	if ($recipient) { $rm_args->{ recipient } = $recipient;}

	$curproc->reply_message($rm_args, $rm_args);
    }
    else {
	croak("$filepath not found\n");
    }

}


=head2 send_user_xxx_message($curproc, $command_args, $type)

Send back a help file if "help" is found in $ml_home_dir
(e.g. /var/spool/ml/elena) for backward compatibility.
Sebd back the default help message if not found.

=cut


# Descriptions: send back file file in $ml_home_dir if found.
#               return the default message if not found.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args) STR($type)
# Side Effects: put the message into the mail queue
# Return Value: none
sub send_user_xxx_message
{
    my ($self, $curproc, $command_args, $type) = @_;
    my $config = $curproc->config();

    # XXX-TODO: care for non Japanese
    # XXX-TODO: hmm, we can handle file.ja file.ja.euc file.en file.ru ?
    # if "help" is found in $ml_home_dir (e.g. /var/spool/ml/elena),
    # send it.
    if (-f $config->{ "${type}_file" }) {
	$command_args->{ _filepath_to_send } = $config->{ "${type}_file" };
	$command_args->{ _filename_to_send } = $type;
	$self->send_file($curproc, $command_args);
    }
    # if "help" is not found, use the default help message.
    else {
	$curproc->reply_message_nl("user.${type}",
				   "${type} unavailable (error).");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::SendFile first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
