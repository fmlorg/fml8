#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Sort.pm,v 1.4 2001/11/10 08:50:41 fukachan Exp $
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
sub show_articles_for_thread
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
    my $fd = $self->{ _fd } || \*STDOUT;

    print $fd "<TABLE BORDER=4>\n";
    print $fd "<TD>id\n";
    print $fd "<TD>summary\n";
    print $fd "<TD>age\n";
    print $fd "<TD>status\n";
    print $fd "<TD>change\n";
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
    $action  = "${action}?ml_name=${ml_name}";
    $action .= "&thread_id=$xtid&article_id=$aid";

    print "<TR>\n";
    print "<TD>";
    print "<A HREF=\"$action&action=show\"\n\tTARGET=\"$target.show\">";
    print $tid;
    print "\n</A>\n";

    print "<TD>";

    # summary
    if (defined $articles) {
	$aid = (split(/\s+/, $articles))[0];
	my $f = File::Spec->catfile($spool_dir, $aid);
	if (-f $f) {
	    my $buf = $self->message_summary($f);
	    $self->print( STR2EUC($buf) );
	}
    }

    print "<TD>$age\n";
    print "<TD>$status\n";
    print "<TD>";
    my $name    = "change-status=$tid";
    my $values  = ['open', 'analyzed', 'closed'];
    my $default = $status;
    print checkbox_group(-name=>$name, 
			 -values=>$values, 
			 -defaults=>$default,
			 -linebreak=>'true',
			 );

    # print "<A HREF=\"$action&action=close\" TARGET=\"$target.close\">";
    # print "[close]</A>\n";

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
