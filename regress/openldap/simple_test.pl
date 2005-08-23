#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;
use Net::LDAP;

# parameters
$| = 1;
my $dn       = "dc=fml, dc=org";
my $x        = "dc=elena, $dn";
my $address  = "fukachan\@home.fml.org";
my $address2 = "rudo\@home.fml.org";

# USAGE: new ( HOST, OPTIONS )
my $ldap = Net::LDAP->new( 'localhost' ) or warn($@);

# USAGE: bind ( DN, OPTIONS ) # bind to a directory with dn and password
my $mesg = $ldap->bind($dn, password => 'uja');
$mesg->code && warn($mesg->error);
_dump();

_add($ldap);
_modify($ldap);
_delete($ldap);

# UNBIND
$mesg = $ldap->unbind;
$mesg->code && warn($mesg->error);

exit 0;


sub _dump
{
    my ($attr) = @_;
    my $mesg   = undef;

    print "DUMPED {\n";

    # USAGE: search ( OPTIONS )
    #                 base   => DN
    #                 filter => FILTER
    #                 attrs  => [ ATTR, .. ]
    if ($attr) {
	$mesg = $ldap->search(base   => $dn,
			      filter => "(objectclass=*)",
			      );
    }
    else {
	$mesg = $ldap->search(base   => $dn,
			      filter => "(objectclass=*)",
			      );
    }
    
    $mesg->code && warn($mesg->error);
    
    for my $entry ($mesg->entries) { 
	if ($attr) {
	    my $r = $entry->get_value($attr, asref => 1) || [];
	    print "[ @$r ]\n";
	}
	else {
	    $entry->dump;
	}
    }

    print "\n}\n\n";
    print "=" x60;
    print "\n";
}


sub _add
{
    my ($ldap) = @_;

    print "* add (dn: $x)\n";
    my $mesg =
	$ldap->add($x,
		   attr => [
			    'dc'           => "elena",
			    'ou'           => "elena\@home.fml.org",
			    'fmlmember'    => $address,
			    'fmlrecipient' => $address,
			    'objectclass'  => [
					       'top',
					       'dcObject', 
					       'organizationalUnit', 
					       'fml'
					       ]
			    ]
		   );
    $mesg->code && warn($mesg->error);
    _dump("fmlmember");
}

sub _modify
{
    my ($ldap) = @_;

    print "* modify (dn: $x)\n";
    my $mesg = $ldap->modify($x, 
			     add => {
				 'fmlmember'    => $address2,
				 'fmlrecipient' => $address2,
				 }
			     );
    $mesg->code && warn($mesg->error);
    _dump("fmlmember");
}

sub _delete
{
    my ($ldap) = @_;

    print "* delete (dn: $x)\n";
    my $mesg = $ldap->modify($x, 
			     delete => {
				 'fmlmember'    => $address2,
				 'fmlrecipient' => $address2,
			     }
			     );
    $mesg->code && warn($mesg->error);
    _dump("fmlmember");


    return;
    my $mesg = $ldap->delete($x);
    $mesg->code && warn($mesg->error);
    _dump("fmlmember");
}
