#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::MapAdapter;
use strict;
use Carp;


BEGIN {}


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my ($me)   = {};

    if ( ref($args) eq 'CODE' ) {
	$me->{_type} = 'array_on_memory';
	eval { &$args($me);};
	_log($me, $@) if $@;
    }
    else {
	if ($args =~ /file:(\S+)/ || $args =~ m@^(/\S+)@) {
	    $me->{_file} = $1;
	    $me->{_type} = 'file';
	}
	elsif ($args =~ /unix\.group:(\S+)/) {
	    $me->{_name} = $1;
	    $me->{_type} = 'unix.group';
	}
	elsif ($args =~ /(ldap|mysql|postgresql):(\S+)/) {
	    $me->{_type}   = $1;
	    $me->{_schema} = $2;

	    # lowercase the '_type' syntax
	    $me->{_type}   =~ tr/A-Z/a-z/;
	}
	else {
	    my $s = "IO::MapAdapter::new: args='$args' is unknown.";
	    print STDERR $s, "\n";
	    _log($me, $s);
	}
    }

    return bless $me, $type;
}


sub _log
{
    my ($self, $mesg) = @_;
    $self->{ _error } = $mesg;
}


sub error
{
    my ($self) = @_;
    return $self->{ _error };
}


sub dump_variables
{
    my ($self, $args) = @_;
    my ($k, $v);
    while (($k, $v) = each %$self) {
	print STDERR "IO::Map.debug: $k => $v\n";
    }
}


sub open
{
    my ($self, $flag) = @_;

    # default flag is "r" == "read open"
    $flag ||= 'r';

    if ($self->{'_type'} eq 'file') {
	my $file = $self->{_file};
	eval q{ use FileHandle;};
	my $fh = new FileHandle $file, $flag;
	if (defined $fh) {
	    $self->{_fh} = $fh;
	    return $fh;
	}
	else {
	    $self->_log("Error: cannot open $file $flag");
	}
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	my @x = getgrnam( $self->{_name} );
	my @members = split ' ', $x[3];
	$self->{_members}     = \@members;
	$self->{_num_members} = $#members;
	$self->{_counter}     = 0;
	return defined @members ? \@members : undef;
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	my $r_array = $self->{ _recipients_array_on_memory };
	my @members = @$r_array;
	$self->{_members}     = $r_array;
	$self->{_num_members} = $#members;
	$self->{_counter}     = 0;
	return defined @members ? \@members : undef;
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	return undef;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


my $c = 0;
my $ec = 0;
sub line_count { my ($self) = @_; return "${ec}/${c}";}


# aliases for convenience
sub get_member    { my ($self) = @_; $self->_get_address;}
sub get_active    { my ($self) = @_; $self->_get_address;}
sub get_recipient { my ($self) = @_; $self->_get_address;}
sub _get_address
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my ($buf) = '';
	my $fh = $self->{_fh};

	if (defined $fh) {
	  INPUT:
	    while ($buf = <$fh>) {
		$c++; # for benchmark (debug)
		next INPUT if not defined $buf;
		next INPUT if $buf =~ /^\s*$/o;
		next INPUT if $buf =~ /^\#/o;
		next INPUT if $buf =~ /\sm=/o;
		next INPUT if $buf =~ /\sr=/o;
		next INPUT if $buf =~ /\ss=/o;
		last INPUT;
	    }

	    if (defined $buf) {
		my @buf = split(/\s+/, $buf);
		$buf    = $buf[0];
		$buf    =~ s/[\r\n]*$//o;
		$ec++;
	    }
	    return $buf;
	}
	return undef;
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	my $i  = $self->{_counter}++;
	my $ra = $self->{_members};
	defined $$ra[ $i ] ? $$ra[ $i ] : undef;
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	my $i  = $self->{_counter}++;
	my $ra = $self->{_members};
	defined $$ra[ $i ] ? $$ra[ $i ] : undef;
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	$self->_log("Error: not yet implemented");
	return undef;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


# raw line reading
sub getline
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	$fh->getline;
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	my $i  = $self->{_counter}++;
	my $ra = $self->{_members};
	defined $$ra[ $i ] ? $$ra[ $i ] : undef;
    }
    elsif ($self->{'_type'} eq 'ldap' ||
	   $self->{'_type'} eq 'mysql' ||
	   $self->{'_type'} eq 'postgresql'
	   ) {
	$self->_log("Error: not yet implemented");
	return undef;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


sub getpos
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	tell($fh);
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	$self->{_counter};
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	$self->{_counter};
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


sub setpos
{
    my ($self, $pos) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	seek($fh, $pos, 0);
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	$self->{_counter} = $pos;
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	$self->{_counter} = $pos;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


sub eof
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	my $fh = $self->{_fh};
	$fh->eof;
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	$self->{_counter} > $self->{_num_members} ? 1 : 0;
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	$self->{_counter} > $self->{_num_members} ? 1 : 0;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


sub close
{
    my ($self) = @_;

    if ($self->{'_type'} eq 'file') {
	$self->{_fh}->close;
    }
    elsif ($self->{'_type'} eq 'unix.group') {
	;
    }
    elsif ($self->{'_type'} eq 'array_on_memory') {
	;
    }
    else {
	$self->_log("Error: type=$self->{_type} is unknown type.");
    }
}


sub DESTROY
{
    my ($self) = @_;
    $self->close;
    undef $self;
}


1;
