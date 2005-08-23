#-*- perl -*-
#
#  Copyright (C) 2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

package IO::Adapter::LDAP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Net::LDAP;

=head1 NAME

IO::Adapter::LDAP - abstracted IO interface for LDAP.

=head1 SYNOPSIS

   use IO::Adapter;
   my $obj = new IO::Adapter "ldap:fml", $map_params;
   $obj->open();
   $obj->add( 'rudo@nuinui.net' );
   $obj->close();

=head1 DESCRIPTION

This module provides LDAP interface.

=head1 METHODS

=head2 configure($me, $args)

IO::Adapter::LDAP specific configuration loader.

=cut


# Descriptions: initialize LDAP specific configuration.
#    Arguments: OBJ($self) HASH_REF($me) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub configure
{
    my ($self, $me, $args) = @_;
    my $map    = $me->{ _map };       # e.g. "ldap:toymodel"
    my $config = $args->{ "[$map]" };

    # save map specific configuration
    $me->{ _config } = $config;

    # module
    use Net::LDAP;
}


# Descriptions: open connection to LDAP server (init and bind).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: ldap_bind()
# Return Value: OBJ
sub open
{
    my ($self, $args) = @_;
    my $config   = $self->{ _config }         || {};
    my $servers  = $config->{ ldap_servers }  || '';
    my $password = $config->{ ldap_password } || undef;
    my $root     = $config->{ ldap_bind_dn }  || undef;

    if (defined $servers) {
	my $last_error = '';

	my (@servers) = split(/\s+/, $servers);
	for my $host (@servers) {
	    my $ldap = Net::LDAP->new( $host ) or $self->error_set($@);
	    if (defined $ldap) {
		$self->{ _ldap } = $ldap; 
		my $mesg = $ldap->bind($root, password => $password);
		$mesg->code && $self->error_set($mesg->error);
		return $mesg;
	    }
	    else {
		$last_error = "undefined";
	    }
	}

	if ($last_error) {
	    $self->error_set($last_error);
	    return undef;
	}
    }
    else {
	$self->error_set("host undefined");
	return undef;
    }
}


# Descriptions: unbind.
#    Arguments: OBJ($self)
# Side Effects: ldap_unbind().
# Return Value: none
sub close
{
    my ($self) = @_;
    my $ldap   = $self->{ _ldap };

    # reset row information
    undef $self->{ _row_pos };
    undef $self->{ _row_max };
    undef $self->{ _res };

    if (defined $ldap) {
	$ldap->unbind();
    }
}


=head2 add($address, ... )

add (append) $address to this map.

=cut

# Descriptions: add $addr into map.
#    Arguments: OBJ($self) STR($addr) VARARGS($argv)
# Side Effects: update map
# Return Value: same as close()
sub add
{
    my ($self, $addr, $argv) = @_;
    my $ldap   = $self->{ _ldap }          || undef;
    my $config = $self->{ _config }        || {};
    my $dn     = $config->{ ldap_base_dn } || undef;

    # LDIF like form to add.
    my $query  = $config->{ ldap_query_add_as_ldif } || undef;

    # convert LDIF like form to HASH_REF and modify $dn.
    my $hash = $self->_ldif_query_to_hash_ref($query, $addr, $argv);
    my $mesg = $ldap->modify($dn, add => $hash);
    $mesg->code && $self->error_set($mesg->error);
}


# Descriptions: add $addr into map.
#    Arguments: OBJ($self) STR($addr) VARARGS($argv)
# Side Effects: update map
# Return Value: same as close()
sub delete
{
    my ($self, $addr, $argv) = @_;
    my $ldap   = $self->{ _ldap }          || undef;
    my $config = $self->{ _config }        || {};
    my $dn     = $config->{ ldap_base_dn } || undef;

    # LDIF like form to delete.
    my $query  = $config->{ ldap_query_delete_as_ldif } || undef;

    # convert LDIF like form to HASH_REF and modify $dn.
    my $hash = $self->_ldif_query_to_hash_ref($query, $addr, $argv);
    my $mesg = $ldap->modify($dn, delete => $hash);
    $mesg->code && $self->error_set($mesg->error);
}


# Descriptions: convert query LDIF like string to HASH_REF form.
#    Arguments: OBJ($self) STR($query) STR($addr) VARARGS($argv)
# Side Effects: none
# Return Value: HASH_REF
sub _ldif_query_to_hash_ref
{
    my ($self, $query, $addr, $argv) = @_;
    my $r = {};

    # XXX-TODO: &address hard-coded.
    $query =~ s/\&address/$addr/g;
    for my $kv (split(/[\s,]+/, $query)) {
	my ($k, $v) = split(/:/, $kv);
	$r->{ $k } = $v;
    }

    return $r;
}


=head2 getline()

return the next address.

=head2 get_next_key()

return the next key.

=cut


# Descriptions: return a table row as a string sequentially.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub getline
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'getline');
}


