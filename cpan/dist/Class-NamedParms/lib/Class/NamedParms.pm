package Class::NamedParms;

# $RCSfile: NamedParms.pm,v $ $Revision: 1.1 $ $Date: 1999/06/15 17:25:38 $ $Author: snowhare $

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '1.04';

=head1 NAME

Class::NamedParms - A lightweight named parameter handling system.

=head1 SYNOPSIS

 package SomePackage;
 use Class::NamedParms;
 use vars qw (@ISA);
 @ISA=qw(Class::NamedParms);

 sub new {	

	my ($proto) = shift;
    my ($class) = ref ($proto) || $proto;
	
    $self = Class::NamedParms->new(-benefits,-costs);
	$self = bless $self,$class;

	$self;
 }

 $thingy = SomePackage->new;
 $thingy->set({ -benefits => 1, -costs => 0.5 });
 my ($costs,$benefits) = $thingy->get(-costs,-benefits);

=head1 DESCRIPTION

Provides key name checking for named accessor parameters. This allows
the use of a generic 'get/set' type parameterized accessor while
automatically catching accidental mis-spellings and usage of uninitialized
parameters. This catches a large class of programming errors without requiring
a new accessor for every object parameter.

=head1 CHANGES

 1.00 1999.06.16 - Initial release.

 1.01 1999.06.17 - Bug fix to 'clear' method. Added 'make test' support.

 1.02 1999.06.18 - Performance tweak to 'get' method.

 1.03 1999.06.21 - Minor docs tweaks. Removal of 'use attrs' for portability

 1.04 1999.10.08 - Bug fix to 'all_parms' method 

=head2 Initialization

=cut

######################################################################

=over 4

=item C<new;>

Creates a new instance of a NamedParms object.

You can optionally 'declare' the legal parameter keys at the same time.

Example:

     my $self = Class::NamedParms(-benefits,-costs,-other);

=back

=cut

sub new {
    my ($class) = shift;
    my $self    = bless {},$class;

	$self->{-legal_parms} = {};
	$self->{-parm_values} = {};

    if ($#_ != -1) {
        $self->declare(@_);
    }

    $self;
}

######################################################################

=over 4

=item C<list_declared_parms;>

Returns a list of all parm names that have been declared for this 
NamedParms object. List is unsorted.

=back

=cut

sub list_declared_parms {
	my $self = shift;

	my (@parmnames) = keys %{$self->{-legal_parms}};
	return @parmnames;
}

######################################################################

=over 4

=item C<list_initialized_parms;>

Lists all parms that have had values initialized for this NamedParms object
Returns a list of the parameter names. List is unsorted.

=back

=cut

sub list_initialized_parms {
	my $self = shift;

	my (@parmnames) = keys %{$self->{-parm_values}};
	return @parmnames;
}

######################################################################

=over 4

=item C<declare($parmname,[$parmname1,...]);>

Declares one or more parameters for use with the NamedParms object.

Example:

   $self->declare(-moved_in,-car_key,-house_key,-relationship);

This *does not* initialize the parameters - only declares them
to be legal for use.

=back

=cut

sub declare {
	my $self = shift;

	my (@parmnames)  = @_;

	my $parmname;
	foreach $parmname (@parmnames) {
		$parmname       = lc ($parmname);
		$self->{-legal_parms}->{$parmname} = 1;
	}
}

######################################################################

=over 4

=item C<undeclare($parmname,$parmname1,...);>

'undeclares' one or more parameters for use with the NamedParms object.
This also deletes any values assigned to those parameters.

Example:

   $self->undeclare(-house_key,-car_key,-relationship);

=back

=cut

sub undeclare {
	my $self = shift;

	my (@parmnames)  = @_;

	my $parmname;
	foreach $parmname (@parmnames) {
		$parmname       = lc ($parmname);
		if (exists $self->{-legal_parms}->{$parmname}) {
			delete $self->{-legal_parms}->{$parmname};
			if (exists $self->{-parm_values}->{$parmname}) {
				delete $self->{-parm_values}->{$parmname};
			}
		} else {
			confess (__PACKAGE__ . "::undeclare() - Attempted to undeclare a parameter name ($parmname) that was never declared\n");
		}
	}
}

