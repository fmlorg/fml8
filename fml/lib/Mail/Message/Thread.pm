#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Thread.pm,v 1.1 2003/07/20 04:58:29 fukachan Exp $
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

    $db->analyze($msg);
}


=head1 TODO

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Message::Thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

This class is renamed from C<Mail::HTML::Lite> 1.40 (2001-2002).

=cut


1;
