#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Debug.pm,v 1.4 2003/08/23 04:35:38 fukachan Exp $
#

package FML::Process::Debug;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::Debug - debug tool

=head1 SYNOPSIS

=head1 DESCRIPTION

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


# Descriptions: create directory $dir if needed
#    Arguments: OBJ($self) STR($dir) STR($mode)
# Side Effects: create directory $dir
# Return Value: NUM(1 or 0)
sub mkdir
{
    my ($self, $dir, $mode) = @_;

    print STDERR "mkdir($dir, 0755);\n";
    mkdir($dir, 0755);
}


# Descriptions: log message
#    Arguments: OBJ($self) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $msg, $msg_args) = @_;
    print STDERR "log: $msg\n";
}


# Descriptions: log message
#    Arguments: OBJ($self) STR($msg) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub logwarn
{
    my ($self, $msg, $msg_args) = @_;
    print STDERR "warn: $msg\n";
}


# Descriptions: log message
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

    use IO::Adapter;
    my $obj = new IO::Adapter "/etc/fml/ml_home_prefix";
    my $ent = $obj->find($domain, { want => 'key,value', all => 1 });

    # debug
    for my $buf (@$ent) {
	my ($x_domain, $x_prefix) = split(/\s+/, $buf);
	return $x_prefix if $x_domain eq $domain;
    }

    return '';
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

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Debug appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
