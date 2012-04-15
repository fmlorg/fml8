# $Id: /mirror/monster/Email-Find/trunk/t/addr-spec.t 702 2002-01-13T12:52:05.000000Z miyagawa  $
use strict;
use Test::More tests => 2;

BEGIN { use_ok 'Email::Find::addrspec' }
ok defined $Addr_spec_re;

