#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.12 2008/08/24 08:28:36 fukachan Exp $
#

package FML::CGI::Anonymous::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::CGI::Anonymous::DB - anonymous user database.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: assign a magic string and an identifier.
#               see FML::CGI::Skin::Anonymous::run_cgi_main()
#               for more details.
#    Arguments: OBJ($self)
# Side Effects: update PCB and database.
# Return Value: none
sub assign_id
{
    my ($self)    = @_;
    my ($curproc) = $self->{ _curproc };
    my ($config)  = $curproc->config();
    my ($pcb)     = $curproc->pcb();

    # generate a session identifier and a challenge magic string.
    use FML::String::Random;
    my $string = new FML::String::Random;
    my $magic_string = $string->magic_string();
    my $session_id   = $string->identifier($magic_string);
    $self->set_session_id($session_id);
    $self->set_magic_string($magic_string);

    # save them and the request into the temporal database => {
    #   session_id-$session_id   => $session_id,
    #   magic_string-$session_id => $magic_string.
    # };
    my $expire    = $config->as_second("anonymous_cgi_expire_limit") || 300;
    my $confirm   = $self->_db_open();
    $confirm->set($session_id, "session_id",   $session_id);
    $confirm->set($session_id, "magic_string", $magic_string);
    $confirm->set($session_id, "expire_time",  time + $expire);
}


=head1 UTILITIES

=head2 set_session_id($session_id)

save the current session_id in PCB.

=head2 get_session_id()

get the current session_id.

=head2 set_magic_string($magic_string)

save the current magic string in PCB.

=head2 get_magic_string()

get the current magic string.

=cut


# Descriptions: save session_id in PCB.
#    Arguments: OBJ($self) STR($session_id)
# Side Effects: update pcb.
# Return Value: none
sub set_session_id
{
    my ($self, $session_id) = @_;
    my ($curproc) = $self->{ _curproc };
    my ($pcb)     = $curproc->pcb();

    $pcb->set("cgi", "anonymous_session_id", $session_id);
}


# Descriptions: get the current session_id in PCB.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_session_id
{
    my ($self)    = @_;
    my ($curproc) = $self->{ _curproc };
    my ($pcb)     = $curproc->pcb();

    if (defined $pcb) {
	return $pcb->get("cgi", "anonymous_session_id");
    }
    else {
	$curproc->logerror("get_session_id: no pcb");
	return undef;
    }
}


# Descriptions: save magic string in PCB.
#    Arguments: OBJ($self) STR($magic_string)
# Side Effects: update pcb.
# Return Value: none
sub set_magic_string
{
    my ($self, $magic_string) = @_;
    my ($curproc) = $self->{ _curproc };
    my ($pcb)     = $curproc->pcb();

    $pcb->set("cgi", "magic_string", $magic_string);
}


# Descriptions: get the current magic string in PCB.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_magic_string
{
    my ($self)    = @_;
    my ($curproc) = $self->{ _curproc };
    my ($pcb)     = $curproc->pcb();

    if (defined $pcb) {
	return $pcb->get("cgi", "magic_string");
    }
    else {
	$curproc->logerror("get_magic_string: no pcb");
	return undef;
    }
}


# Descriptions: check if the request for this session_id is too old ?
#    Arguments: OBJ($self) STR($session_id)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_expired
{
    my ($self, $session_id) = @_;
    my $confirm     = $self->_db_open();
    my $expire_time = $confirm->get($session_id, "expire_time") || 0;

    return( time > $expire_time ? 1 : 0 );
}


# Descriptions: check if the $magic_string is correct for $session_id.
#    Arguments: OBJ($self) STR($session_id) STR($magic_string)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_correct_magic_string
{
    my ($self, $session_id, $magic_string) = @_;
    my $confirm         = $self->_db_open();
    my $db_session_id   = $confirm->get($session_id, "session_id");
    my $db_magic_string = $confirm->get($session_id, "magic_string");

    # case insensitive
    $magic_string    =~ tr/A-Z/a-z/;
    $db_magic_string =~ tr/A-Z/a-z/;
    if ($magic_string eq $db_magic_string) {
	return 1;
    }
    else {
	return 0;
    }
}


=head1 DATABASE OPERATIONS

private. 

DO NOT USE THESE METHODS.

=cut


# Descriptions: open the database.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub _db_open
{
    my ($self)    = @_;
    my ($curproc) = $self->{ _curproc };
    my ($config)  = $curproc->config();
    my ($pcb)     = $curproc->pcb();

    use FML::Confirm;
    my $cache_dir = $config->{ db_dir };
    my $confirm   = new FML::Confirm $curproc, {
	keyword   => "confirm",
	cache_dir => $cache_dir,
	class     => "cgi",
	address   => "dummy",
	buffer    => "dummy",
    };
    return $confirm;
}


# Descriptions: close the database (dummy).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _db_close
{
    my ($self) = @_;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Anonymous::DB appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
