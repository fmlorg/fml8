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
use FML::Log qw(Log);

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

    # cut off Re: Re: Re: ...
    $self->_cut_off_reply(\$subject);

    # de-tag
    $subject = _delete_subject_tag( $subject, $tag );

    # cut off Re: Re: Re: ...
    $self->_cut_off_reply(\$subject);

    # add(prepend) the updated tag
    $tag = sprintf($tag, $ml_name, $args->{ id });
    my $new_subject = $tag." ".$subject;
    $header->replace('subject', $new_subject);
}


sub _delete_subject_tag
{
    my ($subject, $tag) = @_;
    my $retag = _regexp_compile($tag);

    $subject  =~ s/$retag//g;
    $subject  =~ s/^\s*//;

    return $subject;
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


sub is_reply
{
    my ($self, $subject) = @_;

    return 1 if $subject =~ /^\s*Re:/i;

    my $pkg = 'Dialect::Japanese::Subject';
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	return 1 if &Dialect::Japanese::Subject::is_reply($subject);
    };

    return 0;
}


sub _cut_off_reply
{
    my ($self, $r_subject) = @_;

    my $pkg = 'Dialect::Japanese::Subject';
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	$$r_subject = 
	    &Dialect::Japanese::Subject::cut_off_reply_tag($$r_subject);
    }
    else  {
	Log($@);
    }
}


sub execute_ticket_system
{
    my ($self, $header, $config, $args) = @_;
    my $model = $config->{ ticket_model };
    my $pkg   = "Ticket::Model::".$model;
    eval qq {require $pkg; $pkg->import();};
    
    $pkg->increment_id( $config->{ ticket_sequence_file });
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
