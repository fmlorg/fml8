#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Scheduler.pm,v 1.3 2001/04/05 08:31:44 fukachan Exp $
#

package FML::Process::Scheduler;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);

=head1 NAME

FML::Process::Scheduler -- demonstration

=head1 SYNOPSIS

    use FML::Process::Configure;
    $curproc = new FML::Process::Configure;
    $curproc->run();

=head1 DESCRIPTION

FML::Process::Configure is the wrapper for fmlconf and makefml.
See C<FML::Process::Flow> for each method definition.

=head2 MODULES

These programs, 
C<fmlconf> and C<makefml>,
bootstrap by using these modules in this order.

   libexec/loader -> FML::Process::Switch -> FML::Process::Configure

=head1 METHODS

=head2 C<new($args)>

usual constructor.

=head2 C<prepare($args)>

dummy.

=cut


# avoid default fml new() since we do not need it.
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub prepare { ; }


sub run
{
    my ($self, $args) = @_;
    
    use FileHandle;
    use TinyScheduler;

    my $schedule = new TinyScheduler $args;
    my $tmp      = $schedule->tmpfile;
    my $fh       = new FileHandle $tmp, "w";

    # show three calender for this month, next month, last month
    my $show_3_month = defined($args->{ options }->{ a }) ? 1 : 0;
    if ($show_3_month) {
	for my $n ('this', 'next', 'last') {
	    $schedule->print_specific_month($fh, $n);
	}
    }
    else {
	$schedule->print_specific_month($fh, 'this');
    }

    $fh->close;

    my $mode = $args->{ options }->{ m } || 'text';
    if ($mode eq 'text') {
	system "w3m -dump $tmp";
    }
    else {
	system "cat $tmp";	
    }

    unlink $tmp;
}


# dummy to avoid the error ( undefined function )
sub AUTOLOAD
{
    ;
}

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Configure appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
