#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Header::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub rewrite_subject_tag
{
    my ($self, $header, $config, $args) = @_;

    # for example, ml_name = elena
    my $ml_name = $config->{ ml_name };
    my $tag     = $config->{ subject_tag };
    my $subject = $header->get('subject');

    # de-tag
    my $retag   = _regexp_compile($tag);
    $subject  =~ s/$retag//g;
    $subject  =~ s/^\s*//;

    # add the updated tag
    $tag = sprintf($tag, $ml_name, $args->{ id });
    my $new_subject = $tag." ".$subject;
    $header->replace('subject', $new_subject);
}


# Descriptions: create regexp for a subject tag, for example
#               "[%s %05d]" => "\[\S+ \d+\]"
#    Arguments: a subject tag string
# Side Effects: none
# Return Value: a regexp for the given tag
sub _regexp_compile
{
    my ($s) = @_;

    $s =~ s@\%s@\\S+@g;
    $s =~ s@\%0\d+d@\\d+@g;
    $s =~ s@\%\d+d@\\d+@g;

    $s =~ s/^(.)/\\$1/;
    $s =~ s/(.)$/\\$1/;

    $s;
}



=head1 NAME

FML::Header::Subject.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut


1;