######################################################################

=over 4

=item C<exists($parmname);>

Returns true if the specified parmname has been initialized via 'set'.

=back

=cut

sub exists {
	my $self = shift;

	my ($parmname) = @_;
	$parmname      = lc $parmname;
	# The Perl built-in, not us.
	CORE::exists $self->{-parm_values}->{$parmname};
}

######################################################################

=over 4

=item C<set($parm_ref);>

Sets one or more named parameter values.

Example:

  $self->set({ -thingy => 'test', -other_thingy => 'more stuff' });

Will 'confess' if an attempt is made to set an undeclared parameter key.

=back

=cut

sub set {
	my $self = shift;

	my $parm_ref  = {};
	if ($#_ == 0) {
		$parm_ref = shift;
	} elsif ($#_ > 0) {
		%$parm_ref = @_;
	}
	
	my (@parmnames) = keys %$parm_ref;
	my $parmname;
	foreach $parmname (@parmnames) {
		my $keyname = lc ($parmname);
		my $value   = $parm_ref->{$parmname};
		confess (__PACKAGE__ . "::set() - Attempted to set an undeclared named parameter: '$keyname'\n") if (not exists $self->{-legal_parms}->{$keyname});	
		$self->{-parm_values}->{$keyname} = $value;
	}
}

######################################################################

=over 4

=item C<clear(@parm_names);>

Clears (deletes) one or more named parameter values.

Example:

     $self->clear(-this,-that,-the_other_thing);

Note: A 'cleared' value returns undef from 'get'.

=back

=cut

sub clear {
	my $self = shift;

	my (@parmnames) = @_;
	my $parmname;
	foreach $parmname (@parmnames) {
		my $keyname = lc ($parmname);
		confess (__PACKAGE__ . "::clear() - Attempted to clear an undeclared named parameter: '$keyname'\n") if (not exists $self->{-legal_parms}->{$keyname});	
		$self->{-parm_values}->{$keyname} = undef;
	}
}

######################################################################

=over 4

=item C<get(@parm_names);>

Gets one or more named parameter values. 

Screams and dies (well, 'confess'es) if you attempt to read
a value that has not been initialized. Results are returned
in the same order as the parameter names passed.

In a scalar context, the _last_ result is what is returned.

Example:

   my ($age,$gender) = $self->get(-age,-gender);

Will 'confess' if an attempt is made to access an undeclared key or if
the requested value has not been initialized.

=back

=cut

sub get {
	my $self = shift;

	if ($#_ == -1) { confess(__PACKAGE__ . "::get() - Called without any parameters\n"); }
	my (@results) = ();
	foreach (@_) {
		my $keyname = lc $_;
		if (not exists $self->{-parm_values}->{$keyname}) {
			confess (__PACKAGE__ . "::get() - Attempted to retrieve an undeclared or unitialized named parameter: '$keyname'\n");
		}
		push (@results,$self->{-parm_values}->{$keyname});
	}
	if (wantarray) {
		return @results;
	}
    $results[$#results];
}

################################################################

=over 4

=item C<all_parms;>

Returns an anonymous hash containing all the currently
set keys and values. This hash is suitable for usage
with Class::NamedParms or Class::ParmList for setting
keys/values with their 'set' methods.

It works by making a shallow copy of the data. This means 
that it copies the scalar values.  In the case of simple 
numbers and strings, this produces a new copy, in the case 
of references to hashes and arrays or objects, it returns 
the reference to the original object such that alterations
of the returned object are reflected in the live copy.

Example:

  my $parms = $parms->all_parms;

=back

=cut

sub all_parms {
	my ($self) = shift;
	my (@parm_list) = $self->list_initialized_parms;
	my ($all_p) = {};
	foreach my $parm (@parm_list) {
		$all_p->{$parm} = $self->get($parm);
	}
	$all_p;
}

#######################################################################

=head1 COPYRIGHT

Copyright 1999, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and 
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR    

Benjamin Franz  

=head1 VERSION

   1.04

=head1 TODO             

Debugging. 

=cut            

1;
