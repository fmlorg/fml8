#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: MimeComponent.pm,v 1.15 2005/08/10 12:55:33 fukachan Exp $
#

package FML::Filter::MimeComponent;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $recursive_level $recursive_max_level);
use Carp;
use FML::Filter::ErrorStatus qw(error_set error error_clear);

=head1 NAME

FML::Filter::MimeComponent - filter based on mail MIME components.

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

=head2 new()

constructor.

=cut


my $debug = 0;


# default rules for convenience.
my $filter_rules = [
		    ['text/plain',   '*',  'permit'],
		    ['text/html' ,   '*',  'reject'],
		    ['multipart/*',  '*',  'reject'],
		    ];


# XXX-TODO: $default_action customizable ?
my $default_action = 'permit';

# XXX-TODO: $opt_cutoff_empty_part customizable ?
my $opt_cutoff_empty_part = 1;

# XXX-TODO: $recursive_max_level customizable ?
my $recursive_max_level    = 10;



# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my %count  = ();
    my %reason = ();
    my $me     = {
	_curproc => $curproc,
	_count   => \%count,
	_reason  => \%reason,
    };

    return bless $me, $type;
}


=head2 mime_component_check($msg)

C<$msg> is C<Mail::Message> object.

C<Usage>:

    use FML::Filter::MimeComponent;
    my $obj = new FML::Filter::MimeComponent;
    my $msg = $curproc->incoming_message();

    $obj->mime_component_check($msg);
    if ($obj->error()) {
       # do something for wrong formated message ...
    }

=cut


# Descriptions: top level dispatcher.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub mime_component_check
{
    my ($self, $msg) = @_;
    my $curproc      = $self->{ _curproc };
    my $count        = $self->{ _count };
    my $reason       = $self->{ _reason };
    my $is_cutoff    = 0; # debug

    # whole message type
    my $whole_data_type = $msg->whole_message_header_data_type();

    # debug info
    if ($debug) { $self->dump_message_structure($msg);}

    $recursive_level ||= 0;

    my ($data_type, $prevmp, $nextmp, $mp, $action, $reject_reason, $i, $j);
  MSG:
    for ($mp = $msg, $i = 1, $j = 1; $mp; $mp = $mp->{ next }) {
	$data_type = $mp->data_type();

	# ignore the header part of the whole RFC822 message.
	#        and parts of Mail::Message internal use.
	next MSG if ($data_type eq "text/rfc822-headers");
	next MSG if ($data_type =~ /multipart\./);

	if ($recursive_level > 0) {
	    __dprint("\n   msg($recursive_level/$i) $data_type");
	}
	else {
	    __dprint("\n   msg($i) $data_type");
	}

	if ($data_type =~ /message\/rfc822/i) {
	    $self->_rfc822_mime_component_check($mp);
	    next MSG;
	}

	# apply all rules for this message $mp.
      RULE:
	for my $rule (@$filter_rules) {
	    __dprint("\n\trule ${j}: (@$rule)");
	    $j++;

	    $action = $self->_rule_match($msg,$rule,$mp,$whole_data_type);
	    if (defined $action) {
		$count->{ $action }++;
		$reason->{ $action } = join(" ", @$rule);

		if ($action eq 'reject' || $action eq 'permit') {
		    __dprint("\n\t! action = $action.");
		    if ($action eq 'reject') {
			$reject_reason = join(" ", @$rule);
		    }
		}
		elsif ($action eq 'cutoff') {
		    __dprint("\n\t! action = $action.");
		    $is_cutoff = 1;
		    $self->_cutoff($mp);
		}
	    }

	    $i++; # prepare for the next _rule_match().
	}

	# cut off this part if empty.
	if ($opt_cutoff_empty_part) {
	    if ($mp->is_empty()) {
		__dprint("\n\t! action = cutoff due to empty.");
		$is_cutoff = 1;
		$self->_cutoff($mp);
	    }
	}
    }

    # reject if all effective parts are cutoff.
    if ($opt_cutoff_empty_part) {
	if ($msg->is_multipart()) {
	    # reject if no effective part.
	    unless ($self->_has_effective_part($msg)) {
		my $reason = "no effective part in this multipart";
		$curproc->log($reason) if defined $curproc;
		$count->{ 'reject' }++;
		$reason->{ 'reject' } = $reject_reason = $reason;
	    }
	}
    }

    # debug info
    if ($is_cutoff && $debug) { $self->dump_message_structure($msg);}

    # if matched with "reject" at laest once, reject the whole mail.
    my $decision = $default_action;
    my $_reason  = undef;
    if (defined $count->{ 'reject' } && $count->{ 'reject' } > 0) {
	$decision = 'reject';
	$_reason  = $reject_reason;
    }
    else {
	# save the reason(s).
	for my $key (keys %$reason) {
	    if ($key ne 'reject') {
		$_reason .=
		    $_reason ? " + $reason->{ $key }" : $reason->{ $key };
	    }

	    if ($key eq 'permit') {
		$decision = 'permit';
	    }
	}
    }

    $_reason ||= $self->{ _reject_reason } || "default action";
    if (defined $curproc) {
	$curproc->log("mime_component_filter: $decision ($_reason)");
    }

    __dprint("\n   our desicion($recursive_level): $decision ($_reason)");

    if ($decision eq 'reject') {
	$self->error_set($_reason);
	$self->{ _reject_reason } = $_reason;
    }
    return $decision;
}


