#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package TinyScheduler;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

TinyScheduler - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    my $user   = $args->{ user } || $ENV{'USER'};

    # directory
    use User::pwent;
    my $pw       = getpwnam($user);
    my $home_dir = $pw->dir;
    my $dir      = "$home_dir/.tsch";

    # ~/.schedule/ by default
    $me->{ _user }          = $user;
    $me->{ _schedule_dir }  = $dir;
    $me->{ _schedule_file } = $args->{ schedule_file } || "$dir/$user";

    return bless $me, $type;
}


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
	croak("Hmm, unsafe ? I cannot write $dir, stop\n");
    }

    $self->{ _tmpfile } = $tmpdir ."/$$.html";
    return $self->{ _tmpfile };
}


=head2 C<parse($args)>

=cut

sub parse
{
    my ($self, $args) = @_;
    my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time);

    # get the date to show
    $year  = $args->{ year }  || (1900 + $year);
    $month = $args->{ month } || ($month + 1);

    # schedule file
    my $data_file = $args->{ schedule_file } ||	$self->{ _schedule_file };

    # pattern to match
    my @pat;
    $pat[0] = sprintf("^%04d%02d(\\d{1,2})\\s+(.*)",  $year, $month);
    $pat[1] = sprintf("^%04d/%02d/(\\d{1,2})\\s+(.*)", $year, $month);
    $pat[2] = sprintf("^%02d(\\d{1,2})\\s+(.*)", $year, $month);
    $pat[3] = sprintf("^%02d/(\\d{1,2})\\s+(.*)", $year, $month);

    # 
    use HTML::CalendarMonthSimple;

    my $cal = new HTML::CalendarMonthSimple('year'=> $year, 'month'=> $month);

    if (defined $cal) {
	$self->{ _schedule } = $cal;
    }
    else {
	croak("cannot get object");
    }

    $cal->width('50%');
    $cal->border(10);
    $cal->header("$year/$month schedule");
    $cal->bgcolor('pink');

    if (-f $data_file) {
	use FileHandle;
	my $fh = new FileHandle $data_file;

	while (<$fh>) {
	    for my $pat (@pat) {
		if (/$pat(.*)/) {
		    $self->_parse($1, $2);
		}
	    }
	}
	close($fh);
    }
}


sub _parse
{
    my ($self, $day, $buf) = @_;
    my $cal = $self->{ _schedule };
    $cal->addcontent($day, "<p>". $buf);
}


sub print
{
    my ($self, $fd) = @_;
    $fd = $fd || \*STDOUT;
    print $fd $self->{ _schedule }->as_HTML;
}


if ($0 eq __FILE__) {
    eval q{
	my %options;

	use Getopt::Long;
	GetOptions(\%options, "e!");

	require FileHandle; import FileHandle;
	require TinyScheduler; import TinyScheduler;
	my $schedule = new TinyScheduler;

	if ($options{'e'}) {
	    my $editor = $ENV{'EDITOR'} || 'mule';
	    system $editor, '-nw', $schedule->{ _schedule_file };
	}

	$schedule->parse;

	my $tmp = $schedule->tmpfile;
	my $fh  = new FileHandle $tmp, "w";
	$schedule->print($fh);
	$fh->close;

	system "w3m -dump $tmp";

	unlink $tmp;
    };
    croak($@) if $@;
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
