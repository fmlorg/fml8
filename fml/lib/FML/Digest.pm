#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Digest.pm,v 1.5 2002/12/22 03:39:43 fukachan Exp $
#

package FML::Digest;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

#
# XXX-TODO: Currently, fml 8 digest has no granuality like fml 4.
#

=head1 NAME

FML::Digest - create digest, a subset of articles.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ _curproc } = $curproc;
    return bless $me, $type;
}


=head1 GIANT LOCK VERSION of DIGEST

=head2 id()

same as get_digest_id().

=head2 get_digest_id()

return the last article id sent back as digest.

=head2 set_digest_id()

set the last article id sent back as digest.

=cut


# Descriptions: return the last article id sent back as digest.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub id
{
    my ($self) = @_;
    $self->get_digest_id();
}


# Descriptions: return the last article id sent back as digest.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_digest_id
{
    my ($self) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ digest_sequence_file };

    return $self->_get_id($seq_file);
}


# Descriptions: return the last article id sent back as digest
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_article_id
{
    my ($self) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ article_sequence_file };

    return $self->_get_id($seq_file);
}


# Descriptions: return the last article id sent back as digest
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub _get_id
{
    my ($self, $seq_file) = @_;

    # XXX-TODO: we should enhance IO::Adapter module to handle
    # XXX-TODO: sequential number.
    use File::Sequence;

    # XXX-TODO: defined() check for $sfh.
    if (-f $seq_file) {
	my $sfh = new File::Sequence { sequence_file => $seq_file };
	my $id  = $sfh->get_id();
	if ($sfh->error) { LogError( $sfh->error ); }

	return $id;
    }
    else {
	Log("$seq_file not found") if 0;

	# XXX-TODO: defined() check for $sfh.
	my $sfh = new File::Sequence { sequence_file => $seq_file };
	my $id  = $sfh->increment_id();
	if ($sfh->error) { LogError( $sfh->error ); }

	return 1;
    }
}


# Descriptions: return the last article id sent back as digest.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: NUM
sub set_digest_id
{
    my ($self, $id) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->{ config };
    my $seq_file = $config->{ digest_sequence_file };

    # XXX-TODO: we should enhance IO::Adapter module to handle
    # XXX-TODO: sequential number.
    # XXX-TODO: defined() check for $sfh.
    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    $sfh->set_id($id);
    if ($sfh->error) { LogError( $sfh->error ); }

    return $id;
}


# Descriptions: insert articles sent as digest into reply message queue.
#    Arguments: OBJ($self) HASH_REF($optargs)
# Side Effects: update reply messages chain on memory
# Return Value: none
sub create_multipart_message
{
    my ($self, $optargs) = @_;
    my $range     = $optargs->{ range };
    my $curproc   = $self->{ _curproc };
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };
    my $ml_addr   = $config->{ address_for_post };
    my $charset   = $config->{ template_file_charset };
    my $seq_file  = $config->{ digest_sequence_file };
    my $rcptmaps  = $config->get_as_array_ref('digest_recipient_maps');
    my $count_ok  = 0;
    my $count_err = 0;
    my $msgopts   = {
	recipient_maps => $rcptmaps,
	header         => {
	    'subject'  => "$ml_name ML digest $range",
	    'to'       => $ml_addr,
	    'reply-to' => $ml_addr,
	}
    };

    Log("send back articles range=$range");

    my $filelist = $self->_expand_range($range);
    for my $filename (@$filelist) {
	use FML::Article;
	my $article  = new FML::Article $curproc;
	my $filepath = $article->filepath($filename);
	if (-f $filepath) {
	    $curproc->reply_message( {
		type        => "message/rfc822; charset=$charset",
		path        => $filepath,
		filename    => $filename,
		disposition => "$ml_name ML article $filename",
	    }, $msgopts);
	    $count_ok++;
	}
	else {
	    Log("no such file: $filepath");
	    $count_err++;
	}
    }

    Log("eat articles ok=$count_ok error=$count_err");
}


# Descriptions: eat "10-20", return file list as \[10 11 ... 20].
#    Arguments: OBJ($self) STR($fn)
# Side Effects: none
# Return Value: ARRAY_REF
sub _expand_range
{
    my ($self, $fn) = @_;

    use Mail::Message::MH;
    my $mh = new Mail::Message::MH;

    if ($fn =~ /(\d+)\-(\d+)/) {
	return $mh->expand($fn, 1, $2);
    }
    else {
	return [];
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $obj = new FML::Digest;
    for (@ARGV) {
	my $ra = $obj->_expand_range($_);
	print join(" ", @$ra), "\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Digest appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
