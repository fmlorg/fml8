#-*- perl -*-
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#
# $FML: Config.pm,v 1.32 2001/07/15 04:00:26 fukachan Exp $
#

package FML::Config;

use strict;
use Carp;
use vars qw($need_expansion_variables
	    %_fml_config_result
	    %_fml_config
	    %_default_fml_config);
use ErrorStatus qw(error_set error error_clear);


=head1 NAME

FML::Config -- manipulate fml5 configuration

=head1 SYNOPSIS

    $config = new FML::Config;

    # get the current value
    $config->{recipient_maps};

    # set the new value
    $config->{recipient_maps} = 'mysql:toymodel';

    # function style to get/set the value for the key "recipient_maps"
    $config->get('recipient_maps');
    $config->set('recipient_maps', 'mysql:toymodel');


=head1 DESCRIPTION

=head2 DATA STRUCTURE

C<$curproc> hash holds the CURrent PROCess information.
It contains several references to other data structures.

    $curproc = {
	# configurations
	config => {
	    key => value,
	},

	# struct incoming_message holds the mail input from STDIN.
	incoming_message => $r_msg,
	article          => $r_msg,
    };

where we use r_variable_name syntax where "r_" implies "reference to"
here.

For exapmle, this C<$r_msg> is the reference to a hash to represent a
mail message. It composes of header, body and several information.

    $r_msg = {
	r_header => \$header,p
	r_body   => \$body,
	info   => {
	    mime-version => 1.0, 
	    content-type => {
		charset      => ISO-2022-JP,
	    },
	    size         => $size,
	},
    };

where $header is the object returned by Mail::Header class (CPAN
module) and the $body is the reference to the mail body region on
memory which locates within FML::Parse name space.

=head2 DELAYED VALUE EXPANSION

data manipulation of set() and get() is assymetric and asynchronous.

C<set(key,value)> saves the value for a key in C<%fml_config>.

C<get(key)> returns the value for a key in C<%fml_config_result>,
which is value expanded C<%fml_config>.
The expansion is done when C<get()> is called not when C<set()> is
called.

=head1 METHODS

=head2  C<new( ref_to_curproc )>

special method used only in the fml initialization phase.
This method binds $curproc and the %_fml_config hash on memory.

Internally this method uses C<tie()> to get and set a key to a value.
For example, C<get()> and C<set()> described below is a wrapper for
tie() IO.

=cut


sub new
{
    my ($self, $args) = @_;

    unless (defined %_fml_config) { %_fml_config = ( pid => $$ );}

    # prepare the tied hash to %_fml_config;
    # to support $config->{ variable } syntax.
    my $me = {};
    tie %$me, $self;

    # import variables
    if (defined $args) {
	my ($k, $v);
	while (($k, $v) = each %$args) { set($me, $k, $v);}
    }

    return bless $me, $self;
}


=head2  C<get( key )>

=head2  C<set( key, value )>

=cut

sub get
{
    my ($self, $key) = @_;
    $self->{ $key };	
}


sub set
{
    my ($self, $key, $value) = @_;
    $self->{ $key } = $value;
}



=head2  C<overload( filename )>

alias of C<load_file( filename )>.

=head2  C<load_file( filename )>

read the configuration file, split keys and the values in it and set
them to %_fml_config.

=cut


sub overload 
{
    my ($self, $file) = @_;
    $self->load_file($file);
}


sub load_file
{
    my ($self, $file) = @_;
    my $config        = \%_fml_config;

    # read configuration file
    $self->_read_file({ 
	file   => $file, 
	config => $config,
    });

    # At the first time, save $config to another hash, which is used
    # as a default value at variable comparison.
    unless (%_default_fml_config) {
	%_default_fml_config = %_fml_config;
    }

    # flag on: we need $config->{ key } needs variable expansion
    $need_expansion_variables = 1;
}


