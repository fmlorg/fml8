#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Bounce.pm,v 1.12 2001/07/30 23:09:04 fukachan Exp $
#

package Mail::Bounce;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

=head1 NAME

Mail::Bounce - analye error messages

=head1 SYNOPSIS

    use Mail::Message;
    my $msg = Mail::Message->parse( { fd => \*STDIN } );

    use Mail::Bounce;
    my $bouncer = new Mail::Bounce;
    $bouncer->analyze( $msg );

    # show results
    for my $a ( $bouncer->address_list ) {
	print "address: $a\n";

	print " status: ";
	print $bouncer->status( $a );
	print "\n";

	print " reason: ";
	print $bouncer->reason( $a );
	print "\n";
	print "\n";
    }


=head1 DESCRIPTION

try to analyze the given error message, which is a Mail::Message
object.

For non DSN pattern,
try to analyze it by using modules in C<Mail::Bounce::> 
which can recognize MTA specific and domian specific patterns.

For example,

  Mail::Bounce
      
                $msg
              --------> Mail::Bounce::DSN::analyze()
              <--------
               $result

returned C<$result> provides the following information:

    $result = {
	address1 => {
	    Original-Recipient => 'rfc822; addr',
	    Final-Recipient    => 'rfc822; addr',
	    Diagnostic-Code    => 'reason ...',
	    Action             => 'failed',
	    Status             => '4.0.0',
	    Reporting-MTA      => 'dns; server.fml.org',
	    Received-From-MTA  => 'DNS; server.fml.org',
	    hints              => ... which module matches ...,
	},

	address2 => {
	    ... snip ...
	},

	...
    };


=head1 METHODS

=head2 C<new()>

standard new() method.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 C<analyze($msg)>

C<$msg> is a C<Mail::Message> object.  
This routine is a top level switch which provides the entrance 
for C<Mail::Bounce::> modules, for example, C<Mail::Bounce::DSN>.

C<Mail::Bounce::$model::analyze( \$msg, \$result )> 
method in each module is the actual model specific analyzer.
C<$result> has an answer of analyze if the error message pattern is
already known.

=cut

sub analyze
{
    my ($self, $msg) = @_;
    my $result = {};

    if ($debug) {
	my $h = $msg->get_data_type_list;
	print "   ----- dump msg -----\n";
	for (@$h) { print "   ", $_, "\n";}
	print "   ----- dump msg end -----\n";
    }

    for my $pkg (
		 'DSN', 
		 'Postfix19991231', 
		 'Qmail', 
		 'Exim',
		 'GOO',
		 'SimpleMatch', 
		 ) {
	my $module = "Mail::Bounce::$pkg";
	print "\n   --- module: $module\n" if $debug;
	eval qq { 
	    require $module; $module->import();
	    $module->analyze( \$msg , \$result );
	};
	croak($@) if $@;

	if (keys %$result) { 
	    print "\n   match $module\n" if $debug;
	    last;
	}
    }

    $self->{ _result } = $result;
}


=head2 C<address_list()>

return ARRAY of addresses found in the error message.

=cut


sub address_list
{
    my ($self) = @_;
    my $result = $self->{ _result };
    return keys %$result;
}


=head2 C<status($addr)>

return status (string) for C<$addr>.
The status is extracted from C<result> analyze() method gives. 

=head2 C<reason($addr)>

return error reason (string) for C<$addr>.
It is extracted from C<result> analyze() method gives. 

=cut


sub status
{
    my ($self, $addr) = @_;
    my $status = $self->{ _result }->{ $addr }->{ 'Status' };
    $status =~ s/\s+/ /g;
    $status =~ s/\s*$//;
    $status;
}


sub reason
{
    my ($self, $addr) = @_;
    my $reason = $self->{ _result }->{ $addr }->{ 'Diagnostic-Code' };
    $reason =~ s/\s+/ /g;
    $reason =~ s/\s*$//; 
    $reason;
}


sub hints
{
    my ($self, $addr) = @_;
    $self->{ _result }->{ $addr }->{ 'hints' };
}


=head2 C<look_like_japanese(string)>

return 1 if C<string> looks Japanese one in JIS/SJIS/EUC code.
return 0 unless.

=cut


my $RE_SJIS_C = '[\201-\237\340-\374][\100-\176\200-\374]';
my $RE_SJIS_S = "($RE_SJIS_C)+";
my $RE_EUC_C  = '[\241-\376][\241-\376]';
my $RE_EUC_S  = "($RE_EUC_C)+";
my $RE_JIN    = '\033\$[\@B]';
my $RE_JOUT   = '\033\([BJ]';

my @REGEXP = (
	      $RE_SJIS_C,
	      $RE_SJIS_S,
	      $RE_EUC_C,
	      $RE_EUC_S,
	      $RE_JIN,
	      $RE_JOUT,
	      );

sub look_like_japanese
{
    my ($self, $buf) = @_;

    for my $regexp (@REGEXP) {
	return 1 if $buf =~ /$regexp/;
    }

    0;
}


=head2 C<address_clean_up(type, addr)>

clean up C<addr> and return it.

C<type> gives a special hint for some specific MTA or domain.
It is rarely used.

=cut

sub address_clean_up
{
    my ($self, $hint, $addr) = @_;

    # nuke predecing and trailing strings around user@domain pattern
    my $prev_addr = $addr;
    do { 
	$prev_addr = $addr;
	print "    address_clean_up.in: $prev_addr\n" if $debug;

	$addr      =~ s/\.$//;
	$addr      =~ s/^\<//;
	$addr      =~ s/\>$//;
	$addr      =~ s/^\"//;
	$addr      =~ s/\"$//;

	print "   address_clean_up.out: $addr\n" if $debug;
    } while ($addr ne $prev_addr);

    # Mail::Bounce::FixBrokenAddress class provides irrgular
    # address handlings, so handles domain/MTA specific addresses.
    # For example, nifty.ne.jp, webtv.ne.jp, ...
    use Mail::Bounce::FixBrokenAddress;
    return Mail::Bounce::FixBrokenAddress::FixIt($hint, $addr);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Bounce appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
