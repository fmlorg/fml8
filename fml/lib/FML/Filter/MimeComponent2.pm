#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MimeComponent.pm,v 1.1 2002/09/30 11:00:54 fukachan Exp $
#

package FML::Filter::MimeComponent;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Filter::MimeComponent - filter based on mail MIME component

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::MimeComponent> is a MIME content filter.

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


my $debug = 0;


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


=head2 C<mime_component_check($msg, $args)>

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::MimeComponent;
    my $obj = new FML::Filter::MimeComponent;
    my $msg = $curproc->incoming_message();

    $obj->mime_component_check($msg, $args);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


    my $default_action = 'permit';


# Descriptions: top level dispatcher
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub mime_component_check
{
    my ($self, $msg, $args) = @_;
    my ($data_type, $prevmp, $nextmp, $mp, $action);
    my $is_match = 0;
    my $i = 1;

    # whole message type
    my $whole_data_type = $msg->whole_message_header_data_type();
    
  MSG:
    for ($mp = $msg; $mp; $mp = $mp->{ next }) {
	$data_type = $mp->data_type();

	# skip 
	# 1. the header part of the whole RFC822 message.
	# 2. parts of Mail::Message internal use.
	next MSG if ($data_type eq "text/rfc822-headers");
	next MSG if ($data_type =~ "multipart\.");

	# o.k. apply our filter rules.
	print STDERR "\n   msg($i) ($whole_data_type, $data_type)\n"; 
	$action = 
	    $self->_rule_match($msg, $args, $mp, $whole_data_type);

	if ($action eq 'reject' || $action eq 'permit') {
	    print STDERR "\n\t! action = $action. stop here.\n";
	    $is_match = 1;
	    last MSG;
	}

	# prepare for the next _rule_match().
	$i++;
    }

    my $decision = $is_match ? $action : $default_action;
    my $reason   = $is_match ? "matched action" : "default action";
    print STDERR "\n   our desicion: $decision ($reason)\n";
    return $decision;
}


=head1 INTERNAL PRESENTATION FOR FILTER RULES

Our filter rule is a list of the following components:

    (whole message type, message type, action)

For example, 

    $rules = (
	      (text/plain   *  permit),
	      (multipart/*  *  reject),
	      (*            *  reject),
	    );

=cut


my $filter_rules = [
		    ['text/plain',   '*',  'permit'],
		    ['multipart/*',  'image/*',  'reject'],
		    ];


# Descriptions: 
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($args) 
#               OBJ($mp) STR($whole_type)
# Side Effects: "reject" and "permit" affects nothing.
#               "cutoff" changes the chain of Mail::Message OBJs.
# Return Value: none
sub _rule_match
{
    my ($self, $msg, $args, $mp, $whole_type) = @_;
    my $type = $mp->data_type();
    my $i    = 0;

    if ($debug) {
	print STDERR "\twhole_type = $whole_type\n";
	print STDERR "\t      type = $type\n";
    }

    for my $rule (@$filter_rules) {
	$i++;

	my ($r_whole_type, $r_type, $r_action) = @$rule;
	print STDERR 
	    "\n\trule ${i}: ($r_whole_type, $r_type, $r_action)\n";

	if (__regexp_match($whole_type, $r_whole_type)) {
	    if (__regexp_match($type, $r_type)) {
		print STDERR "\t\t* checked. => $r_action\n";
		return $r_action;
	    }
	    else {
		print STDERR "\t\tnot check (type not matched)\n";
	    }
	}
	else {
	    print STDERR "\t\tnot check (whole_type not matched)\n";
	}
    }
}


# Descriptions: compare the given strings with regexp fuzziness.
#               return 1 if matched.
#    Arguments: STR($type) STR($regexp)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub __regexp_match
{
    my ($type, $regexp) = @_;

    # case insensitive
    $type   =~ tr/A-Z/a-z/;
    $regexp =~ tr/A-Z/a-z/;

    # prepare variables to compare
    my ($xl, $xr) = split(/\//, $type);     # text/plain
    my ($rl, $rr) = split(/\//, $regexp);   # text/*
    if ($regexp eq '*') { $rl = $rr = '*';} # * => */*

    # check left hand side
    if ($xl eq $rl || $rl eq '*') {
	# check right hand side
	if ($xr eq $rr || $rr eq '*') {
	    return 1; # both left and right hand sides ok
	}
	else {
	    return 0;
	}
    }
    else {
	return 0;
    }
}


# Descriptions: print filter rules.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub dump_filter_rules
{
    my $i = 0;
    
    for my $rule (@$filter_rules) {
	$i++;
	printf STDERR "%15s: %20s %20s %10s\n", "rule ${i}", @$rule;
    }

    printf STDERR "%15s: %20s %20s %10s\n", "default rule", 
    "*", "*", $default_action;
}


#
#sub _cutoff
#{
#	$prevmp = $mp->{ prev };
#	if ($prevmp) {
#	    my $prev_type = $prevmp->data_type();
#	    if ($prev_type eq "multipart.delimiter") {
#		$prevmp->delete_message_part_link();
#		Log("only_plaintext delete multipart delimiter");
#	    }
#	}
#	$mp->delete_message_part_link();
#	Log("only_plaintext delete not plain $data_type");
#    }
#}
#


# 
# debug
#

if ($0 eq __FILE__) {
    eval q{
	use FileHandle;
	use File::Basename;
	use Mail::Message;

	print STDERR "* current filter rules:\n";
	my $obj = new FML::Filter::MimeComponent;
	$obj->dump_filter_rules();
	print STDERR "\n";

	for (@ARGV) {
	    print STDERR ">>> ", basename($_), "\n";
	    my $msg = Mail::Message->parse( { file => $_ });
	    my $obj = new FML::Filter::MimeComponent;
	    my $fh  = new FileHandle $_;
	    $obj->mime_component_check($msg);
	    print STDERR "\n";
	}
    };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Filter::MimeComponent first appeared in fml8 mailing list driver
package.  See C<http://www.fml.org/> for more details.

Original FML::Filter::MimeComponent is writtern by Takuya MURASHITA.
This FML::Filter::MimeComponent module is rewritten based on the first
version to be able to handle enhanced filter rules.

2002/09/30: rename ContentCheck to MimeComponent.

=cut


1;
