#-*- perl -*-
#
# Copyright (C) 2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML$
#

package FML::Process::Fake;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Fake -- dispatcher to fake several processes.

=head1 SYNOPSIS

    use FML::Process::Fake;
    $curproc = new FML::Process::Fake;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Fake provides the main function for C<libexec/faker>.

See C<FML::Process::Flow> for the flow detail.

=head1 METHODS

=head2 new($args)

constructor.
It make a C<FML::Process::Kernel> object and return it.

=head2 prepare($args)

load config files and fix @INC.

=head2 verify_request($args)

dummy.

=cut


# Descriptions: ordinary constructor
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'faker_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->_faker_prepare();
    exit(0);

    $eval = $config->get_hook( 'faker_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: initialize the faker process
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _faker_init
{
    my ($curproc)    = @_;
    my $argv         = $curproc->command_line_argv();
    my $faker_domain = $argv->[0];

    # we assume
    # VIRTUAL  @domain faker=domain@${default_domain}
    # ALIAS    faker=domain: "|/usr/local/libexec/fml/faker domain"
    if ($curproc->is_valid_domain_syntax($faker_domain)) {
	$curproc->set_emul_domain($faker_domain);
    }
}


# Descriptions: parser of incoming message header.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _faker_prepare
{
    my ($curproc) = @_;
    my (@mail_addresses) = ();

    # 1. parse message 
    $curproc->parse_incoming_message();

    # 2. pick up to: and cc: information to speculate our ML
    #    ${ml_name}@${ml_domain}.
    my $header = $curproc->incoming_message_header();
    if (defined $header) {
	my ($to) = $header->get('to');
	my ($cc) = $header->get('cc');
	my $buf  = sprintf("%s, %s", $to, $cc);

	# parse to: and cc: to pick up valid mail addresses.
	use Mail::Address;
	my (@addrlist) = Mail::Address->parse($buf);
	for my $a (@addrlist) {
	    if (defined $a) {
		my $addr = $a->address;
		$addr =~ s/^\s*<//;
		$addr =~ s/>\s*$//;
		push(@mail_addresses, $addr);
	    }
	}

	$curproc->_faker_analyze_address(\@mail_addresses);
	# ml existence check ...
	# user check ...
	# start new emulation for ml's (for all valid ml_name !)
    }
    else {
	croak("no header");
    }
}


sub _faker_analyze_address
{
    my ($curproc, $addrlist) = @_;
    my $faker_domain = $curproc->get_emul_domain();
    my $found  = 0;
    my (@user) = ();

    for my $addr (@$addrlist) {
	if ($addr =~ /\@$faker_domain$/i) {
	    $found = 1;
	    my ($ml_name, $ml_domain) = split(/\@/, $addr);
	}
	else {
	    push(@user, $addr);
	}
    }
}


# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'faker_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'faker_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<faker>.

It kicks off C<_faker($args)> for faker.

NOTE:
C<$args> is passed from parrent libexec/loader.
See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions: just a switch, call _faker_main().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    $curproc->_faker_main($args);
}


# Descriptions: dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'faker_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'faker_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
    my $name = $0;
    eval {
	use File::Basename;
	$name = basename($0);
    };

print <<"_EOF_";

Usage: $name [options]

-n   show fml specific aliases.

[BUGS]
	support only fml8 + postfix case.
	also, we assume /etc/passwd exists.

_EOF_
}


=head2 _faker_main($args)

show all aliases (accounts + aliases).
show only accounts if -n option specified.

See <FML::Process::Switch()> on C<$args> for more details.

=cut


# Descriptions:
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _faker_main
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'faker_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'faker_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Fake first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
