package Class::ParmList;

# $RCSfile: ParmList.pm,v $ $Revision: 1.4 $ $Date: 2000/12/07 00:06:26 $ $Author: snowhare $

use strict;
use Carp;
use Exporter;
use vars qw (@ISA $VERSION @EXPORT_OK %EXPORT_TAGS @EXPORT);

BEGIN {
    $VERSION     = '1.03';
    @ISA         = qw (Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = qw (simple_parms parse_parms);
    %EXPORT_TAGS = ();
}

my $error = '';

=head1 NAME

Class::ParmList - A collection of routines for processing named parameter lists for method calls.

=head1 SYNOPSIS

  use Class::ParmList qw(simple_parms parse_parms);

 $thingy->some_method({
      -bgcolor   => '#ff0000',
      -textcolor => '#000000'
	  });

 sub some_method {
     my ($self) = shift;

	 my ($parm_ref) = @_;

     my $parms = Class::ParmList->new ({
            -parms    => $parm_ref,
            -legal    => [qw (-textcolor -border -cellpadding)],
            -required => [qw (-bgcolor)],
            -defaults => {
                           -bgcolor   => "#ffffff",
                           -textcolor => "#000000"
                         }
         });

     if (not defined $parms) {
	    my $error_message = Class::ParmList->error;
		die ($error_message);
     }

     # Stuff...

 }

  sub another_method {
    my $self = shift;
    my ($name,$rank,$serial_number) = simple_parms([qw(-name -rank -serial_number)], @_);

    #...
  }

  sub still_another {
     my $parms = parse_parms ({
            -parms    => \@_,
            -legal    => [qw (-textcolor -border -cellpadding)],
            -required => [qw (-bgcolor)],
            -defaults => {
                           -bgcolor   => "#ffffff",
                           -textcolor => "#000000"
                         }
         });
     if (not defined $parms) {
	    my $error_message = Class::ParmList->error;
		die ($error_message);
     }

     # ...
  }

=head1 DESCRIPTION

This is a simple package for validating calling parameters to a subroutine or
method. It allows you to use "named parameters" while providing checking for
number and naming of parameters for verifying inputs are as expected and
meet any minimum requirements. It also allows the setting of default
values for the named parameters if omitted.

=cut

=head1 CHANGES

 1.00 1999.06.16 - Initial release

 1.01 1999.06.18 - Performance tweaks

 1.02 1999.06.21 - Fixing of failure to catch undeclared parm,
                   removal of 'use attrs qw(method)', and
				   extension of 'make test' support.

 1.03 2000.12.06 - Added exportable class functions 'simple_parms'
                   and 'parse_parms' and allowed 'stacking' references
                   for parms to the object to improve calling usage.

=head1 METHODS

=over 4

=item C<new($parm_list_ref);>

Returns a reference to an object that can be used to return
values. If an improper specification is passed, returns 'undef'.
Otherwise returns the reference.

Example:

     my $parms = Class::ParmList->new ({
            -parms    => $parm_ref,
            -legal    => [qw (-textcolor -border -cellpadding)],
            -required => [qw (-bgcolor)],
            -defaults => {
                           -bgcolor   => "#ffffff",
                           -textcolor => "#000000"
                         }
         });
All four parameters (-parms, -legal, -required, and -defaults) are
optional. It is liberal in that anything defined for a -default
or -required is automatically added to the '-legal' list.

If the '-legal' parameter is not _explicitly_ called out, no
checking against the legal list is done. If it _is_ explicitly
called out, then all -parms are checked against it and it will
fail with an error if a -parms parameter is present but not
defined in the -legal explict or implict definitions.

To simplify calling routines, the '-parms' parameters is allowed
to 'stack' anon list references: [['parm','value']]

This gives a calling routine the ability to parse @_ without
jumping through hoops to handle the cases of arrays vs hashes for
the passed parameters.

Example:

 sub example_sub {
   my $parms = Class::ParmList->new({ -parms => \@_,
                                     -legal => [],
                                  -required => ['-file','-data'],
                                  -defaults => {},
                                  });

   #...
 }

This routine would accept *either*

   example_sub({ '-file' => 'test', '-data' => 'stuff' });

or

   example_sub( '-file' => 'test', '-data' => 'stuff' );

with no code changes.

=back

=over 4

=item C<parse_parms($parm_list_ref);>

This is a functional equivalent to the 'new' method. Calling
parameters are identical, but it is called as a function
that may be exported.

Example:

   my $parms = parse_parms({ -parms => \@_,
                             -legal => [],
                          -required => ['-file','-data'],
                          -defaults => {},
                         });

=back

=cut

sub parse_parms {
    my $parms = new(__PACKAGE__, @_);
    return $parms;
}

sub new {
	my ($something) = shift;
    my $package     = __PACKAGE__;
	my ($class)     = ref ($something) || $something || $package;
	my $self = bless {},$class;

	# Clear any outstanding errors
	$error = '';

	if (-1 == $#_) { # It's legal to pass no parms.
		$self->{-name_list} = [];
		$self->{-parms}     = {};
		return $self;
	}

	my $raw_parm_list = {};
	my $reftype = ref $_[0];
	if ($reftype eq 'HASH') { # A basic HASH setup
		($raw_parm_list) = @_;
	} else {  # An unwrapped list
		%$raw_parm_list = @_;
	}

	# Transform to lowercase keys on our own parameters
	my $parms = {};
	%$parms = map { (lc($_),$raw_parm_list->{$_}) } keys %$raw_parm_list;
	
	# Check for bad parms
	my @parm_keys = keys %$parms;
	my @bad_parm_keys = grep(!/^-(parms|legal|defaults|required)$/,@parm_keys);
	if ($#bad_parm_keys > -1) {
		$error = "Invalid parameters ("."@bad_parm_keys".") passed to Class::ParmList->new\n";
		return;
	}

	my $check_legal    = 0;
	my $check_required = 0;

	# Legal Parameter names
	my $legal_names = {};
	if (defined $parms->{-legal}) {
		%$legal_names = map { (lc($_),1) } @{$parms->{-legal}};
		$check_legal = 1;
	}

	# Required Parameter names
	my $required_names = {};
	if (defined $parms->{-required}) {
		my $lk;
		%$required_names = map { $lk = lc $_; $legal_names->{$lk} = 1; ($lk,1) } @{$parms->{-required}};
		$check_required = 1;
	}

	# Set defaults if needed
	my $parm_list = {};
	my $defaults = $parms->{-defaults};
	if (defined $defaults) {
		my $lk;
		%$parm_list = map { $lk = lc $_; $legal_names->{$lk} = 1; ($lk,$defaults->{$_}) } keys %$defaults;
	}

	# The actual list of parms
	my $base_parm_list = $parms->{-parms};
    # Unwrap references to ARRAY referenced parms
    while (defined($base_parm_list) && (ref($base_parm_list) eq 'ARRAY')) {
        my @data = @$base_parm_list;
        if ($#data == 0) {
            $base_parm_list = $data[0];
        } else {
            $base_parm_list = { @data };
        }
    }

	if (defined ($base_parm_list)) {
        my @key_list = keys %$base_parm_list;
        foreach my $key (@key_list) {
            $parm_list->{lc($key)} = $base_parm_list->{$key};
        }
	}

	# Check for Required parameters
	if ($check_required) {
		foreach my $name (keys %$required_names) {
			next if (exists $parm_list->{$name});
			$error .= "Required parameter '$name' missing\n";
		}
	}

	# Check for illegal parameters
	my $final_parm_names = [keys %$parm_list];
	if ($check_legal) {
		foreach my $name (@$final_parm_names) {
			next if (exists $legal_names->{$name});
			$error .= "Parameter '$name' not legal here.\n";
		}
		$self->{-legal} = $legal_names;
	}

	return if ($error ne '');

	# Save the parms for accessing
	$self->{-name_list} = $final_parm_names;
	$self->{-parms}     = $parm_list;

	$self;	
}

################################################################

=over 4

=item C<get($parm_name1,$parm_name2,...);>

Returns the parameter value(s) specified in the call line. If
a parameter is not defined, it returns undef. If a set of
'-legal' parameters were declared, it croaks if a parameter
not in the '-legal' set is asked for.

Example:
  my ($help,$who) = $parms->get(-help,-who);

=back

=cut

sub get {
	my ($self) = shift;

	my (@parmnames) = @_;
	if ($#parmnames == -1) {
		croak(__PACKAGE__ . '::get() called without any parameters');
	}
	my (@results) = ();
	my $parmname;
	foreach $parmname (@parmnames) {
		my $keyname = lc ($parmname);
		croak (__PACKAGE__ . "::get() called with an illegal named parameter: '$keyname'") if (exists ($self->{-legal}) and not exists ($self->{-legal}->{$keyname}));	
		push (@results,$self->{-parms}->{$keyname});
	}
	if (wantarray) {
		return @results;
	} else {
		return $results[$#results];
	}
}

################################################################

=over 4

=item C<exists($parm_name);>

Returns true if the parameter specifed by $parm_name (qv.
has been initialized), false if it does not exist.

  if ($parms->exists(-help) {
      # do stuff
  }

=back

=cut

sub exists {
	my ($self) = shift;
	
	my ($name) = @_;

	$name = lc ($name);
	CORE::exists ($self->{-parms}->{$name});
}

################################################################

=over 4

=item C<list_parms;>

Returns the list of parameter names. (Names are always
presented in lowercase).

Example:

  my (@parm_names) = $parms->list_parms;

=back

=cut

sub list_parms {
	my ($self) = shift;

	my (@names) = @{$self->{-name_list}};

	return @names;
}

################################################################

=over 4

=item C<all_parms;>

Returns an anonymous hash containing all the currently
set keys and values. This hash is suitable for usage
with Class::NamedParms or Class::ParmList for setting
keys/values. It works by making a shallow copy of
the data. This means that it copies the scalar values.
In the case of simple numbers and strings, this produces
a new copy, in the case of references to hashes and arrays or
objects, it returns the references to the original objects.

Example:

  my $parms = $parms->all_parms;

=back

=cut

sub all_parms {
	my ($self) = shift;

	my (@parm_list) = $self->list_parms;
	my ($all_p) = {};
	foreach my $parm (@parm_list) {
		$all_p->{$parm} = $self->get($parm);
	}
	$all_p;
}

=head1 FUNCTIONS

################################################################

=over 4

=item C<error;>

Returns the error message for the most recent invokation of
'new'.  (Static method - does not require an object to function)

Example:

     my $error_message = Class::ParmList->error;
     die ($error_message);

=back

=cut

sub error {
	$error;
}

#######################################################################

=over 4

=item C<simple_parms(['-list','-of','-parameter_names'],@_);>

Parses the passed named parameter list (croaking/confessing if extra or
missing parameters are found).

Examples:

 use Class::ParmList qw(simple_parms);

 sub some_method {
    my $self = shift;

    my ($name,$rank) = simple_parms([qw(-name -rank)],@_);
    # Now do stuff
 }

 sub some_function {
    my $serial_number = simple_parms([qw(-serial_number)],@_);
    # Now do stuff
 }

The passed parameter values for parsing this way may be either an anonymous hash of parameters

Example:
   a_function({ -parm1_name => $parm1_value, -parm2_name => $parm2_value }) )

or a straight list of parameters:

Example:
  a_function(-parm1_name => $parm1_value, -parm2_name => $parm2_value) )

Note that it *IS* legal for a parameter to be passed with an 'undef' value - it
will not trigger an error.

If you need optional parameters, this function is not well suited. You should
use the object methods above instead for that case - they are much more
flexible (but quite a bit slower and slightly more complex to use).

Its main virtues are that is is simple to use, has rugged error checking for
mis-usages and is reasonably fast.

'simple_parms' can be exported by specifying it on the 'use' line.

=back

=cut

sub simple_parms {
    local $SIG{__DIE__} = '';
    my $parm_list = shift;
    if (not (ref($parm_list) eq 'ARRAY')) {
        confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - The first parameter to 'simple_parms()' must be an anonymous list of parameter names.");
    }

    if (($#_ > 0) && (($#_ + 1) % 2)) {
        confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - Odd number of parameter array elements");
    }

    # Read any other passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift;
    } elsif ($#_ > 0) {
        if (($#_ + 1) % 2) {
            confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - Odd number of parameter array elements");
        }
        %$parm_ref = @_;
    }

    if (ref ($parm_ref) ne 'HASH') {
        confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - A bad parameter list was passed (not either an anon hash or an array)");
    }

    my @parm_keys = keys %$parm_ref;
    if ($#parm_keys != $#$parm_list) {
        confess ('[' . localtime(time) . '] [error] ' .  __PACKAGE__ . ":simple_parms() - An incorrect number of parameters were passed");
    }
   if ($#parm_keys == -1) {
        croak ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - At least one parameter is required to be requested");
    }

    my @extra_parms    = ();
    my %checkoff_parms = ();
    my @parsed_parms   = ();
    foreach my $parm_name (@$parm_list) {
        $checkoff_parms{"'$parm_name'"} = 1;
        push (@parsed_parms,$parm_ref->{$parm_name});
    }
    foreach my $parm_name (@parm_keys) {
        if (not exists $parm_ref->{$parm_name}) {
            push (@extra_parms,"'$parm_name'");
        } else {
            delete $checkoff_parms{"'$parm_name'"};
        }
    }
    my @missing_parms = keys %checkoff_parms;
    my $errors = '';
    if ($#missing_parms > -1) {
        $errors = "Parameters " . join (', ',@missing_parms) . " were not found.";
    }
    if ($#extra_parms > -1) {
        $errors .= "Parameters " . join (', ',@extra_parms) . " are not legal here.";
    }
    if ($errors ne '') {
        confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - $errors");
    }
    if (wantarray) {
        return (@parsed_parms);
    }
    if ($#parsed_parms > 0) {
        croak ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - Requested multiple values in a 'SCALAR' context.");
    }
    $parsed_parms[0];
}

#######################################################################
# Non-public methods                                                  #
#######################################################################

#######################################################################

# Keeps 'AUTOLOAD' from sucking cycles during object destruction
sub DESTROY {}

#######################################################################

=head1 VERSION

1.03 2000.12.06

=head1 COPYRIGHT

Copyright 1999,2000 Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Everything.

=cut

1;
