#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MimeComponent2.pm,v 1.2 2002/10/21 08:35:45 fukachan Exp $
#

package FML::Filter::MimeComponent;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use ErrorStatus qw(error_set error error_clear);
use FML::Log qw(Log LogWarn LogError);

=head1 NAME

FML::Filter::MimeComponent - filter based on mail MIME components

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::MimeComponent> is a mime content based filter.

=head1 INTERNAL PRESENTATION FOR FILTER RULES

Our filter rule is a list of the following components:

    (whole message type, message type, action)

For example, 

    $rules = (
	      (text/plain   *  permit),
	      (multipart/*  *  reject),
	      (*            *  reject),
	    );

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


my $debug = 0;


# default rules
my $filter_rules = [
		    ['text/plain',   '*',  'permit'],
		    ['text/*',       '*',  'reject'],
		    ['multipart/*',  '*',  'reject'],
		    ['*',            '*',  'reject'],
		    ];


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
    my $j = 1;

    # whole message type
    my $whole_data_type = $msg->whole_message_header_data_type();

    # debug info
    if (1) { $self->dump_message_structure($msg);}

  RULE:
    for my $rule (@$filter_rules) {
	__dprint("\n    rule ${j}: (@$rule)");
	$j++;

      MSG:
	for ($mp = $msg, $i = 1; $mp; $mp = $mp->{ next }) {
	    $data_type = $mp->data_type();

	    # ignore the header part of the whole RFC822 message.
	    #        and parts of Mail::Message internal use.
	    next MSG if ($data_type eq "text/rfc822-headers");
	    next MSG if ($data_type =~ "multipart\.");

	    __dprint("\n\tmsg($i) $data_type"); 
	    $action = $self->_rule_match($msg,$rule,$mp,$whole_data_type);
	    if ($action eq 'reject' || $action eq 'permit') {
		__dprint("\n\t! action = $action. stop here.");
		$is_match = 1;
		last RULE;
	    }
	    
	    $i++; # prepare for the next _rule_match().
	}
    }

    my $decision = $is_match ? $action : $default_action;
    my $reason   = $is_match ? "matched action" : "default action";
    __dprint("\n   our desicion: $decision ($reason)");
    return $decision;
}


# Descriptions: 
#    Arguments: OBJ($self) OBJ($msg) ARRAY_REF($rule)
#               OBJ($mp) STR($whole_type)
# Side Effects: "reject" and "permit" affects nothing.
#               "cutoff" changes the chain of Mail::Message OBJs.
# Return Value: none
sub _rule_match
{
    my ($self, $msg, $rule, $mp, $whole_type) = @_;
    my ($r_whole_type, $r_type, $r_action) = @$rule;
    my $type                               = $mp->data_type();

    if (__regexp_match($whole_type, $r_whole_type)) {
	if (__regexp_match($type, $r_type)) {
	    __dprint("\t\t* checked. => $r_action");
	    return $r_action;
	}
	else {
	    __dprint("\t\tnot check (type not matched)");
	}
    }
    else {
	__dprint("\t\tnot check (whole_type not matched)");
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


=head1 utilities

=cut


# Descriptions: read rule file.
#               XXX we should enhance this to use IO::Adapter.
#    Arguments: OBJ($self) STR($file)
# Side Effects: update filter rules.
# Return Value: none
sub read_filter_rule_from_file
{
    my ($self, $file) = @_;
    my ($whole_type, $type, $action);

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my $rules = [];

	while (<$fh>) {
	    next if /^#/o;
	    next if /^\s*$/o;

	    ($whole_type, $type, $action) = split(/\s+/, $_);
	    push(@$rules, [ $whole_type, $type, $action ] );
	}

	$fh->close();

	if (@$rules) {
	    $filter_rules = $rules;
	}
	else {
	    use Carp;
	    carp("no valid filter rules");
	}
    }
}


sub dump_message_structure
{
    my ($self, $msg) = @_;
    my ($data_type, $prevmp, $nextmp, $mp, $action, $i);
    my $whole_data_type = $msg->whole_message_header_data_type();

    __dprint("\t[message structure]");
    __dprint("\t\t$whole_data_type");

  MSG:
    for ($mp = $msg, $i = 1; $mp; $mp = $mp->{ next }) {
	$data_type = $mp->data_type();
	next MSG if ($data_type eq "text/rfc822-headers");
	next MSG if ($data_type =~ "multipart\.");
	__dprint("\t\t\t$data_type");
	$i++;
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


=head1 DEBUG

    perl -I PERL_INCLUDE_PATH MimeComponent2.pm -c RULE_FILE @FILES

=cut


# Descriptions: print for debug (works if $debug level > 1).
#    Arguments: STR($s)
# Side Effects: none
# Return Value: none
sub __dprint
{
    my ($s) = @_;

    if ($debug > 1) {
	print STDERR $s, "\n";
    }
}


# 
# debug
#

if ($0 eq __FILE__) {
    eval q{
	use FileHandle;
	use File::Basename;
	use Mail::Message;
	use Getopt::Long;
	my $opt = {};
	GetOptions($opt, qw(debug! -c=s));

	# update debug level
	$debug = 2;

	# rule ?
	print STDERR "* current filter rules:\n";
	my $obj = new FML::Filter::MimeComponent;
	if (defined $opt->{ 'c' }) {
	    my $file = $opt->{ 'c' };
	    $obj->read_filter_rule_from_file($file);
	}
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

2002/10/21: fully rewritten by fukachan@fml.org.

=cut


1;
