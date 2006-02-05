#-*- perl -*-
#
# Copyright (C) 2006 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: CreateOnPost.pm,v 1.2 2006/02/05 01:02:52 fukachan Exp $
#

package FML::Process::CreateOnPost;

use strict;
use Carp;
use vars qw($debug @ISA @EXPORT @EXPORT_OK);

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::CreateOnPost -- create-on-post ML master process.

=head1 SYNOPSIS

    use FML::Process::CreateOnPost;
    $curproc = new FML::Process::CreateOnPost;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::CreateOnPost provides the main function for
C<libexec/createonpost>.

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

    my $eval = $config->get_hook( 'createonpost_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->ml_variables_resolve();
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    if ($config->yes('use_createonpost_function')) {
	$curproc->incoming_message_parse();
    }
    else {
	$curproc->logerror("use of createonpost_program prohibited");
	exit(0);
    }

    $eval = $config->get_hook( 'createonpost_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: exit ASAP.
#               longjmp() to help() if appropriate
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'createonpost_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    unless ($curproc->is_refused()) {
	$curproc->_createonpost_verify_request();
    }
    else {
	$curproc->logwarn("ignore this request");
	exit(0);
    }

    $eval = $config->get_hook( 'createonpost_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

the top level dispatcher for C<createonpost>.

=cut


# Descriptions: just a switch, call _createonpost_main().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'createonpost_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    unless ($curproc->is_refused()) {
	$curproc->log("create-on-post run ...");
	$curproc->_run_createonpost();
    }
    else {
	$curproc->logwarn("ignore this request");
    }

    $eval = $config->get_hook( 'createonpost_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
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

    my $eval = $config->get_hook( 'createonpost_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $eval = $config->get_hook( 'createonpost_finish_end_hook' );
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

[BUGS]

_EOF_
}


=head1 INTERNAL FUNCTIONS

Internal function fakes mail retrieve and forward mechanism.

It fetches a message via POP3 or IMAP4 protocol and forward it into
fml8 process.

=cut


my $ADDR_CREATE_ON_POST = 1;
my $ADDR_FML8_MANAGED   = 2;
my $ADDR_NORMAL         = 3;


# Descriptions: retrieve a message and forward it into fml8 to parse
#               incoming message.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _createonpost_verify_request
{
    my ($curproc) = @_;
    my ($restriction, $addrlist);

    # 1. parse To: and Cc:
    my ($all, $address2class, $class2address) = $curproc->_classify_address();
    my $r_args = {
	address_to_class => $address2class, 
	class_to_address => $class2address,
    };

    # 1.1 and some preparations.
    my $header      = $curproc->incoming_message_header();
    my $return_path = $header->address_cleanup( $header->get('Return-Path') );
    my $cred        = $curproc->credential();
    my $sender      = $cred->sender();

    # 2. check sender. 
    $r_args->{ address_list } = [ $return_path, $sender ];
    $restriction = 'createonpost_sender_restrictions';
    $addrlist    = $curproc->_apply_restrictions($restriction, $r_args);
    if ($addrlist->{ "deny" }) {
	$curproc->log("Return-Path: $return_path") if $return_path;
	$curproc->log("sender: $sender") if $sender;
	$curproc->log("$restriction: denied");
	$curproc->stop_this_process();
	return;
    }

    # 3. check recipients (To: and Cc:).
    $r_args->{ address_list } = $all;
    $restriction = 'createonpost_subscribe_restrictions',
    $addrlist    = $curproc->_apply_restrictions($restriction, $r_args);

    # 4. save for later use.
    my $pcb = $curproc->pcb();
    $pcb->set("createonpost", "address_list", $addrlist);
    $pcb->set("createonpost", "address_to_class", $address2class);
    $pcb->set("createonpost", "class_to_address", $class2address);
}


# Descriptions: classify recipient addresses (To: and Cc:) in header.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: ARRAY(ARRAY_REF, HASH_REF, $HASH_REF)
sub _classify_address
{
    my ($curproc)  = @_;
    my $config     = $curproc->config();
    my $ml_domain  = $curproc->ml_domain();
    my $header     = $curproc->incoming_message_header();
    my $to         = $header->get('To') || '';
    my $cc         = $header->get('Cc') || '';
    my $fields     = "$to, $cc";
    my $result     = {};
    my $addrlist   = [];
    my $rev_result = {
	$ADDR_CREATE_ON_POST => [],
	$ADDR_FML8_MANAGED   => [],
	$ADDR_NORMAL         => [],
    };

    use Mail::Address;
    my (@addr) = Mail::Address->parse($fields);
    for my $_addr (@addr) {
	my $addr = $_addr->address();
	push(@$addrlist, $addr);

	# 1. create-on-post
	if ($addr =~ /\@$ml_domain$/i) {
	    $result->{ $addr } = $ADDR_CREATE_ON_POST;
	    push(@{$rev_result->{ $ADDR_CREATE_ON_POST }}, $addr);
	}
	# 2. fml8 managed.
	elsif ($curproc->is_fml8_managed_address($addr)) {
	    $result->{ $addr } = $ADDR_FML8_MANAGED;
	    push(@{$rev_result->{ $ADDR_FML8_MANAGED }}, $addr);
	}
	# 3. others
	else {
	    $result->{ $addr } = $ADDR_NORMAL;
	    push(@{$rev_result->{ $ADDR_NORMAL }}, $addr);
	}
    }

    return( $addrlist, $result, $rev_result );
}


# Descriptions: apply $createonpost_sender_restrictions rules.
#    Arguments: OBJ($curproc) STR($restriction) HASH_REF($r_args)
# Side Effects: none
# Return Value: HASH_REF
sub _apply_restrictions
{
    my ($curproc, $restriction, $r_args) = @_;
    my $config      = $curproc->config();
    my $rules       = $config->get_as_array_ref($restriction);
    my $addrlist    = $r_args->{ address_list } || [];
    my $result_data = {};
    my $result_addr = {};

    use FML::Restriction::CreateOnPost;
    my $acl = new FML::Restriction::CreateOnPost $curproc;
    my ($match, $result) = (0, 0);

  RULE:
    for my $rule (@$rules) {        # reject_XXX, permit_anyone
      ADDR:
	for my $addr (@$addrlist) { # e.g. COP, MANAGED, OTHER;
	    next ADDR unless $addr;

	    if ($acl->can($rule)) {
		# match  = matched. return as soon as possible from here.
		#          ASAP or RETRY the next rule, depends on the rule.
		# result = action determined by matched rule.
		($match, $result) = $acl->$rule($rule, $addr);
	    }
	    else {
		($match, $result) = (0, undef);
		$curproc->logwarn("unknown rule=$rule");
	    }

	    if ($match) {
		$curproc->logdebug("match rule=$rule address=$addr");
		$result_data->{ $result }++;
		push(@{ $result_addr->{ $result } }, $addr );
	    }
	}
    }

    return $result_addr;
}


# Descriptions: create-on-post main dispatcher. 
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _run_createonpost
{
    my ($curproc)        = @_;
    my $pcb              = $curproc->pcb();
    my $addr_list        = $pcb->get("createonpost", "address_list")     || {};
    my $address_to_class = $pcb->get("createonpost", "address_to_class") || {};
    my $class_to_address = $pcb->get("createonpost", "class_to_address") || {};
    my (@process_list)   = ();

    # address list
    my (@deny_list)   = @{ $addr_list->{ "deny" }   || [] };
    my (@permit_list) = @{ $addr_list->{ "permit" } || [] };

    # 1. 
    my $cop_list= $class_to_address->{ $ADDR_CREATE_ON_POST } || [];
    for my $ml (@$cop_list) {
	if ($curproc->_is_ml_address($ml)) {
	    $curproc->log("ml exist: $ml");
	}
	else {
	    $curproc->log("ml fault: create $ml");
	    $curproc->_create_ml($ml);
	}
    }

    # 2. generate list to subscribe.
  ADDR:
    for my $addr (@permit_list) {
	for my $ign (@deny_list) {
	    if ($addr eq $ign) {
		$curproc->log("ignore $addr");		
		next ADDR;
	    }
 	}
	push(@process_list, $addr);
    }

    # 2.1 save user list on shared memory.
    $curproc->_save_user_list(\@process_list);

    # 3. run distribute processes.
    for my $ml (@$cop_list) {
	# XXX bound for elena (NOT elena-ctl NOR elena-admin).
        if ($curproc->_is_ml_address($ml)) {
	    if ($curproc->is_fml8_managed_address($ml)) {
		$curproc->_distribute_ml($ml);
	    }
	    else {
		$curproc->logwarn("$ml ignored");
	    }
	}
        else {
            $curproc->logerror("$ml not found");
        }
    }
}


# Descriptions: check if the given address is one of ML addresses
#               (ML, ML-ctl and ML-admin).
#    Arguments: OBJ($curproc) STR($addr)
# Side Effects: none
# Return Value: NUM
sub _is_ml_address
{
    my ($curproc, $addr) = @_;
    my ($ctl, $admin);

    # elena
    # XXX if you create xxx-ctl or xxx-admin ML, it should be allowed.
    if ($curproc->is_fml8_managed_address($addr)) {
	return 1;
    }
    # elena-ctl
    elsif ($addr =~ /-ctl\@/) {
	return 1;
    }
    # elena-admin
    elsif ($addr =~ /-admin\@/) {
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: save user list for child process.
#    Arguments: OBJ($curproc) ARRAY_REF($list)
# Side Effects: none
# Return Value: none
sub _save_user_list
{
    my ($curproc, $list) = @_;

    $curproc->set_address_fault();
    $curproc->set_address_fault_list($list);
    $curproc->log("subscribe? (@$list)");
}


# Descriptions: execute distribute process.
#    Arguments: OBJ($curproc) STR($ml)
# Side Effects: none
# Return Value: none
sub _distribute_ml
{
    my ($curproc, $ml) = @_;

    use FML::CreateOnPost;
    my $cop = new FML::CreateOnPost $curproc;
    $cop->distribute_ml($ml);
}


=head1 FAULT HANDLING

=head2 ML VALIDATION FAULT 

This process checks the ML existence and call fault handler if not
found. The fault handler creates a ML.

=head2 ADDRESS VALIDATION FAULT 

This process does not handle address fault that the specified address
is not a member. Instead the executed process e.g. distirubition
process handles it as address validation fault.

=cut


# Descriptions: create ml. 
#    Arguments: OBJ($curproc) STR($ml_addr)
# Side Effects: none
# Return Value: none
sub _create_ml
{
    my ($curproc, $ml_addr) = @_;

    use FML::CreateOnPost;
    my $cop = new FML::CreateOnPost $curproc;
    $cop->create_ml($ml_addr);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CreateOnPost first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