# Descriptions: try rule match by regexp.
#               see __regexp_match() for matching details.
#    Arguments: OBJ($self) OBJ($msg) ARRAY_REF($rule)
#               OBJ($mp) STR($whole_type)
# Side Effects: "reject" and "permit" affects nothing.
#               "cutoff" changes the chain of Mail::Message OBJs.
# Return Value: STR
sub _rule_match
{
    my ($self, $msg, $rule, $mp, $whole_type) = @_;
    my ($r_whole_type, $r_type, $r_action)    = @$rule;
    my $type                                  = $mp->data_type() || '';

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

    return undef;
}


# Descriptions: compare the given strings with regexp fuzziness.
#               return 1 if matched.
#    Arguments: STR($type) STR($regexp)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub __regexp_match
{
    my ($type, $regexp) = @_;
    my $reverse = 0;

    $type   ||= '';
    $regexp ||= '';

    # case insensitive
    $type   =~ tr/A-Z/a-z/;
    $regexp =~ tr/A-Z/a-z/;

    if ($regexp =~ /^\!/o) {
	$reverse = 1;
	$regexp =~ s/^\!//o;

	# XXX-TODO: correct ?
	$regexp =~ s/^\(\S+\)/$1/o;
    }

    my $status = __basic_regexp_match($type, $regexp);

    if ($status) {
	return $reverse ? 0 : 1;
    }
    else {
	return $reverse ? 1 : 0;
    }
}


