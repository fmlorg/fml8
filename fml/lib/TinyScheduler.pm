#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: TinyScheduler.pm,v 1.11 2001/11/27 11:32:34 fukachan Exp $
#

package TinyScheduler;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

TinyScheduler - scheduler with minimal functions

=head1 SYNOPSIS

    use TinyScheduler;
    my $schedule = new TinyScheduler;

    $schedule->parse;

    # show table by w3m :-) 
    my $tmp = $schedule->tmpfile;
    my $fh  = new FileHandle $tmp, "w";
    $schedule->print($fh);
    $fh->close;

    system "w3m -dump $tmp";
    unlink $tmp;

=head1 DESCRIPTION

demonstration module to show how to use and build up modules
especially to couple with CPAN and FML modules.

It parses files in ~/.schedule/ and output schedule of this month as
HTML TABLE by default.

To see it, you need WWW browser e.g. "w3m".

=head1 METHODS

=head2 new()

=cut


# Descriptions: usual constructor. $args is optional, which comes from
#               parameters from CGI.pm  if fmlsci.cgi uses.
#                    OR
#               libexec/loaders's $args if fmlsch uses.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: object
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    my $user   = defined $args->{ user } ? $args->{ user } : $ENV{'USER'};

    # default directory to hold schdule file(s): ~/.schedule/ by default
    use User::pwent;
    my $pw                  = getpwnam($user);
    my $home_dir            = $pw->dir;

    # XXX FML::Restriction / Taint
    # simple check (not enough mature) to avoid -T error ;)
    if ($home_dir =~ /^([\w\d\.\/]+)$/) {
	$home_dir = $1;
    }
    else {
	croak("invalid home directory");
    }

    $me->{ _user }          = $user;
    $me->{ _schedule_dir }  = "$home_dir/.schedule"; # ~/.schedule/ by default
    $me->{ _schedule_file } = undef;

    for my $key ('schedule_dir', 'schedule_file', 'mode') {
	if (defined $args->{ $key }) {
	    $me->{ "_$key" } = $args->{ $key };
	}
    }

    # reset PATH
    $ENV{'PATH'} = '/bin/:/usr/bin:/usr/pkg/bin:/usr/local/bin';

    return bless $me, $type;
}


# Descriptions: determine template file location
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: STR(filename)
sub tmpfile
{
    my ($self, $args) = @_;
    my $user = $self->{ _user };
    my $dir  = $self->{ _schedule_dir };
    my $tmpdir;

    if (-w $dir) {
	$tmpdir = $dir;
    }
    else {
	croak("$dir not exists\n")      unless -d $dir;
	croak("$dir is not writable\n") unless -w $dir;
    }

    eval q{ 
	use File::Spec;
	$self->{ _tmpfile } = File::Spec->catfile($tmpdir, ".tmp.$$.html");
    };
    croak($@) if $@;
    return $self->{ _tmpfile };
}


=head2 C<parse($args)>

=cut


# Descriptions: parse file(s)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: update calender entries in $self object
#               (actually by _add_entry() calleded here)
# Return Value: none
sub parse
{
    my ($self, $args) = @_;
    my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time);

    # get the date to show
    $year  = defined $args->{ year }  ? $args->{ year }  : (1900 + $year);
    $month = defined $args->{ month } ? $args->{ month } : ($month + 1);

    # schedule file
    my $data_dir  = $self->{ _schedule_dir };
    my $data_file = $self->{ _schedule_file };

    # pick up line matched with this pattern
    my @pat = (
	       sprintf("^%04d%02d(\\d{1,2})\\s+(.*)",   $year, $month),
	       sprintf("^%04d/%02d/(\\d{1,2})\\s+(.*)", $year, $month),
	       sprintf("^%04d/%d/(\\d{1,2})\\s+(.*)",   $year, $month),
	       sprintf("^%02d(\\d{1,2})\\s+(.*)",  $month),
	       sprintf("^%02d/(\\d{1,2})\\s+(.*)", $month),
	       );

    use HTML::CalendarMonthSimple;
    my $cal = new HTML::CalendarMonthSimple('year'=> $year, 'month'=> $month);

    if (defined $cal) {
	$self->{ _schedule } = $cal;
    }
    else {
	croak("cannot get object");
    }

    $cal->width('70%');
    $cal->border(10);
    $cal->header(sprintf("%04d/%02d %s",  $year, $month, "schedule"));
    $cal->bgcolor('pink');

    if ($data_file && -f $data_file) {
	$self->_analyze($data_file, \@pat);
    }
    elsif (-d $data_dir) {
	use DirHandle;
	my $dh = new DirHandle $data_dir;

	if (defined $dh) {
	    while (defined($_ = $dh->read)) {
		next if $_ =~ /~$/;
		next if $_ =~ /^\./;
		my $schedule_file = "$data_dir/$_";
		if (-f $schedule_file) {
		    $self->_analyze($schedule_file, \@pat);
		}
	    }
	}
    }
    else {
	croak("invalid data");
    }
}


