#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use ExtUtils::TBone;
use Utils;

# Make a tester... here are 3 different alternatives:
my $T = typical ExtUtils::TBone;                 # standard log
$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

# Pairs:
my @pairs = 
    (
     ['  me@myhost.com      ',
      1,
      '<me@myhost.com>'],

     ['  mylogin      ',
      1,
      '<mylogin>'],

     ['   "Me, Jr." <  me@myhost.com >  ',
      1,
      '<me@myhost.com>'],

     ['  Me   <me@myhost.com>',
      1,
      '<me@myhost.com>'],

     ['"Me, Jr." <me@myhost.com>',
      1,
      '<me@myhost.com>'],

     ['"Me@somewhere.com, Jr." <me@myhost.com>',
      1,
      '<me@myhost.com>'],

     ['me@myhost.com,you@yourhost.com',
      2,
      '<me@myhost.com> <you@yourhost.com>'],

     ['"Me" <me@myhost.com>, "You"<you@yourhost.com>',
      2,
      '<me@myhost.com> <you@yourhost.com>'],

     ['"Me" <me@myhost.com>, you@yourhost.com, "And also" <she@herhost.com>',
      3,
      '<me@myhost.com> <you@yourhost.com> <she@herhost.com>'],

     ['"Me" <me@myhost.com>, mylogin  ,yourlogin  , She <she@herhost.com>',
      4,
      '<me@myhost.com> <mylogin> <yourlogin> <she@herhost.com>']
     );
      

# Abort?
if (eval "require Mail::Address") {
    $T->begin(1);
    $T->ok(1, "we have and trust Mail::Address");
    $T->end;
    exit 0;
}  

# Begin testing:
$T->begin(2 * @pairs);

# New:
foreach my $pair (@pairs) {
    my ($to, $count, $result) = @$pair;
    my @addrs = MIME::Lite::extract_addrs($to);

    $T->ok_eqnum(int(@addrs), $count,
                 "compare count",
		 In => $to);
    $T->ok_eq(join(' ', map {"<$_>"} @addrs),
	      $result,
	      "compare result",
	      In => $to);
}

$T->end;





