#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: HTML.pm,v 1.4 2001/11/11 00:57:36 fukachan Exp $
#

package Mail::ThreadTrack::Print::HTML;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use CGI qw/:standard/;

use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);


# Descriptions: show articles as HTML in this thread
#    Arguments: $self $str
# Side Effects: none
# Return Value: none
sub show_articles_in_thread
{
    my ($self, $thread_id) = @_;
    my $mode      = $self->get_mode || 'text';
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };

    my $articles = $self->{ _hash_table }->{ _articles }->{ $thread_id };

    print "<B>";
    print "show contents related with thread_id=$thread_id\n";
    print "</B>";
    print "<HR>";
    print "<PRE>\n";

    if (defined($articles) && defined($spool_dir) && -d $spool_dir) {
	use FileHandle;

	my $s = '';
	for (split(/\s+/, $articles)) {
	    my $file = File::Spec->catfile($spool_dir, $_);
	    my $fh   = new FileHandle $file;
	    while (defined($_ = $fh->getline())) {
		next if 1 .. /^$/;

		$s = STR2EUC($_);
		$s =~ s/&/&amp;/g;
		$s =~ s/</&lt;/g;
		$s =~ s/>/&gt;/g;
		$s =~ s/\"/&quot;/g;
		print $s;
	    }
	    $fh->close;
	}
    }

    print "</PRE>";
}


# Descriptions: show guide
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub __start_thread_summary
{
    my ($self, $args) = @_;
    my $config  = $self->{ _config };
    my $ml_name = $config->{ ml_name };
    my $fd      = $self->{ _fd } || \*STDOUT;
    my $action  = "fmlthread.cgi";
    my $target  = "ResultsWindow";

    # statistics
    if (defined $self->{ _ticket_id_stat }) {
	my $stat = $self->{ _ticket_id_stat };
	for my $key ('open', 'analyzed', 'closed') {
	    print $fd "$key: ";
	    print $fd defined $stat->{ $key } ? $stat->{ $key } : 0;
	    print $fd ", ";
	}
	print $fd br, "\n";
    }

    print $fd start_form(-action=>$action, -target=>$target);
    print $fd submit(-name => 'submit');
    print $fd reset(-name => 'reset');
    print $fd "\n";

    print $fd hidden(-name    => 'ml_name',
		     -default => [ $ml_name ],
		     ), "\n";

    param('action', 'change_status'); # we need to override
    print $fd hidden(-name    => 'action',
		     -default => [ 'change_status ' ],
		     ), "\n";

    print $fd "<TABLE BORDER=4>\n";
    print $fd "<TD>id\n";
    print $fd "<TD>change\n";
    print $fd "<TD>summary\n";
    print $fd "<TD>age\n";
    print $fd "<TD>status\n";
}


# Descriptions: finalize thread list
#               close TABLE tag
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub __end_thread_summary
{
    my ($self, $args) = @_;
    my $fd = $self->{ _fd } || \*STDOUT;

    print $fd "</TABLE>\n";

    print submit(-name => 'submit');
    print reset(-name => 'reset');
    print $fd end_form;
}


# Descriptions: This shows summary on C<$thread_id> in HTML language.
#               It is used in C<FML::CGI::ThreadSystem>.
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub __print_thread_summary
{
    my ($self, $optargs) = @_;
    my $config    = $self->{ _config };
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $action    = 'fmlthread.cgi';
    my $target    = $config->{ thread_cgi_target_window } || 'ThreadCGIWindow';

    my $date     = $optargs->{ date };
    my $age      = $optargs->{ age };
    my $status   = $optargs->{ status };
    my $tid      = $optargs->{ thread_id };
    my $articles = $optargs->{ articles };
    my $aid      = (split(/\s+/, $articles))[0];

    # do nothing if the $thread_id is unknown.
    return unless $tid;

    # <FORM ACTION=> ..>
    my $xtid = CGI::escape($tid);
    $action  = "${action}?ml_name=${ml_name}&article_id=$aid";

    $self->{ _table_count } = 1 unless defined $self->{ _table_count };
    if (($self->{ _table_count }++ % 5) == 0) {
	print "<TR>\n<TD>\n";
	print submit(-name => 'submit'), reset(-name => 'reset');
    }

    print "<TR>\n";

    # thread id
    print "<TD>";
    print "<A HREF=\"$action&action=show\" TARGET=\"lower\">\n";
    print $tid;
    print "\n</A>\n";

    # action
    print "<TD>";
    my $name    = "change_status.$tid";
    my $values  = ["open", "analyzed", "closed"];
    my $default = $status;
    print radio_group(-name      => $name, 
		      -values    => $values, 
		      -default   => $default,
		      -linebreak => 'true',
		      );

    # message (article) brief summary
    print "<TD>";
    if (defined $articles) {
	$aid = (split(/\s+/, $articles))[0];
	my $f = File::Spec->catfile($spool_dir, $aid);
	if (-f $f) {
	    my $buf = $self->message_summary($f);
	    $self->print( STR2EUC($buf) );
	}
    }

    # addional information: age, status
    print "<TD>$age\n";
    print "<TD>$status\n";

    print "\n\n";
}


# Descriptions: dummy
#    Arguments: none
# Side Effects: none
# Return Value: none
sub __print_message_summary
{
    ;
}


1;
