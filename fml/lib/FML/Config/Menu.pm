#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Menu.pm,v 1.2 2004/11/21 07:01:32 fukachan Exp $
#

package FML::Config::Menu;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


my $debug = 0;


=head1 NAME

FML::Config::Menu - menu utility.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $menu   = {};
    my $result = {};
    my $me     = {
	_curproc => $curproc,
	_menu    => $menu,
	_result  => $result,
    };
    _init($me, $menu);

    return bless $me, $type;
}


# Descriptions: read config file and return menu object.
#    Arguments: OBJ($self) HASH_REF($menu)
# Side Effects: none
# Return Value: none
sub _init
{
    my ($self, $menu) = @_;
    my $curproc   = $self->{ _curproc };
    my $menu_path = $curproc->get_cui_menu();
    my ($i, $buf, $class);

    use FileHandle;
    my $rh = new FileHandle $menu_path;

  LINE:
    while ($buf = <$rh>) {
	last LINE if $buf =~ /^\.end\./o;
	next LINE if $buf =~ /^\#/o;

	chomp $buf;

	if ($buf =~ /^(\/[\/\S_]+|\/)/o) {
	    $class = $1;
	    $i     = 0;
	    next LINE;
	}

	if ($buf =~ /^\s+(.*)|^\s*$/) {
	    $buf = $1 || '';
	    $menu->{ $class }->[ $i ] = $buf;
	    print STDERR "menu{ $class }[$i] => $buf\n" if $debug;
	    $i++;
	}
    }

    return $class;
}


# Descriptions: run interactive menu.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub run_cui
{
    my ($self) = @_;
    my $menu   = $self->{ _menu };
    my $result = $self->{ _result };
    my $output = '';

    use Term::ReadLine;
    my $term     = new Term::ReadLine 'menu';
    my $prompt   = "select> ";
    my $wh       = $term->OUT || \*STDOUT;
    my $class    = '/';
    my $fallback = {};
    my $r;

    # show top menu.
    $self->_menu_print($wh, $menu, $class, $fallback);

  LOOP:
    while (defined ($r = $term->readline($prompt))) {
	if ($r eq 'q' || $r eq 'quit' || ($r eq '' && $class eq '/')) {
	    last LOOP;
	}

	if (defined $fallback->{ $r }->{ set }) {
	    $output .= $fallback->{ $r }->{ set } || '';
	}
	elsif (defined $fallback->{ $r }->{ next }) {
	    $class = $fallback->{ $r }->{ next };
	}

	# up if null input.
	if ($r eq '') {
	    $class = $self->_get_parent_class_name($class);
	}

	$fallback = {};
	$self->_menu_print($wh, $menu, $class, $fallback);
    }

    if ($output) {
	$self->{ _output } = $output;
	
	print STDERR "*** DIFF (debug) ***\n";
	print STDERR $output, "\n";
	print STDERR "*** DIFF END ***\n";
    }
}