# Descriptions: read configuration file and the keys and values to
#               $config (REF HASH).
#
#               XXX we should not reset $config since we permit
#               XXX $config can be overwritten.
#
#    Arguments: $self $file $config $options
#                     $file = configuration file
#                   $config = area to store {key => value } hash
#                  $options = REFHASH to describe a hash for options
# Side Effects: $config changes
# Return Value: none
sub _read_file
{
    my ($self, $args) = @_;
    my $file    = $args->{ 'file' };
    my $config  = $args->{ 'config' }  || {}; 
    my $comment = $args->{ 'comment' } || {};
    my $order   = $args->{ 'order' }   || [];
    my $mode    = defined $args->{ 'mode' } ? $args->{ 'mode' } : 'default';

    # open the $file by using FileHandle.pm
    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my ($key, $value, $curkey, $comment_buffer);

	# For example
	#    var = key1         (case 1.)
	#    var = key1 key2    (case 1.)
	#    var = key1         (case 1.)
	#          key2         (case 2.)
	# 
	while (<$fh>) {
	    last if /^=cut/; # end of postfix format
	    next if /^=/;    # ignore special keywords of pod formats
	    
	    if ($mode eq 'raw') { # save comment buffer
		if (/^\s*\#/) { $comment_buffer .= $_;}
	    }
	    else { # in 'default' mode, nuke trailing "\n"
		chop;
	    }

	    # case 1.
	    if (/^([A-Za-z0-9_]+)\s+=\s*(.*)/) {
		my ($key, $value)  = ($1, $2);
		$value             =~ s/\s*$//o;
		$curkey            = $key;
		$config->{ $key }  = $value;

		# save variable order for re-construction e.g. used in write()
		if ($mode eq 'raw') { 
		    $comment->{ $key } = $comment_buffer;
		    undef $comment_buffer;

		    push(@$order, $key);
		}
	    }
	    # case 2.
	    elsif (/^\s+(.*)/ && defined($curkey)) {
		my $value = $1;
		$value =~ s/\s*$//o;
		$config->{ $curkey }  .= " ". $value;
	    }
	}
	$fh->close;
    }
    else {
	$self->error_set("Error: cannot open $file");
    }
}


=head2 C<read(file)>

read configuration from the specified file. 
Internally it holds configuration and comment information in 
appearing order.

=head2 C<write(file)>

=cut

# allocate space to hold
my $config_hold_space = {};


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub read
{
    my ($self, $file) = @_;
    my $config  = {};
    my $comment = {};
    my $order   = [];

    $self->_read_file({ 
	file    => $file, 
	config  => $config,
	comment => $comment,
	order   => $order,
	mode    => 'raw',
    });

    # XXX debug: removed in the future
    if (0) {
	my ($k, $v);
	while (($k, $v) = each %$config) {
	    print STDERR "\n[$k]\n";
	    print STDERR " value  $v\n";
	    if (defined $comment->{ $k }) {
		my $comment = $comment->{ $k };
		print STDERR " comment\n{$comment}\n";
	    }
	}
    }

    # save the value in the object
    $config_hold_space->{ config }  = $config;
    $config_hold_space->{ comment } = $comment;
    $config_hold_space->{ order  }  = $order;
}


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub write
{
    my ($self, $file) = @_;
    my $config  = $config_hold_space->{ config };
    my $comment = $config_hold_space->{ comment };
    my $order   = $config_hold_space->{ order  };

    # get handle to update $file
    my $fh = IO::File::Atomic->open($file);

    if (defined $fh) {
	$fh->autoflush(1);
	for my $k (@$order) {
	    print $fh $comment->{$k} if defined $comment->{$k};
	    print $fh "$k = ";
	    print $fh join("\n\t", split(/\s+/, $config->{$k}));
	    print $fh "\n";
	    print $fh "\n";
	}    
	$fh->close;
    }
    else {
	use Carp;
	carp("cannot open > $file");
	Log("cannot open > $file");
    }
}


=head2 C<expand_variables()>

expand all variables in C<%_default_fml_config> and C<%_fml_config>.
The expanded result is saved in the same hash.

  XXX obsolete ? This method is used before hook is introduced.
  XXX Consider a hook may change the variable.
  XXX We should expand variables on demand in that case

=cut


# expand variable name e.g. $dir/xxx -> /var/spool/ml/elena/xxx
sub expand_variables
{
    my ($self) = @_;

    # always expand variables within itself.
    _expand_variables( \%_default_fml_config );

    # XXX 2001/05/05
    # XXX %_fml_config        has variables before expansion.
    # XXX %_fml_config_result has variables after expansion.
    %_fml_config_result = %_fml_config;
    _expand_variables( \%_fml_config_result );
}


