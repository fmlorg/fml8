#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use ExtUtils::TBone;
use Utils;

# Make a tester... here are 3 different alternatives:
my $T = typical ExtUtils::TBone;                 # standard log
$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

# Begin testing:
$T->begin(14);

# New:
my $from = 'me@myhost.com';
my $me = MIME::Lite->build(From    => $from,
			   To      => 'you@yourhost.com',
			   Subject => 'Me!',
			   Type    => 'text/plain',
			   Data    => "Hello!\n");

# Test "get" [4 tests]:
$T->ok_eq(scalar($me->get('From')),
	  $from,
	  "get: simple get of 'From'");
$T->ok_eq($me->get('From',0),
	  $from,
	  "get: indexed get(0) of 'From' gets first");
$T->ok_eq($me->get('From',-1),
	  $from,
	  "get: indexed get(-1) of 'From' gets first");
$T->ok_eq($me->get('FROM',0),
	  $from,
	  "get: indexed get(0) of 'FROM' gets From");

# Test "add": add one, then two [6 tests]:
$me->add('Received', 'sined');
$me->add('Received', ['seeled', 'delivered']);
$T->ok_eq(scalar($me->get('Received')),
	  'sined',
	  "add: scalar context get of 'Received'");
$T->ok_eq($me->get('Received',0),
	  'sined',
	  "add: scalar context get(0) of 'Received'");
$T->ok_eq($me->get('Received',1),
	  'seeled',
	  "add: scalar context get(1) of 'Received'");
$T->ok_eq($me->get('Received',2),
	  'delivered',
	  "add: scalar context get(2) of 'Received'");
$T->ok_eq($me->get('Received',-1),
	  'delivered',
	  "add: scalar context get(-1) of 'Received'");
$T->ok_eq(($me->get('Received'))[1],
	  'seeled',
	  "add: array context get of 'Received', indexed to 1'th elem");

# Test "delete" [1 test]:
$me->delete('RECEIVED');
$T->ok(!defined($me->get('Received')),
       "delete: deletion of RECEIVED worked");

# Test "replace" [1 test]:
$me->replace('subject', "Hellooooo, nurse!");
$T->ok_eq($me->get('SUBJECT'), 
	  "Hellooooo, nurse!",
	  "replace: replace of SUBJECT worked");

# Test "attr" [2 tests]:
$me->attr('content-type.charset', 'US-ASCII');
$T->ok_eq($me->attr('content-type.charset'),
	  'US-ASCII',
	  "attr: replace of charset worked");
#
my ($ct) = map {($_->[0] eq 'content-type') ? $_->[1] : ()} @{$me->fields};
$T->ok_eq($ct,
	  'text/plain; charset="US-ASCII"',
	  "attr: replace of charset worked on whole line");


$T->end;





