#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Digest.pm,v 1.19 2004/04/23 04:10:27 fukachan Exp $
#

package FML::Digest;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

#
# XXX-TODO: Currently, fml 8 digest has no granuality like fml 4.
#

=head1 NAME

FML::Digest - create digest, a subset of articles.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: $self->{ _curproc } = $curproc;
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: get lock channel name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_lock_channel_name
{
    my ($self) = @_;

    # XXX_LOCK_CHANNEL: digest_sequence
    return 'digest_sequence';
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
    my ($self)   = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $seq_file = $config->{ digest_sequence_file };

    return $self->_get_id($seq_file);
}


# Descriptions: return the last article id sent back as digest
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_article_id
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };

    return $curproc->article_max_id();
}


# Descriptions: return the last sequence id sent back as digest.
#    Arguments: OBJ($self) STR($seq_file)
# Side Effects: none
# Return Value: NUM
sub _get_id
{
    my ($self, $seq_file) = @_;
    my $curproc = $self->{ _curproc };
    my $channel = $self->get_lock_channel_name();
    my $id      = 1; # XXX return default value if something fails.

    $curproc->lock($channel);

    if (-f $seq_file) {
	my $map = sprintf("file:%s", $seq_file);

	use FML::Article::Sequence;
	my $seq = new FML::Article::Sequence $curproc;
	$id = $seq->get_number_from_map($map) || 0;
    }

    $curproc->unlock($channel);

    # XXX return default value if something fails.
    return $id;
}


# Descriptions: set digest id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: NUM
sub set_digest_id
{
    my ($self, $id) = @_;
    my $curproc  = $self->{ _curproc };
    my $config   = $curproc->config();
    my $seq_file = $config->{ digest_sequence_file };
    my $map      = sprintf("file:%s", $seq_file);
    my $channel  = $self->get_lock_channel_name();

    $curproc->lock($channel);

    use IO::Adapter;
    my $io = new IO::Adapter $map;
    $io->sequence_replace($id);
    if ($io->error()) {
	$curproc->logerror( $io->error() );
    }

    $curproc->unlock($channel);

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
    my $config    = $curproc->config();
    my $ml_name   = $config->{ ml_name };
    my $ml_addr   = $config->{ article_post_address };
    my $seq_file  = $config->{ digest_sequence_file };
    my $rcptmaps  = $config->get_as_array_ref('digest_recipient_maps');
    my $count_ok  = 0;
    my $count_err = 0;

    # XXX-TODO: subject should be configurable.
    my $msgopts   = {
	recipient_maps => $rcptmaps,
	header         => {
	    'subject'  => "$ml_name ML digest $range",
	    'to'       => $ml_addr,
	    'reply-to' => $ml_addr,
	}
    };

    $curproc->log("send back articles range=$range");

    my $filelist = $self->_expand_range($range);
    for my $filename (@$filelist) {
	use FML::Article;
	my $article  = new FML::Article $curproc;
	my $filepath = $article->filepath($filename);
	if (-f $filepath) {
	    # XXX-TODO: disposition should be configurable.
	    $curproc->reply_message( {
		type        => "message/rfc822",
		path        => $filepath,
		filename    => $filename,
		disposition => "$ml_name ML article $filename",
	    }, $msgopts);
	    $count_ok++;
	}
	else {
	    $curproc->log("no such file: $filepath");
	    $count_err++;
	}
    }

    $curproc->log("eat articles ok=$count_ok error=$count_err");
}


# Descriptions: eat "10-20", return file list as \( 10 11 ... 20 ).
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

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Digest appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