# Descriptions: compare the given strings with regexp fuzziness
#               where $regexp has "^!" (not mode).
#    Arguments: STR($type) STR($regexp)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub __basic_regexp_match
{
    my ($type, $regexp) = @_;

    if (defined $type && $type && defined $regexp && $regexp) {
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

    return 0;
}


# Descriptions: cut off $mp from a chain of Mail::Message objects.
#    Arguments: OBJ($self) OBJ($mp)
# Side Effects: change a chain of objects.
# Return Value: none
sub _cutoff
{
    my ($self, $mp) = @_;
    my $curproc     = $self->{ _curproc };
    my $data_type   = $mp->data_type();
    my $prevmp      = $mp->{ prev };

    if ($prevmp) {
	my $prev_type = $prevmp->data_type();
	if ($prev_type eq "multipart.delimiter") {
	    $prevmp->delete_message_part_link();
	    $curproc->log("delete multipart delimiter");
	}
    }

    $mp->delete_message_part_link();

    $curproc->log("delete $data_type");
}


# Descriptions: check if the object chain has effective part ?
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: NUM( 1 or 0 )
sub _has_effective_part
{
    my ($self, $msg) = @_;
    my ($mp, $data_type, $in_multipart);
    my $i = 0;

  MSG:
    for ($mp = $msg; $mp; $mp = $mp->{ next }) {
	$data_type    = $mp->data_type();
	$in_multipart = 1 if $data_type eq 'multipart.delimiter';
	$in_multipart = 0 if $data_type eq 'multipart.close-delimiter';

	next MSG if $data_type =~ /multipart\./o;

	if ($in_multipart) {
	    $i++;
	}
    }

    return( $i ? 1 : 0 );
}


# Descriptions: parser of child multipart.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: update $recursive_level (file scope variable).
# Return Value: NUM
sub _rfc822_mime_component_check
{
    my ($self, $msg) = @_;
    my $curproc      = $self->{ _curproc };

    $recursive_level ||= 0;
    $recursive_level++;

    if ($debug) {
	print STDERR "\t_rfc822_mime_component_check ($recursive_level)\n";
    }

    if ($recursive_level > $recursive_max_level) {
	croak("too deep recursive call");
    }
    else {
	my $tmpf = $self->_tmp_file_path();

	use FileHandle;
	my $wh = new FileHandle "> $tmpf";
	if (defined $wh) {
	    $msg->print($wh);
	    $wh->close();
	}

	my $rh = new FileHandle $tmpf;
	if (defined $rh) {
	    use Mail::Message;
	    my $msg0 = new Mail::Message->parse( { fd => $rh } );
	    $self->mime_component_check($msg0);
	}
    }

    $recursive_level--;
}


# Descriptions: return temporary file path to be used.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub _tmp_file_path
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };

    if (defined $curproc) {
	return $curproc->tmp_file_path();
    }
    elsif ($debug) {
	return "./fileter.debug.$$";
    }
    else {
	$curproc->logerror("\$curproc is mandatory");
	croak("\$curproc undefined");
    }
}


=head1 UTILITY FUNCTIONS

=cut


# Descriptions: read rule file.
#               XXX we should enhance this to use IO::Adapter.
#    Arguments: OBJ($self) STR($file)
# Side Effects: update filter rules.
# Return Value: none
sub read_filter_rule_file
{
    my ($self, $file) = @_;
    my ($whole_type, $type, $action);

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my $rules = [];
	my $buf;

	while ($buf = <$fh>) {
	    next if $buf =~ /^#/o;
	    next if $buf =~ /^\s*$/o;

	    ($whole_type, $type, $action) = split(/\s+/, $buf);
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
    else {
	use Carp;
	carp("cannot open $file");
    }
}


# Descriptions: dump message structure
#               (a chain of Mail::Message objects).
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
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
	# next MSG if ($data_type =~ "multipart\.");
	__dprint("\t\t\t$data_type");
	$i++;
    }

    if ($debug > 7) {
	for ($mp = $msg, $i = 1; $mp; $mp = $mp->{ next }, $i++) {
	    my ($p, $c, $n) = ("$mp->{ prev }", "$mp", "$mp->{ next }");
	    $p =~ s/Mail::Message=HASH\((\S+)\)/$1/;
	    $c =~ s/Mail::Message=HASH\((\S+)\)/$1/;
	    $n =~ s/Mail::Message=HASH\((\S+)\)/$1/;
	    __dprint(sprintf("%2d %25s | %10s | %10s | %10s",
			     $i, $mp->data_type(), $p, $c, $n));
	}
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

    perl -I PERL_INCLUDE_PATH MimeComponent3.pm -c RULE_FILE @FILES

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
    $| = 1;
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
	    $obj->read_filter_rule_file($file);
	}
	$obj->dump_filter_rules();
	print STDERR "\n";

	for my $argv (@ARGV) {
	    print STDERR ">>> ", basename($argv), "\n";
	    my $msg = Mail::Message->parse( { file => $argv });
	    my $obj = new FML::Filter::MimeComponent;
	    my $fh  = new FileHandle $argv;
	    $obj->mime_component_check($msg);
	    print STDERR "\n";
	}
    };
    print $@ if $@;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi

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
