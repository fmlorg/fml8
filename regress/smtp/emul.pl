#!/usr/bin/env perl
#
# $FML$
#


use strict;
use Carp;
use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);
use vars qw(%option);
use Getopt::Long;

# parse options
GetOptions(\%option, qw(recipient=s sender=s mta=s));
my $me     = 'fukachan@home.fml.org';
my $rcpt   = $option{ recipient } || $me;
my $sender = $option{ sender }    || $me;
my $mta    = $option{ mta }       || '127.0.0.1:1025';

# help
usage() unless @ARGV;
for my $file (@ARGV) { usage() if $file eq '-h';}

# main
for my $file (@ARGV) {
    send_file($file) if -f $file;
}

exit 0;


sub usage
{
    print STDERR <<"EOF";
USAGE:
    $0 [options] file(s)

	--recipient	 ADDRESS
        --sender         ADDRESS
	--mta            HOST:PORT e.g. 127.0.0.1:10025
EOF

    exit(0);
}


sub send_file
{
    my ($file) = @_;
    my $sfp = sub { print STDERR @_;};

    use Mail::Delivery;
    my $service = new Mail::Delivery {
	protocol           => 'SMTP',
	default_io_timeout => 10,
	smtp_log_function  => $sfp,
    };
    if ($service->error) { croak($service->error); return;}

    use Mail::Message;
    my $msg = Mail::Message->parse( { file => $file } ); 
      

    $service->deliver(
		      {
			  smtp_servers    => $mta,

			  smtp_sender     => $sender,
			  recipient_array => [ $rcpt ],
			  recipient_limit => 1000,

			  message         => $msg,
		      });
    if ($service->error) { croak($service->error); return;}
}

1;
