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
$T->begin(2);

my $msg;

$msg  = MIME::Lite->new(From=>"me", To=>"you");
$msg->attach(Path => "boguscmd |");
$msg->attach(Data => "Hello");
$msg->attach(Path => "<path.to.missing.file");
eval { $msg->verify_data };
$T->ok($@ =~ /path\.to\.missing\.file/,
       "Did we detect a missing file?",
       Error => $@);

$msg  = MIME::Lite->new(From=>"me", To=>"you");
$msg->attach(Data => "Hello");
eval { $msg->verify_data };
$T->ok(!$@,
       "Did we detect NO missing file?",
       Error => $@);


$T->end;





