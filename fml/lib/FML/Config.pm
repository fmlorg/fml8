#-*- perl -*-
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $Id$
# $FML$ # 注意: cvs のタグを $FML$ にする
#

package FML::Config;

use strict;
use Carp;
use vars qw(%_fml_config %_default_fml_config);


sub new
{
    my ($self, $args) = @_;

    unless (defined %_fml_config) { %_fml_config = ( pid => $$ );}
    my $me = \%_fml_config;

    # import variables
    if (defined $args) {
	my ($k, $v);
	while (($k, $v) = each %$args) { set($me, $k, $v);}
    }

    return bless $me, $self;
}


sub dump_variables
{
    my ($self, $args) = @_;
    my ($k, $v);
    my $len  = 0;
    my $mode = $args->{ mode } || 'all';

    for $k (keys %_fml_config) { $len = $len > length($k) ? $len : length($k);}

    my $format = '%-'. $len. 's = %s'. "\n";
    for $k (sort keys %_fml_config) {
	next unless $k =~ /^[a-z0-9]/io;
	$v = $_fml_config{ $k };

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


sub _log
{
   my ($self, $msg) = @_;
   $self->{ _error_message } = $msg;
}


sub error
{
   my ($self) = @_;
   $self->{ _error_message };
}


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


sub overload 
{
    my ($self, $file) = @_;
    $self->load_file($file);
}


sub load_file
{
    my ($self, $file) = @_;
    my $config        = \%_fml_config;

    # open the $file by using FileHandle.pm
    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my ($key, $value, $curkey);

	while (<$fh>) {
	    last if /^=cut/; # end of postfix format
	    next if /^=/;    # ignore special keywords of pod formats
	    next if /^\#/;   # ignore comments

	    # here we go
	    chop;

	    if (/^([A-Za-z0-9_]+)\s+=\s*(.*)/) {
		my ($key, $value) = ($1, $2);
		$value =~ s/\s*$//o;
		$curkey           = $key;
		$config->{$key}   = $value;
	    }
	    if (/^\s+(.*)/) {
		my $value = $1;
		$value =~ s/\s*$//o;
		$config->{ $curkey }  .= " ". $value;
	    }
	}
	$fh->close;
    }
    else {
	$self->_log("Error: cannot open $file");
    }

    # first time
    unless (%_default_fml_config) {
	%_default_fml_config = %_fml_config;
    }
}


# expand variable name e.g. $dir/xxx -> /var/spool/ml/elena/xxx
sub expand_variables
{
    my ($self) = @_;
    _expand_variables( \%_default_fml_config );
    _expand_variables( \%_fml_config );

    # disable POSIX strftime() expansion which conflicts
    # printf() expansion
    # _expand_special_syntax( \%_fml_config );
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
	# a = $x/y and b = $a/c/0
	# 
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


sub _expand_special_syntax
{
    my ($config) = @_;
    my @order  = keys %$config;
    my $use_strftime = 0;

    for my $x ( @order ) {
	if ($config->{ $x } =~ /\%[a-zA-Z]/) { $use_strftime = 1;}
    }

    if ($use_strftime) {
	eval qq{ require POSIX; import POSIX qw(strftime);};
	unless ($@) {
	    for my $x ( @order ) {
		if ($config->{ $x } =~ /\%[a-zA-Z]/) { 
		    $config->{ $x } = strftime($config->{ $x }, localtime);
		}
	    }    
	}
    }
}


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


sub FETCH
{
    my ($self, $key) = @_;
    return $_fml_config{$key};
}


sub STORE
{
    my ($self, $key, $value) = @_;
    $_fml_config{$key} = $value;
}


sub DELETE
{
    my ($self, $key) = @_;
    delete $_fml_config{$key};
}


sub CLEAR
{
    my ($self) = @_;
    undef %_fml_config;
}


=head1 NAME

FML::Config -- fml5 configuration holding object

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


=head1 METHOD

=item  Init( ref_to_curproc )

special method only used in the initialization phase.
This method binds $curproc and the %_fml_config memory area.

=item  load_file( filename ) 

read the configuration file, split key and value and set them to
%_fml_config.

=item  get( key )

=item  set( key, value )

=item  dump_variables()

show all {key => value} for debug.

=head1 DATA STRUCTURE

C<%CurProc> holds the CURrent PROCess information.
The hash holds several references to other data structures,
which are mainly hashes.

    $CurProc = {
		# configurations
		config => {
		    key => value,
		},

		# emulator mode though fml mode in fact
		emulator => $emulator,

		# struct incoming_message holds the mail input from STDIN.
		incoming_message => $r_msg,
		article          => $r_msg,
		};

We use r_variable_name syntax where "r_" implies "reference to" here.
C<$r_msg> is the reference to "struct message".

    $r_msg = {
	r_header => \$header,
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

=cut

1;
