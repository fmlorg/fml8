#-*- perl -*-
#
# Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Fake.pm,v 1.13 2005/06/04 08:55:57 fukachan Exp $
#

package FML::Process::Fake;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

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

load default config files,
set up domain we need to fake,
and
fix @INC if needed.

lastly, parse incoming message input from \*STDIN channel.

=cut


# Descriptions: constructor.
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


# Descriptions: preparation.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'faker_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->_faker_init($args);
    $curproc->_faker_prepare();

    $eval = $config->get_hook( 'faker_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

parse the header of incoming message to check to: and cc: fields.

If one of them matches the domain to fake, we need to start to emulate
something in run() method running phase.

=cut


# Descriptions: verify requests.
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

    $curproc->_faker_verify_request();

    $eval = $config->get_hook( 'faker_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<faker>.

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


=head2 finish($args)

dummy.

=cut


# Descriptions: dummy.
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


# Descriptions: show help.
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


=head1 INTERNAL FAKER FUNCTIONS

=cut


# Descriptions: initialize the faker process.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _faker_init
{
    my ($curproc, $args) = @_;
    my $config           = $curproc->config();
    my $work_dir         = $config->{ fml_default_ml_home_prefix };
    my $argv             = $curproc->command_line_argv();
    my $faker_domain     = $argv->[0];
    $faker_domain        =~ s/^\@//;

    # XXX we should chdir(ml_home_prefix of $faker_domain).
    # XXX anyway chdir(2) to the default domain's ml_home_prefix
    # XXX before actions for emergency logging.
    chdir $work_dir || exit(1);

    my $ml_home_dir  = File::Spec->catfile($work_dir, 'faker');
    $curproc->mkdir($ml_home_dir);
    $config->set('ml_name',        'faker');
    $config->set('ml_domain',      $faker_domain);
    $config->set('ml_home_prefix', $work_dir);
    $config->set('ml_home_dir',    $ml_home_dir);

    # init
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    # we assume
    # 
    # [/etc/postfix/virtual]
    #         @domain faker=domain@${default_domain}
    # 
    # [default_domain's alias file]
    #         faker=domain: "|/usr/local/libexec/fml/faker @domain"
    # 
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

    # 1. parse message
    $curproc->incoming_message_parse();
}


# Descriptions: parse the header and save addresses in To: and Cc:.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _faker_verify_request
{
    my ($curproc) = @_;
    my $pcb       = $curproc->pcb();

    # 2. pick up to: and cc: information to speculate our ML
    #    ${ml_name}@${ml_domain}.
    my $header = $curproc->incoming_message_header();
    if (defined $header) {
	my (@mail_addresses) = ();
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

	# 2.1 save valid addresses to pcb.
	unless ($curproc->_faker_analyze_address(\@mail_addresses)) {
	    $curproc->logerror("cannot find valid faker_domain");
	    exit(1);
	}
    }
    else {
	$curproc->logerror("no valid header");
	croak("no valid header");
    }
}


# Descriptions: main routine of libexec/faker process.
#               validate input data and emulates process switches.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load FML::Command::command module and execute it.
# Return Value: none
sub _faker_main
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();
    my $pcb    = $curproc->pcb();

    my $eval = $config->get_hook( 'faker_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # 3. validate and create a new $ml_name\@$faker_domain if needed.
    # 4. start emulation.
    my $ml_list   = $curproc->get_emul_ml_list();
    my $ml_domain = $curproc->get_emul_domain();
    for my $ml_name (@$ml_list) {
	if ($curproc->is_valid_ml($ml_name, $ml_domain)) {
	    $curproc->log("ml found: $ml_name");
	}
	else {
	    $curproc->log("try to create ml: $ml_name");
	    # $curproc->_ml_create($ml_name, $ml_domain);
	}

	$curproc->_faker_process_switch($args, $ml_name, $ml_domain);

	# XXX-TODO why 2nd chance ???
	if ($curproc->is_valid_ml($ml_name, $ml_domain)) {
	    $curproc->log("ml found: $ml_name");
	    $curproc->_faker_process_switch($args, $ml_name, $ml_domain);
	}
	else {
	    $curproc->logerror("fail to create ml: $ml_name");
	}
    }

    $eval = $config->get_hook( 'faker_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head1 Faker utilities

=cut


# Descriptions: ?
#    Arguments: OBJ($curproc) ARRAY_REF($addrlist)
# Side Effects: none
# Return Value: none
sub _faker_analyze_address
{
    my ($curproc, $addrlist) = @_;
    my $faker_domain = $curproc->get_emul_domain();
    my $pcb          = $curproc->pcb();
    my $found        = 0;
    my (@user)       = ();
    my (@ml)         = ();

    for my $addr (@$addrlist) {
	if ($addr =~ /\@$faker_domain$/i) {
	    $found++;
	    my ($ml_name, $ml_domain) = split(/\@/, $addr);
	    push(@ml, $ml_name);
	    print STDERR "  ml found: $ml_name\@$ml_domain\n";
	}
	else {
	    push(@user, $addr);
	    print STDERR "user found: $addr\n";
	}
    }

    $curproc->set_emul_ml_list(\@ml);
    $curproc->set_emul_user_list(\@user);

    return $found;
}


# Descriptions: emulate process switches.
#    Arguments: OBJ($curproc) HASH_REF($args) STR($ml_name) STR($ml_domain)
# Side Effects: none
# Return Value: none
sub _faker_process_switch
{
    my ($curproc, $args, $ml_name, $ml_domain) = @_;
    my $ml_addr = sprintf("%s@%s", $ml_name, $ml_domain);

    $curproc->logdebug("start ml emulation: $ml_name\@$ml_domain");

    # start the process.
    my $path = $curproc->incoming_message_get_cache_file_path();
    if ($path) {
	unless (open(STDIN, $path)) {
	    $curproc->logerror("cannot open $path");
	}
    }
    else {
	$curproc->logerror("cache file not found");
    }

    my $myname = "distribute";
    use FML::Process::Switch;
    &FML::Process::Switch::NewProcess($curproc,
				      $args,
				      $myname,
				      $ml_name,
				      $ml_domain);
}


=head1 Utilities

=head2 is_valid_domain_syntax($domain)

validate domain syntax.

=head2 is_valid_ml($ml_name, $ml_domain)

validate the existence of mailing list.

=cut


# Descriptions: validate domain syntax.
#    Arguments: OBJ($curproc) STR($domain)
# Side Effects: none
# Return Value: none
sub is_valid_domain_syntax
{
    my ($curproc, $domain) = @_;

    my $obj = new FML::Restriction::Base;
    if ($obj->regexp_match("domain", $domain)) {
        return $domain;
    }
}


# Descriptions: validate the existence of mailing list.
#    Arguments: OBJ($curproc) STR($ml_name) STR($ml_domain)
# Side Effects: none
# Return Value: none
sub is_valid_ml
{
    my ($curproc, $ml_name, $ml_domain) = @_;

    if ($curproc->is_config_cf_exist($ml_name, $ml_domain)) {
	return 1;
    }
    else {
	return 0;
    }
}


=head2 set_emul_domain($ml_domain)

save domain libexec/faker handles.

=head2 get_emul_domain()

get domain libexec/faker handles.

=cut


# Descriptions: save domain libexec/faker handles.
#    Arguments: OBJ($curproc) STR($ml_domain)
# Side Effects: update PCB.
# Return Value: none
sub set_emul_domain
{
    my ($curproc, $ml_domain) = @_;
    my $pcb = $curproc->pcb();
    $pcb->set("faker", "domain", $ml_domain);
}


# Descriptions: return domain libexec/faker handles.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub get_emul_domain
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    return $pcb->get("faker", "domain");
}


=head2 set_emul_ml_list($list)

save ml_name list in pcb.

=head2 get_emul_ml_list()

get ml_name list in pcb.

=cut


# Descriptions: save ml_name list in pcb.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: update pcb.
# Return Value: none
sub set_emul_ml_list
{
    my ($curproc, $list) = @_;
    my $pcb = $curproc->pcb();
    $pcb->set("faker", "ml_user_part_list", $list);
}


# Descriptions: 
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_emul_ml_list
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    return $pcb->get("faker", "ml_user_part_list");
}


=head2 set_emul_user_list($list)

save user list in pcb.

=head2 get_emul_user_list()

get user list in pcb.

=cut


# Descriptions: save user list in pcb.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: update pcb.
# Return Value: none
sub set_emul_user_list
{
    my ($curproc, $list) = @_;
    my $pcb = $curproc->pcb();
    $pcb->set("faker", "user_list", $list);
}


# Descriptions: 
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_emul_user_list
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    return $pcb->get("faker", "user_list");
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Fake first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
