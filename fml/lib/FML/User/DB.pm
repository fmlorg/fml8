#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DB.pm,v 1.8 2004/07/23 15:59:12 fukachan Exp $
#

package FML::User::DB;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $debug $default_expire_period);
use Carp;


# debug
$debug = 0;

# XXX-TODO: $default_expire_period customizable ?
# 30 days
my $default_expire_period = 30*24*3600;


=head1 NAME

FML::User::DB - maintain user database with expiration.

=head1 SYNOPSIS

    use FML::User::DB;
    my $data = new FML::User::DB $curproc;

    # add
    $data->add($key, $value);

    # search
    $data->find($key);

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($dbargs)
# Side Effects: create object
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $dbargs) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };

    # initialize.
    my $config = $curproc->config();
    my $db_dir = $config->{ user_db_dir };
    $curproc->mkdir($db_dir, "mode=private");

    return bless $me, $type;
}


=head2 set($class, $key, $value)

add { $key => $value } info to $primary_user_db_${class}_map.

=head2 get($class, $key)

=head2 add($class, $key, $value)

same as set() above.

=cut


# Descriptions: add { $key => $value } to $primary_user_db_${class}_map.
#    Arguments: OBJ($self) STR($class) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub set
{
    my ($self, $class, $key, $value) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $debug ? $curproc->{ config } : $curproc->config();
    my $mapname = sprintf("primary_user_db_%s_map", $class);
    my $map     = $config->{ $mapname };

    if ($map) {
	if ($debug) { print STDERR "open map=$map\n";}

	use IO::Adapter;
	my $obj = new IO::Adapter $map;
	$obj->open();
	$obj->touch();
	if ($self->find($class, $key)) { # avoid duplication.
	    $obj->delete($key);
	}
	$obj->add($key, [ $value ]);
	$obj->close();
    }
    else {
	$curproc->logerror("\$map undeflined");
    }
}


# Descriptions: find the first matched entry { $key => $value } 
#               in $primary_user_db_${class}_map.
#    Arguments: OBJ($self) STR($class) STR($key)
# Side Effects: update database
# Return Value: none
sub get
{
    my ($self, $class, $key) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $debug ? $curproc->{ config } : $curproc->config();
    my $mapname = sprintf("primary_user_db_%s_map", $class);
    my $map     = $config->{ $mapname };

    if ($map) {
	if ($debug) { print STDERR "open map=$map\n";}

	use IO::Adapter;
	my $obj = new IO::Adapter $map;
	$obj->open();
	my $result = $self->find($class, $key);
	$obj->close();

	return $result;
    }
    else {
	$curproc->logerror("\$map undeflined");
    }
}


# Descriptions: add { $key => $value } to $primary_user_db_${class}_map.
#    Arguments: OBJ($self) STR($class) STR($key) STR($value)
# Side Effects: update database
# Return Value: none
sub add
{
    my ($self, $class, $key, $value) = @_;
    $self->set($class, $key, $value);
}


=head2 find($class, $key)

search value for $key in $user_db_${class}_maps.

=cut


# Descriptions: search value for $key in $user_db_${class}_maps.
#    Arguments: OBJ($self) STR($class) STR($key)
# Side Effects: update database
# Return Value: STR
sub find
{
    my ($self, $class, $key) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $mapname = sprintf("user_db_%s_maps", $class);
    my $maps    = $config->get_as_array_ref( $mapname );
    my $_key    = quotemeta($key);

    if (@$maps) {
	my $obj   = undef;
	my $value = '';

	if ($debug) { print STDERR "open maps=(@$maps)\n";}

      MAP:
	for my $map (@$maps) {
	    use IO::Adapter;
	    $obj = new IO::Adapter $map;
	    $obj->open();
	    $obj->touch();

	    # XXX FIRST MATCH. OK ?
	    $value = $obj->find($_key, {
		want           => 'key,value',
		case_sensitive => 0,
	    });
	    if ($value) {
		if ($value =~ /^$_key\s+|^$_key\s*$/) {
		    $obj->close();
		    last MAP;
		}
	    }
	    $obj->close();
	}

	# XXX-TODO: $value = "key value" ? correct ?
	return $value;
    }
    else {
	$curproc->logerror("\$map undeflined");
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    eval q{
	use FML::Process::Debug;
	use FML::Config;

	$debug = 1;

	my $cache_dir = '/tmp';
	my $class     = 'gecos',
	my $key       = 'rudo@example.com';
	my $key2      = 'fukachan@example.com';
	my $value     = time;
	my $curproc   = new FML::Process::Debug;
	my $config    = new FML::Config;
	$curproc->{ config } = $config;
	$config->set("primary_user_db_${class}_map", "$cache_dir/$class");
	$config->set("user_db_${class}_maps",        "$cache_dir/$class");

	use FML::User::DB;
	my $data = new FML::User::DB $curproc;

	print STDERR "\n? add { $key => $value }\n";
	$data->add($class, $key,  $value);
	$data->add($class, $key2, time + $$);

	print STDERR "\n? get( $key )\n";
	my ($r) = $data->get($class, $key);
	print STDERR "$r\n";

	print STDERR "\n? find( $key )\n";
	my ($r) = $data->find($class, $key);
	print STDERR "$r\n";
    };
    print STDERR $@ if $@;
}

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::User::DB appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
