#!/usr/bin/env perl
#
# $FML: test.pl,v 1.1 2006/02/24 12:49:13 fukachan Exp $
#

use strict;
use Carp;
use vars qw($counter %variable);

my $config_file = shift || "./work/CF";
my $base_dir    = shift || "/var/tmp/fml4to8";

init();
read_config($config_file);

exit 0;


sub init
{
    use File::Path;
    mkpath([ $base_dir ], 0, 0755);
}


sub read_config
{
    my ($file) = @_;

    # initialized.
    $counter = 0;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $file) {
	my $buf;

      LINE:
	while ($buf = <$rh>) {
	    if ($buf =~ /^(\S+)\s*=\s*(.*)/) { 
		my ($name, $value) = ($1, $2);
		$variable{ $name } = $value;

		if ($name eq 'PERMIT_POST_FROM' ||
		    $name eq 'PERMIT_COMMAND_FROM') {
		    next LINE;
		}

		if ($name eq 'REJECT_POST_HANDLER') {
		    my (@v) = _expand( $variable{ PERMIT_POST_FROM } );
		    for my $_v (@v) {
			expand($name, $value, { PERMIT_POST_FROM => $_v } );
		    }
		}
		elsif ($name eq 'REJECT_COMMAND_HANDLER') {
		    my (@v) = _expand( $variable{ PERMIT_COMMAND_FROM } );
		    for my $_v (@v) {
			expand($name, $value, { PERMIT_COMMAND_FROM => $_v } );
		    }
		}
		else {
		    expand($name, $value);
		}
	    }
	}

	$rh->close();
    }
}


sub _expand
{
    my ($value) = @_;
    return split(/\s+\|\s+/, $value);
}


sub expand
{
    my ($name, $value, $opts) = @_;
    my (@v) = _expand($value);

    for my $v (@v) {
	$counter++;
	my $cf = config_ph_path($counter);
	my $wh = new FileHandle "> $cf";
	if (defined $wh) {
	    print $wh "\#\n";
	    print $wh "\# $counter\n";
	    print $wh "\#\n";
	    print $wh "\n";
	    print $wh "\$MAIL_LIST = \"elena\\\@fml.org\";\n\n";

	    if (defined $opts && %$opts) {
		my ($k, $v);
		while (($k, $v) = each %$opts) {
		    print $wh "\$${k} = \"$v\";\n\n";
		}
	    }

	    $v =~ s/\s*//g;
	    if ($v =~ /^\d+$/) {
		print $wh "\$${name} = $v;\n\n";
	    }
	    elsif ($v eq '""') {
		print $wh "\$${name} = \"\";\n\n";
	    }
	    elsif ($v) {
		print $wh "\$${name} = \"$v\";\n\n";
	    }
	    else {
		print $wh "\$${name} = \"\";\n\n";
	    }
	    print $wh "1;\n\n";
	    $wh->close();
	}
    }
}


sub config_ph_path
{
    my ($counter) = @_;

    use File::Spec;
    my $dir = File::Spec->catfile($base_dir, sprintf("%03d", $counter));
    unless (-d $dir) {
	use File::Path;
	mkpath([ $dir ], 0, 0755);
    }

    return File::Spec->catfile($dir, "config.ph");
}
