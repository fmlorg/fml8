#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.6 2002/09/28 05:36:03 fukachan Exp $
#

package FML::Article::Summary;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Article::Summary - generate article summary

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: 
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    $me->{ _curproc } = $curproc;
    return bless $me, $type;
}


sub print
{
    my ($self, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $config->{ 'summary_file' };

    print STDERR "open summary_file=$file id=$id\n";

    use FileHandle;
    my $wh = new FileHandle ">> $file";
    if (defined $wh) {
	$wh->autoflush(1);
	my $info = $self->_prepare_info($id);
	$self->print_one_line_summary($wh, $info);
	$wh->close();
    }
}


sub _prepare_info
{
    my ($self, $id) = @_;
    my $curproc = $self->{ _curproc };

    use FML::Article;
    use Mail::Message;
    my $article = new FML::Article $curproc;
    my $file    = $article->filepath($id);
    my $msg     = new Mail::Message->parse( { file => $file } );
    my $header  = $msg->whole_message_header();
    my $address = $header->get( 'from' );

    # extract the first 15 bytes of user@domain part.
    use FML::Header;
    my $hdrobj = new FML::Header;
    $address = substr( $hdrobj->address_clean_up( $address ), 0, 15);

    # fold "\n"
    my $subject = $header->get( 'subject' );
    $subject =~ s/\s*\n/ /g;   
    $subject =~ s/\s+/ /g;

    my $info    = {
	id       => $id,
	address  => $address,
	subject  => $subject,
    };

    return $info;
}


sub print_one_line_summary
{
    my ($self, $wh, $info) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $style   = $config->{ 'summary_format_style' };

    if ($style eq 'fml4_compatible') {
	$self->_fml4_compatible_style_one_line_summary($wh, $info);
    }
    else {
	LogError("unknown \$summary_file_style: $style");
    }
}


sub _fml4_compatible_style_one_line_summary
{
    my ($self, $wh, $info) = @_;
    my $rdate = undef;

    eval q{
        use Mail::Message::Date;
        $rdate = new Mail::Message::Date;
    };

    if (defined $rdate) {
	my $date   = $rdate->{ 'log_file_style' };
	my $format = "%s [%d:%s] %s\n"; 
	my $id     = $info->{ id };
	my $addr   = $info->{ address };
	my $subj   = $info->{ subject };

	printf $wh $format, $date, $id, $addr, $subj;
    }
    else {
	LogError("date object undefined.");
    }
}


if ($0 eq __FILE__) {
    my $obj = new FML::Article::Summary;
    $obj->_one_line_summary("\%d \%s\n", [
				      1000,
				      "uja"
				      ]);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article::Summary appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
