#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: MessageID.pm,v 1.1 2001/04/15 05:01:58 fukachan Exp $
#

package FML::Header::MessageID;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $Counter);
use Carp;

=head1 NAME

FML::Header::MessageID - manupulate message-id 

=head1 SYNOPSIS

    use FML::Header::MessageID;
    my $xobj = new FML::Header::MessageID;
    my $obj  = $xobj->open_cache( {
        directory => $directory,
    });

    if (defined $obj) {
           my $fh = $obj->open;

           # we can tind the $message_id in the past message-id cache ?
           my $dup = $obj->find($message_id);
           print STDERR "error: message-id duplicated\nq" if $dup;

           # save the current id
           print $fh $message_id, "\t", $message_id, "\n";

           $fh->close;
       }
   }

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new($args)>

usual constructor.

=cut


use File::CacheDir;
@ISA = qw(File::CacheDir);


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 C<open_cache($args)>

open cache and return C<File::CacheDir> object.

=cut

sub open_cache
{
    my ($self, $args) = @_;
    my $dir  = $args->{ 'directory' };
    my $mode = 'temporal';
    my $days = 14;

    if ($dir) {
	my $obj = new File::CacheDir {
	    directory  => $dir, 
	    cache_type => $mode,
	    expires_in => $days,
	};

	$self->{ _obj } = $obj;
	return $obj;
    }

    undef;
}


=head2 C<get($key)>

=head2 C<set($key, $value)>

=cut


sub get
{
    my ($self, $key) = @_;
    my $obj = $self->{ _obj };

    if (defined $obj) {
	return $obj->find($key);
    }

    undef;
}


sub set
{
    my ($self, $key, $value) = @_;
    my $obj = $self->{ _obj };

    if (defined $obj) {
	$obj->set($key, $value);
    }

    undef;
}


=head2 C<gen_id($curproc, $args)>

return a new message-id.

=cut


sub gen_id
{
    my ($self, $curproc, $args) = @_;
    my $config = $curproc->{ config };

    $Counter++;
    time.".$$.$Counter\@" . $config->{ address_for_post };
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Header::MessageID appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
