#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Debug.pm,v 1.8 2004/01/04 13:19:10 fukachan Exp $
#

package FML::Process::Debug;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Debug - debug tool / tiny FML::Process emulator

=head1 SYNOPSIS

    if ($0 eq __FILE__) {
	my $domain  = "nuinui.net";
	my $prefix  = "/tmp/nuinui.net";
	my $map     = "/etc/fml/ml_home_prefix";

	use FML::Process::Debug;
	my $curproc = new FML::Process::Debug;
	$curproc->{ config } = { fml_primary_ml_home_prefix_map => $map };

        # special debug flag on
	$debug = 101;
	$|     = 1;

	my $ml_home_prefix = new FML::ML::HomePrefix $curproc;

	print "\n# add { $domain => $prefix }\n";
	$ml_home_prefix->add($domain, $prefix);
	system "cat $map";

	print "\n# delete { $domain => $prefix }\n";
	$ml_home_prefix->delete($domain);
	system "cat $map";
    }


=head1 DESCRIPTION

FML::Pcoess::Debug provides tiny FML::Process:: process emulator for
debug use.

It also provides dump_curproc() method to dump out $curproc structure
as string for documentation.

=head1 METHODS

=head2 new()

constructor.

=head2 dump_curproc($curproc)

dump curproc structure.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 TOOLS for debug

simplified version of FML::Process::* only used for debug.

=head2 mkdir

=head2 log

=head2 logwarn

=head2 logerror

=cut


# Descriptions: create directory $dir if needed.
#    Arguments: OBJ($self) STR($dir) STR($mode)
# Side Effects: create directory $dir
# Return Value: NUM(1 or 0)
sub mkdir
{
    my ($self, $dir, $mode) = @_;

    print STDERR "mkdir($dir, 0755);\n";
    mkdir($dir, 0755);
}


# Descriptions: log message.
#    Arguments: OBJ($self) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $msg, $msg_args) = @_;
    print STDERR "log: $msg\n";
}


# Descriptions: log message at level as warning.
#    Arguments: OBJ($self) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logwarn
{
    my ($self, $msg, $msg_args) = @_;
    print STDERR "warn: $msg\n";
}


# Descriptions: log message at level as critical error.
#    Arguments: OBJ($self) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($self, $msg, $msg_args) = @_;
    print STDERR "error: $msg\n";
}


=head2 ml_home_prefix($domain)

search ml_home_prefi in /etc/fml/ml_home_prefix
and return the prefix.

=cut


# Descriptions: $curproc->ml_home_prefix() emulator.
#    Arguments: OBJ($self) STR($domain)
# Side Effects: none
# Return Value: STR
sub ml_home_prefix
{
    my ($self, $domain) = @_;
    my $_domain = quotemeta($domain);

    use IO::Adapter;
    my $obj = new IO::Adapter "/etc/fml/ml_home_prefix";
    my $ent = $obj->find($_domain, { want => 'key,value', all => 1 });

    # debug
    for my $buf (@$ent) {
	my ($x_domain, $x_prefix) = split(/\s+/, $buf);
	return $x_prefix if "\L$x_domain\E" eq "\L$domain\E";
    }

    return '';
}


=head2 config()

return config object.

=cut


# Descriptions: return config object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub config
{
    my ($self) = @_;

    return( defined $self->{ config } ? $self->{ config } : undef );
}


=head2 dump_curproc($curproc)

dump the curproc structure.

=cut


# Descriptions: dump the curproc structure.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: non
# Return Value: none
sub dump_curproc
{
    my ($self, $curproc) = @_;

    print "CURPROC_BEGIN\n";
    my (@c) = sort keys %$curproc;
    for my $k (@c) {
	my $x = $curproc->{ $k };
	if (ref($x) eq 'HASH') {
	    printf "%-20s => HASH {\n", $k;
	    for my $v (sort keys %$x) {
		my $y = $x->{ $v };
		if (ref($y)) {
		    printf "%-20s    %-20s => %s\n", "", $v, ref($y);
		}
		else {
		    printf "%-20s    %s\n", "", $v;
		}
	    }
	    printf "%-20s }\n", "", $k;
	}
	elsif (ref($x)) {
	    printf "%-20s => %s\n", $k, ref($x);
	}
	else {
	    printf "%-20s => %s\n", $k, "SCALAR";
	}

	print "\n";
    }
    print "CURPROC_END\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Debug appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
