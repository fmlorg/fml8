#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: HTMLify.pm,v 1.4 2001/11/04 13:41:32 fukachan Exp $
#

package FML::Process::HTMLify;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::HTMLify -- yet another interface to htmlify

=head1 SYNOPSIS

See C<Mail::HTML::Lite> module.

=head1 DESCRIPTION

This class drives thread tracking system in the top level.

=head1 METHOD

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare()>

dummy.

=cut


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy to avoid to take data from STDIN 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub prepare
{
    ;
}


sub verify_request
{
    ;
}


=head2 C<run($args)>

call the actual thread tracking system.

=cut

sub run
{
    my ($curproc, $args) = @_;
    my $argv    = $curproc->command_line_argv();
    my $src_dir = $argv->[0];
    my $dst_dir = $argv->[1];

    unless (-d $src_dir) {
	croak("no such source directory");
    }

    if (defined $dst_dir) {
        unless (-d $dst_dir) {
            use File::Utils qw(mkdirhier);
            mkdirhier($dst_dir, 0755);
        }

	print STDERR "htmlify\t$src_dir =>\n\t\t$dst_dir\n";

        use Mail::HTML::Lite;
        &Mail::HTML::Lite::htmlify_dir($src_dir, { directory => $dst_dir });
    }
    else {
        croak("no destination directory\n");
    }
}


sub help
{
    use File::Basename;
    my $name = basename($0);

print <<"_EOF_";

Usage: $name src_dir dst_dir

_EOF_
}


sub DESTROY {}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
