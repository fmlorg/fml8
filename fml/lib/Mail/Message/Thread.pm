#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Thread.pm,v 1.7 2005/08/25 13:13:35 fukachan Exp $
#

package Mail::Message::Thread;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

=head1 NAME

Mail::Message::Thread - Thread interface

=head1 SYNOPSIS

  ... lock by something ...

  ... unlock by something ...

This module itself provides no lock function.
please use flock() built in perl or CPAN lock modules for it.

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

initialize DB (udb) interface.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    my $ndb = _init_db($me, $args);
    $me->{ _ndb } = $ndb;

    return bless $me, $type;
}


# Descriptions: initialize Mail::Message::DB object.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: DB object created.
# Return Value: OBJ
sub _init_db
{
    my ($self, $args) = @_;
    my $db_type = $args->{ db_type }     || 'AnyDBM_File';
    my $db_base = $args->{ db_base_dir } || croak("specify db_base_dir\n");
    my $db_name = $args->{ db_name }     || croak("specify db_name\n");
    my $id      = $args->{ id }          || 0;

    use File::Spec;
    my $db_dir  = File::Spec->catfile($db_base, $db_name);
    unless (-d $db_base) { mkdir($db_base, 0755);}
    unless (-d $db_dir)  { mkdir($db_dir,  0755);}

    my $_db_args = {
	db_module       => $db_type, # AnyDBM_File
	db_base_dir     => $db_dir,  # /var/spool/ml/@udb@/elena
	db_name         => $db_name, # elena

	# old db_dir in non UDB age: ~fml/public_html/.../elena/
	old_db_base_dir => $args->{ output_dir },
    };

    # Firstly, prepare db object.
    use Mail::Message::DB;
    my $db = new Mail::Message::DB $_db_args;
    $db->set_key($id) if $id;

    return $db;
}


=head2 db()

return database object.

=head2 analyze($msg)

top level dispatcher to run thread analyzer.

=cut


# Descriptions: get database object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub db
{
    my ($self) = @_;
    return( $self->{ _ndb } || undef );
}


# Descriptions: top level dispatcher to run thread analyzer.
#    Arguments: OBJ($self) OBJ($msg) NUM($id)
# Side Effects: update database
# Return Value: none
sub analyze
{
    my ($self, $msg, $id) = @_;
    my $db = $self->db();

    $db->add($msg);
}


=head2 get_thread_data($thread_args)

return thread data as HASH_REF.

=cut


# Descriptions: top level dispatcher to get thread data.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: update database
# Return Value: HASH_REF
sub get_thread_data
{
    my ($self, $thread_args) = @_;
    my $db = $self->db();

    return $db->get_thread_data($thread_args);
}


=head2 get_thread_member_as_array_ref($head_id)

return id list within the thread specified by $head_id as ARRAY_REF
e.g.a [ $head_id, id1, id2, id3, ... ].

=cut

# Descriptions: return id list within the thread specified by $head_id
#               as ARRAY_REF.
#    Arguments: OBJ($self) NUM($head_id)
# Side Effects: update database
# Return Value: none
sub get_thread_member_as_array_ref
{
    my ($self, $head_id) = @_;
    my $db = $self->db();

    return $db->get_as_array_ref('ref_key_list', $head_id);
}


=head1 UTILITY

=cut


# Descriptions: set thread status.
#    Arguments: OBJ($self) NUM($head_id) STR($status)
# Side Effects: update UDB
# Return Value: none
sub set_thread_status
{
    my ($self, $head_id, $status) = @_;
    my $db = $self->db();

    $db->set('thread_status', $head_id, $status);
}


# Descriptions: get thread status.
#    Arguments: OBJ($self) NUM($head_id)
# Side Effects: none
# Return Value: STR
sub get_thread_status
{
    my ($self, $head_id) = @_;
    my $db = $self->db();

    $db->get('thread_status', $head_id);
}


# Descriptions: set article status.
#    Arguments: OBJ($self) NUM($id) STR($status)
# Side Effects: update UDB
# Return Value: none
sub set_article_status
{
    my ($self, $id, $status) = @_;
    my $db = $self->db();

    $db->set('article_status', $id, $status);
}


# Descriptions: get article status.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR
sub get_article_status
{
    my ($self, $id) = @_;
    my $db = $self->db();

    $db->get('article_status', $id);
}


# Descriptions: set article summary.
#    Arguments: OBJ($self) NUM($id) STR($summary)
# Side Effects: update UDB
# Return Value: none
sub set_article_summary
{
    my ($self, $id, $summary) = @_;
    my $db = $self->db();

    $db->set('article_summary', $id, $summary);
}


# Descriptions: get article summary.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR
sub get_article_summary
{
    my ($self, $id) = @_;
    my $db = $self->db();

    $db->get('article_summary', $id);
}


=head1 TODO

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
