#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: log.pm,v 1.28 2005/08/17 10:33:17 fukachan Exp $
#

package FML::Command::Admin::log;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::log - log file operations.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

show log file(s).

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 0;}


# Descriptions: show log file.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config   = $curproc->config();
    my $log_file = $config->{ log_file };

    if (-f $log_file) {
	my $style = $curproc->get_print_style();
	$self->_show_log($curproc, $log_file, { printing_style => $style });
    }
}


# Descriptions: show cgi menu.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;
    my $config   = $curproc->config();
    my $log_file = $config->{ log_file };

    if (-f $log_file) {
	my $style = $curproc->get_print_style();
	$self->_show_log($curproc, $log_file, { printing_style => $style });
    }
}


# Descriptions: show log file.
#               This function is same as "tail -30 log" by default.
#    Arguments: OBJ($self) OBJ($curproc) STR($log_file) HASH_REF($sl_args)
# Side Effects: none
# Return Value: none
sub _show_log
{
    my ($self, $curproc, $log_file, $sl_args) = @_;
    my $is_cgi     = 1 if $sl_args->{ printing_style } eq 'html';
    my $line_count = 0;
    my $line_max   = 0;
    my $charset    = $curproc->langinfo_get_charset($is_cgi ? "cgi" : "log_file");

    # run "tail -100 log" by default.
    my $config       = $curproc->config();
    my $last_n_lines = $config->{ log_command_tail_starting_location } || 100;

    use Mail::Message::Encode;
    my $encode = new Mail::Message::Encode;

    use FileHandle;
    my $fh = new FileHandle $log_file;
    my $wh = \*STDOUT;

    if (defined $fh) {
	while (<$fh>) { $line_max++;}
	$fh->close();

	$fh = new FileHandle $log_file;
	my $s = '';
	$line_max -= $last_n_lines;

	if ($is_cgi) { print $wh "<pre>\n";}

	# show the last $last_n_lines lines by default.
	my $buf;
      LINE:
	while ($buf = <$fh>) {
	    next LINE if $line_count++ < $line_max;

	    $s = $encode->convert( $buf, $charset );

	    if ($is_cgi) {
		print $wh (_html_to_text($s));
		print $wh "\n";
	    }
	    else {
		print $wh $s;
	    }
	}
	$fh->close;

	if ($is_cgi) { print $wh "</pre>\n";}
    }
}


# Descriptions: convert text to html.
#    Arguments: STR($str)
# Side Effects: none
# Return Value: STR
sub _html_to_text
{
    my ($str) = @_;

    eval q{
	use HTML::FromText;
    };
    unless ($@) {
	return text2html($str, urls => 1, pre => 0);
    }
    else {
	croak($@);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::log first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