# Descriptions: open, read specified $file
#               analyze the line which matches $pattern.
#    Arguments: OBJ($self) STR($file) STR($pattern)
# Side Effects: update $self object by _add_entry()
# Return Value: none
sub _analyze
{
    my ($self, $file, $pattern) = @_;

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
      FILE:
	while (<$fh>) {
	    for my $pat (@$pattern) {
		if (/$pat(.*)/) {
		    $self->_add_entry($1, $2);
		    next FILE;
		}
	    }

	    # for example, "*/24 something"
	    if (/^\*\/(\d+)\s+(.*)/) {
		$self->_add_entry($1, $2);
	    }
	}
	close($fh);
    }
}


# Descriptions: add calender entry to $self object
#    Arguments: OBJ($self) STR($day) STR($buf)
# Side Effects: update $self object
# Return Value: none
sub _add_entry
{
    my ($self, $day, $buf) = @_;
    my $cal = $self->{ _schedule };
    $day =~ s/^0//;

    $cal->addcontent($day, "<p>". $buf);
}


=head2 C<print($fd)>

print out the result as HTML.
You can specify the output channel by C<$fd>.

=cut


# Descriptions: print calender by HTML::CalenderMonthSimple::as_HTML() method
#    Arguments: OBJ($self) HANDLE($fd)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self, $fd) = @_;
    $fd = $fd || \*STDOUT;
    print $fd $self->{ _schedule }->as_HTML;
}


=head2 C<print_specific_month($fh, $n)>

print range specified by C<$n>.
C<$n> is one of C<this>, C<next> and C<last>.   

=cut


# Descriptions: print calender for specific month as HTML
#    Arguments: OBJ($self) HANDLE($fd) STR($month) [STR($year)] 
# Side Effects: none
# Return Value: none
sub print_specific_month
{
    my ($self, $fh, $month, $year) = @_;
    my ($month_now, $year_now) = (localtime(time))[4,5];
    my $default_year  = 1900 + $year_now;
    my $default_month = $month_now + 1;
    my ($thismonth, $thisyear) = ($default_month, $default_year);
    
    if ($month =~ /^\d+$/) {
	$thismonth = $month;
	$thisyear  = $year if defined $year;
    }
    else {
	if ($default_month == 1) {
	    $thismonth =  2 if $month eq 'next';
	    $thismonth = 12 if $month eq 'last';
	} 
	elsif ($default_month == 12) {
	    $thismonth =  1 if $month eq 'next';
	    $thismonth = 11 if $month eq 'last';
	}
	else {
	    $thismonth++ if $month eq 'next';
	    $thismonth-- if $month eq 'last';
	}
    }

    print $fh "<A NAME=\"$month\">\n";
    $self->parse( { month => $thismonth, year => $thisyear } );
    $self->print($fh);
}


=head2 set_mode( $mode )

=cut


# Descriptions: overwrite $mode 
#    Arguments: OBJ($self) STR($mode)
# Side Effects: update $self object
# Return Value: none
sub set_mode
{
    my ($self, $mode) = @_;
    $self->{ _mode } = $mode;
}


=head1 AUTHOR

Ken'chi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'chi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

TinyScheduler appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