# Descriptions: return (key, values, ... ) as ARRAY_REF.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_key_values_as_array_ref
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'key,value');
}


# Descriptions: return the primary key in the table sequentially.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR
sub get_next_key
{
    my ($self, $args) = @_;
    $self->_get_data_from_cache($args, 'key');
}


# Descriptions: get data from cache obtained from LDAP server.
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: none
# Return Value: STR
sub _get_data_from_cache
{
    my ($self, $args, $mode) = @_;

    # For the first time, get the data and cache it for the later use.
    # So, $self->{ _res } is initialized by _fetch_all().
    unless ($self->{ _res }) {
	# reset row information
	undef $self->{ _row_pos };
	undef $self->{ _row_max };

	my $a = $self->_fetch_all($args, 'get_next_key');
	$self->{ _res }     = $a;         # ARRAY_REF
	$self->{ _row_pos } = 0;
	$self->{ _row_max } = $#$a + 1;
    }

    if ($self->{ _res }) {
	my $pos   = $self->{ _row_pos }++;
	my (@row) = $self->{ _res }->[ $pos ];

	if ($mode eq 'key') {
	    return $row[0];
	}
	elsif ($mode eq 'value') {
	    shift @row;
	    return \@row;
	}
	elsif ($mode eq 'key,value') {
	    return \@row;
	}
	elsif ($mode eq 'getline') {
	    return join(" ", @row);
	}
	else {
	    $self->error_set("LDAP: invalid option");
	    return undef;
	}
    }
    else {
	$self->error_set( "no result" );
	return undef;
    }
}


# Descriptions: get one entry from LDAP server.
#    Arguments: OBJ($self) HASH_REF($args) STR($mode)
# Side Effects: update cache on memory.
# Return Value: ARRAY_REF
sub _fetch_all
{
    my ($self, $args, $mode) = @_;
    my $ldap   = $self->{ _ldap } || undef;
    my $config = $self->{ _config };
    my $root   = $config->{ ldap_bind_dn };
    my $attr   = $config->{ "ldap_query_${mode}_result_attribute" };
    my $filter = $config->{ "ldap_query_${mode}_search_filter" };

    my $mesg = $ldap->search(base   => $root, 
			     filter => $filter,
			     attrs  => [ $attr ] );
    $mesg->code && $self->error_set($mesg->error);    

    my $a = [];
    for my $entry ($mesg->entries) { 
	my $r = $entry->get_value($attr, asref => 1) || [];
	push(@$a, @$r);
    }

    return $a;
}



# Descriptions: search, md = map dependent.
#    Arguments: OBJ($self) STR($regexp) HASH_REF($args)
# Side Effects: update cache on memory.
# Return Value: STR or ARRAY_REF
sub md_find
{
    my ($self, $regexp, $args) = @_;
    my $case_sensitive = $args->{ case_sensitive } ? 1 : 0;
    my $want           = $args->{ want } || 'key,value';
    my $show_all       = $args->{ all } ? 1 : 0;
    my (@buf, $x);

    my $res = $self->_fetch_all($args, 'find'); # ARRAY_REF
  RES:
    for my $key (@$res) {
	$x = $key;

	if ($show_all) {
	    if ($case_sensitive) {
		push(@buf, $x) if $x =~ /$regexp/;
	    }
	    else {
		push(@buf, $x) if $x =~ /$regexp/i;
	    }
	}
	else {
	    if ($case_sensitive) {
		last RES if $x =~ /$regexp/;
	    }
	    else {
		last RES if $x =~ /$regexp/i;
	    }
	}
    }

    # XXX-TODO: $x = "STR STR STR" ? should be $x => [] ?
    return( $show_all ? \@buf : $x );
}


=head2 setpos($pos)

set position in returnd cache.

=cut


# Descriptions: set position in returnd cache.
#    Arguments: OBJ($self) NUM($pos)
# Side Effects: none
# Return Value: none
sub setpos
{
    my ($self, $pos) = @_;
    my $i = 0;

    # requested position $pos is later here
    if ($pos > $self->{ _row_pos }) {
	$i = $pos - $self->{ _row_pos } - 1;
    }
    else {
	# hmm, rollback() is not supported.
	# we need to restart this session.
	my $args = $self->{ _args };
	$self->close($args);
	$self->open($args);
	$i = $pos - 1;
    }

    # discard
    while ($i-- > 0) { $self->get_next_key();}
}


=head2 getpos()

get position in returnd cache.

=cut


# Descriptions: get position in returnd cache.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub getpos
{
    my ($self) = @_;

    return $self->{ _row_pos };
}


=head2 eof()

check if EOF or not?

=cut


# Descriptions: check if EOF or not?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub eof
{
    my ($self) = @_;

    # XXX-TODO: correct ?
    return( $self->{ _row_pos } < $self->{ _row_max } ? 0 : 1 );
}


=head1 SEE ALSO

L<Net::LDAP>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::LDAP first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