# Descriptions: print menu for the specified class.
#    Arguments: OBJ($self)
#               HANDLE($wh) HASH_REF($menu) STR($class) HASH_REF($fallback)
# Side Effects: none
# Return Value: none
sub _menu_print
{
    my ($self, $wh, $menu, $class, $fallback) = @_;

    # XXX-TODO: clear if unix, cls on ms.
    system "clear";
    print $wh "*** CURRENT CLASS (debug) = $class ***\n";

    my $cur_mode = '';
    my $i    = 0;
    my $item = 0;
    my $ma   = $menu->{ $class } || [];
    my $k    = $#$ma;

  MENU:
    for (my $j = 0; $j <= $k ; $j++) {
	my $mbuf = $ma->[ $j ];

	# EXAMPLE: "_item_ ARTICLE_POST_POLICY"
	if ($mbuf =~ /^\s*_item_\s+(\S+)/o) {
	    my $next_layer = $1;
	    if ($next_layer =~ /^[A-Z0-9_]+$/) {
		if ($next_layer eq 'END') {
		    $fallback->{ $i }->{ next } =
			$self->_get_parent_class_name($class);
		}
		else {
		    $fallback->{ $i }->{ next } =
			sprintf("%s/%s", $class, $next_layer);
		}
		$fallback->{ $i }->{ next } =~ s@//@/@g;
	    }

	    # convert _item_ to NUM.
	    $item = $i;
	    $mbuf =~ s/_item_/$item/;
	    $i++;

	    print $wh $mbuf, "\n";
	}

	# end of special mode.
	if ($mbuf =~ /^\s*\}/o) {
	    $cur_mode = '';
	}

	# EXAMPLE: _set_ { ... }
	if ($mbuf =~ /^\s*_set_\s*\{(.*)/o) {
	    $cur_mode = 'set';
	    $fallback->{ $item }->{ set } .= $1;
	    $fallback->{ $item }->{ set } .= "\n";
	    next MENU;
	}
	if ($cur_mode eq 'set') {
	    $fallback->{ $item }->{ set } .= $mbuf;
	    $fallback->{ $item }->{ set } .= "\n";
	}
    }
}


# Descriptions: get parent class name and return it.
#    Arguments: OBJ($self) STR($class)
# Side Effects: none
# Return Value: none
sub _get_parent_class_name
{
    my ($self, $class) = @_;
    my $p_class = $class;

    $p_class =~ s@/[^\/]+$@@;
    $p_class =~ s@//@/@g;

    return( $p_class || '/' );
}


# Descriptions:
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub rewrite_config_cf
{
    my ($self) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };
    my $cf_file = $curproc->config_cf_filepath();

    # 1. save output into $tmp_file.
    my $output   = $self->{ _output } || '';
    my $tmp_file = $curproc->temp_file_path();
    my $wh = new FileHandle ">> $tmp_file";
    if (defined $wh) {
	print $wh "\n";
	print $wh $output;
	print $wh "\n";
	print $wh "=cut\n";
	print $wh "\n";
	$wh->close();
    }

    # 2. merge changes into the current configuration file.
    my $diff_org = $self->_get_diff_as_hash_ref($cf_file);
    my $diff_new = $self->_get_diff_as_hash_ref($cf_file, $tmp_file);

    # 3.
    print "\n// SUMMARY\n";
    my $diff = $self->_get_diff_between_hash_ref($diff_org, $diff_new);

    # 4. rewrite
    $config->merge_to_file($cf_file, $diff);
    for my $k (keys %$diff) {
	print "# configured by CUI.\n";
	print "$k = $diff->{ $k }\n";
	print "\n";
    }
}


# Descriptions: get difference between the current and default configuration.
#               return the result as HASH_REF.
#    Arguments: OBJ($self) VAR_ARGS(@files)
# Side Effects: none
# Return Value: HASH_REF
sub _get_diff_as_hash_ref
{
    my ($self, @files) = @_;

    my $config_tmp = new FML::Config;
    $config_tmp->read($files[0]);
    shift @files;
    for my $f (@files) {
	$config_tmp->overload($f);
    }
    return $config_tmp->dump_variables( { mode => 'get_diff_as_hash_ref' } );
}


# Descriptions: get difference between specified hashes.
#    Arguments: OBJ($self) HASH_REF($hash) HASH_REF($hash_new)
# Side Effects: none
# Return Value: HASH_REF
sub _get_diff_between_hash_ref
{
    my ($self, $hash, $hash_new) = @_;
    my $diff = {};

  KEY:
    for my $k (sort keys %$hash) {
	next KEY if $k =~ /\[/;
	if ($hash_new->{ $k } ne $hash->{ $k }) {
	    $diff->{ $k } = $hash_new->{ $k };
	}
    }

  KEY:
    for my $k (sort keys %$hash_new) {
	next KEY if $k =~ /\[/;
	if ($hash_new->{ $k } ne $hash->{ $k }) {
	    $diff->{ $k } = $hash_new->{ $k };
	}
    }

    return $diff;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Config::Menu appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
