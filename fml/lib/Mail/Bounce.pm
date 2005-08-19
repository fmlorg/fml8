#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Bounce.pm,v 1.29 2005/05/26 13:13:25 fukachan Exp $
#

package Mail::Bounce;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

=head1 NAME

Mail::Bounce - analyze error message.

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
which can recognize MTA specific and domain specific patterns.

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

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 analyze($msg)

C<$msg> is a C<Mail::Message> object.
This routine is a top level switch which provides the entrance
for C<Mail::Bounce::> modules, for example, C<Mail::Bounce::DSN>.

C<Mail::Bounce::$model::analyze( \$msg, \$result )>
method in each module is the actual model specific analyzer.
C<$result> has an answer of analyze if the error message pattern is
one of already known formats.

=cut


# Descriptions: top level dispatcher.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: update $self->{ _result }, which holds several info
# Return Value: none
sub analyze
{
    my ($self, $msg) = @_;
    my $result = {};

    if ($debug) {
	my $h = $msg->data_type_list( { debug => 1 } );
	print STDERR "   ----- dump msg -----\n";
	for my $hdr (@$h) { print STDERR "   ", $hdr, "\n";}
	print STDERR "   ----- dump msg end -----\n";
    }

  MODEL:
    for my $pkg (qw(
		    DSN
		    Postfix19991231
		    Qmail
		    Exim
		    GOO
		    Freeserve
		    SimpleMatch
		    )) {
	my $module = "Mail::Bounce::$pkg";
	print STDERR "\n   --- module: $module\n" if $debug;
	eval qq {
	    use $module;
	    $module->analyze( \$msg , \$result );
	};
	croak($@) if $@;

	# FOUND! if found, this loop ends here for FIRST MATCH.
	if (keys %$result) {
	    print STDERR "\n   match $module\n" if $debug;
	    last MODEL;
	}

        if ($debug) {
	    print STDERR "   * not match $module\n" unless %$result;
	}
    }

    $self->{ _result } = $result;
}


=head2 address_list()

return ARRAY of addresses found in the error message.

=cut


# Descriptions: return ARRAY of addresses found in the error message.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY
sub address_list
{
    my ($self) = @_;
    my $result = $self->{ _result };
    return keys %$result;
}


=head2 status($addr)

return status (string) for C<$addr>.
The status can be extracted from C<result> analyze() method gives.

=head2 reason($addr)

return error reason (string) for C<$addr>.
It can be extracted from C<result> analyze() method gives.

=cut


# XXX-TODO: hmm, we should prepare $addr->status() and $addr->reason() ?


# Descriptions: return status (string) for $addr.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub status
{
    my ($self, $addr) = @_;
    my $status = $self->{ _result }->{ $addr }->{ 'Status' };
    $status =~ s/\s+/ /go;
    $status =~ s/\s*$//o;
    $status;
}


# Descriptions: return reason (string) for $addr.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub reason
{
    my ($self, $addr) = @_;
    my $reason = $self->{ _result }->{ $addr }->{ 'Diagnostic-Code' };
    $reason =~ s/\s+/ /go;
    $reason =~ s/\s*$//o;
    $reason;
}


# Descriptions: return hints (string) for $addr.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub hints
{
    my ($self, $addr) = @_;
    $self->{ _result }->{ $addr }->{ 'hints' };
}


=head2 look_like_japanese(string)

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


# Descriptions: $buf looks like Japanese ?
#    Arguments: OBJ($self) STR($buf)
# Side Effects: none
# Return Value: 1 or 0
sub look_like_japanese
{
    my ($self, $buf) = @_;

    for my $regexp (@REGEXP) {
	return 1 if $buf =~ /$regexp/;
    }

    0;
}


=head2 address_cleanup(hint, addr)

clean up C<addr> and return it.

C<hint> gives a special hint for some specific MTA or domain.
It is rarely used.

=cut


# Descriptions: clean up address for further use.
#    Arguments: OBJ($self) STR($hint) STR($addr)
# Side Effects: none
# Return Value: STR
sub address_cleanup
{
    my ($self, $hint, $addr) = @_;

    if ($debug) { print STDERR "address_cleanup($hint, $addr)\n";}

    # remove prepended and trailing strings around user@domain pattern.
    my $prev_addr = $addr;
    do {
	$prev_addr = $addr;
	print STDERR "    address_cleanup.in: $prev_addr\n" if $debug;

	$addr      =~ s/\.$//o;
	$addr      =~ s/^\<//o;
	$addr      =~ s/\>$//o;
	$addr      =~ s/^\"//o;
	$addr      =~ s/\"$//o;

	print STDERR "   address_cleanup.out: $addr\n" if $debug;
    } while ($addr ne $prev_addr);

    # Mail::Bounce::FixBrokenAddress class provides irrgular
    # address handlings, so handles domain/MTA specific addresses.
    # For example, nifty.ne.jp, webtv.ne.jp, ...
    # XXX-TODO: Mail::Bounce::FixBrokenAddress::FixIt is ugly.
    use Mail::Bounce::FixBrokenAddress;
    return Mail::Bounce::FixBrokenAddress::FixIt($hint, $addr);
}


=head1 SECURITY CONSIDERATION

The address returned by Mail::Bounce class may be unsafe.  Please
validate it by some other class such as FML::Restriction class before
use it at some other place.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;