sub _expand_variables
{
    my ($config) = @_;
    my @order  = keys %$config;

    # check whether the variable definition is recursive.
    # For example, definition "var_a = $var_a/b/c" causes a loop.
    for my $x ( @order ) {
	if ($config->{ $x } =~ /\$$x/) {
	    croak("loop1: definition of $x is recursive\n");
	}
    }

    # main expansion loop
    my $org = '';
    my $max = 0;
  KEY:
    for my $x ( @order ) {
	next KEY if $config->{ $x } !~ /\$/o;

	# we need a loop to expand nested variables, for example, 
	# "a = $x/y" and "b = $a/c/0" would be "b = $x/y/c/0"

	$max = 0;
      EXPANSION_LOOP:
	while ($max++ < 16) {
	    $org = $config->{ $x };
	    
	    $config->{$x} =~ 
		s/\$([a-z_]+[a-z0-9])/(defined $config->{$1} ? $config->{$1} : '')/ge;

	    last EXPANSION_LOOP if $config->{ $x } !~ /\$/o;
	    last EXPANSION_LOOP if $org eq $config->{ $x };

	    if ($config->{ $x } =~ /\$$x/) {
		croak("loop2: definition of $x is recursive\n");
	    }
        }

	if ($max >= 16) {
	    croak("variable expansion of $x causes infinite loop\n");
	} 
    }
}


=head2 C<yes( key )>

useful method to return 1 or 0 according the value to the given key.

=head2 C<no( key )>

useful method to return 1 or 0 according the value to the given key.

=head2 C<has_attribute( key, attribute )>

Some types of C<key> has a list as a value.
If C<key> has the C<attribute> in the list, return 1. 
return 0 if not.

=cut

sub yes
{
    my ($self, $key) = @_;
    if (defined $_fml_config{$key}) {
	$_fml_config{$key} eq 'yes' ? 1 : 0;
    }
    else {
	0;
    }
}


sub no
{
    my ($self, $key) = @_;
    $_fml_config{$key} eq 'no' ? 1 : 0;
}


# has_attribute( key, attribute )
# e.g. has_attribute( "available_command_list" , "help" );
sub has_attribute
{
    my ($self, $key, $attribute) = @_;
    my (@attribute) = split(/\s+/, $_fml_config{$key});

    for my $k (@attribute) {
	return 1 if $k eq $attribute;
    }

    return 0;
}


=head2  C<dump_variables()>

show all {key => value} for debug.

=cut

sub dump_variables
{
    my ($self, $args) = @_;
    my ($k, $v);
    my $len  = 0;
    my $mode = $args->{ mode } || 'all';

    $self->expand_variables();

    for $k (keys %_fml_config_result) { 
	$len = $len > length($k) ? $len : length($k);
    }

    my $format = '%-'. $len. 's = %s'. "\n";
    for $k (sort keys %_fml_config_result) {
	next unless $k =~ /^[a-z0-9]/io;
	$v = $_fml_config_result{ $k };

	# print out all keys
	if ($mode eq 'all') {
	    printf $format, $k, $v;
	}
	# compare the value with the default one
	# print key if values for the key differs.
	else {
	    if (defined $_default_fml_config{ $k }) {
		if ($v ne $_default_fml_config{ $k }) {
		    printf $format, $k, $v;
		}
	    }
	    else {
		printf $format, $k, $v;
	    }
	}
    }
}


=head1 TIEED HASH

tie() operations for hash are binded to \%_fml_config.
For example, C<get()> and C<set()> described above is a wrapper for
tie() IO.

=cut

sub TIEHASH
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%_fml_config;
    return bless $me, $type;
}


sub FETCH
{
    my ($self, $key) = @_;

    if ($need_expansion_variables) {
	$self->expand_variables();
	$need_expansion_variables = 0;
    }

    defined($_fml_config_result{$key}) ? $_fml_config_result{$key} : undef;
}


sub STORE
{
    my ($self, $key, $value) = @_;

    # inform fml we need to expand variable again when FETCH() is
    # called.
    if ($value =~ /\$/) { $need_expansion_variables = 1;}

    $_fml_config{$key} = $value;
}


sub DELETE
{
    my ($self, $key) = @_;

    delete $_fml_config_result{$key};
    delete $_fml_config{$key};
}


sub CLEAR
{
    my ($self) = @_;

    undef %_fml_config_result;
    undef %_fml_config;
}


1;
