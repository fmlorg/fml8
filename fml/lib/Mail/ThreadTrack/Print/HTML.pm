#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: HTML.pm,v 1.17 2003/02/11 11:22:56 fukachan Exp $
#

package Mail::ThreadTrack::Print::HTML;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

Mail::ThreadTrack::Print::HTML - print thread summary as HTML

=head1 SYNOPSIS

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 DESCRIPTION

See C<Mail::ThreadTrack::Print> for usage of this subclass.

=head1 METHODS

=head2 show_articles_in_thread(thread_id)

show articles as HTML in this thread.

=cut


use CGI qw/:standard/;
use Mail::ThreadTrack::Print::Utils qw(decode_mime_string STR2EUC);


# Descriptions: show articles as HTML in this thread
#    Arguments: OBJ($self) STR($thread_id)
# Side Effects: none
# Return Value: none
sub show_articles_in_thread
{
    my ($self, $thread_id) = @_;
    my $mode      = $self->get_mode || 'text';
    my $config    = $self->{ _config };
    my $spool_dir = $config->{ spool_dir };

    my $articles = $self->{ _hash_table }->{ _articles }->{ $thread_id };

    # XXX-TODO: who validates $thread_id ?
    print "<B>";
    print "show contents related with thread_id=$thread_id\n";
    print "</B>";
    print "<HR>";
    print "<PRE>\n";

    if (defined($articles) && defined($spool_dir) && -d $spool_dir) {
	use FileHandle;

	my $s = '';
	for my $article (split(/\s+/, $articles)) {
	    my $file = $self->filepath({
		base_dir => $spool_dir,
		id       => $article,
	    });

	    # XXX-TODO: care for non Japanese char(s).
	    # XXX-TODO: to avoid CSS bug, convert all special char(s).
	    # XXX-TODO: create method safe_html_string() in Mail::Message ?
	    if (-f $file) {
		my $fh = new FileHandle $file;

		if (defined $fh) {
		    my $buf;

		    while (defined($buf = $fh->getline())) {
			# ignore header part.
			next if 1 .. $buf =~ /^$/o;

			$s = STR2EUC($buf);
			$s =~ s/&/&amp;/g;
			$s =~ s/</&lt;/g;
			$s =~ s/>/&gt;/g;
			$s =~ s/\"/&quot;/g;
			print $s;
		    }
		    $fh->close;
		}
	    }
	}
    }

    print "</PRE>";
}


# Descriptions: show guide
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub __start_thread_summary
{
    my ($self, $args) = @_;
    my $config  = $self->{ _config };
    my $ml_name = $config->{ ml_name };
    my $fd      = $self->{ _fd } || \*STDOUT;
    my $action  = $curproc->safe_cgi_action_name();
    my $target  = '_top';

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

    # XXX-TODO: validate $action ?
    print $fd start_form(-action=>$action, -target=>$target);
    print $fd submit(-name => 'submit');
    print $fd reset(-name  => 'reset');
    print $fd "\n";

    # XXX-TODO: validate $ml_name ?
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


# Descriptions: finalize thread list.
#               close TABLE tag.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub __end_thread_summary
{
    my ($self, $args) = @_;
    my $fd = $self->{ _fd } || \*STDOUT;

    print $fd "</TABLE>\n";

    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print $fd end_form;
}


# Descriptions: This shows summary on C<$thread_id> in HTML language.
#               It is used in C<FML::CGI::ThreadSystem>.
#    Arguments: OBJ($self) HASH_REF($optargs)
# Side Effects: none
# Return Value: none
sub __print_thread_summary
{
    my ($self, $optargs) = @_;
    my $config    = $self->{ _config };
    my $ml_name   = $config->{ ml_name };
    my $spool_dir = $config->{ spool_dir };
    my $action    = $curproc->safe_cgi_action_name();
    my $target    = $config->{ thread_cgi_target_window } || '_top';

    my $date      = $optargs->{ date };
    my $age       = $optargs->{ age };
    my $status    = $optargs->{ status };
    my $tid       = $optargs->{ thread_id };
    my $articles  = $optargs->{ articles };
    my $aid       = (split(/\s+/, $articles))[0];

    # do nothing if the $thread_id is unknown.
    return unless $tid;

    # XXX-TODO: validate $action, $ml_name, $aid ...
    # <FORM ACTION=> ..>
    my $xtid = CGI::escape($tid);
    $action  = "${action}?ml_name=${ml_name}&article_id=$aid";

    $self->{ _table_count } = 1 unless defined $self->{ _table_count };
    if (($self->{ _table_count }++ % 5) == 0) {
	print "<TR>\n<TD>\n";
	print submit(-name => 'submit');
	print reset(-name  => 'reset');
    }

    print "<TR>\n";

    # XXX-TODO: validate $msg_base_url ?
    # show articles in this thread id
    print "<TD>";
    if (defined $config->{ msg_base_url }) {
	my $msg_base_url = $config->{ msg_base_url };
	my $url          = "$msg_base_url/msg$aid.html";
	print "<A HREF=\"$url\" TARGET=\"article\">\n";
	print $tid;
	print "\n</A>\n";
    }
    else {
	# XXX-TODO: validate $action ?
	print "<A HREF=\"$action&action=show\" TARGET=\"article\">\n";
	print $tid;
	print "\n</A>\n";
    }

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
	my $f = $self->filepath({
	    base_dir => $spool_dir,
	    id       => $aid,
	});
	if (-f $f) {
	    # XXX-TODO: care for non Japanese.
	    my $buf = $self->message_summary($f);
	    $self->print( STR2EUC($buf) );
	}
    }

    # addional information: age, status
    print "<TD>$age\n";
    print "<TD>$status\n";

    print "\n\n";
}


# Descriptions: dummy, defined for symmetry
#    Arguments: none
# Side Effects: none
# Return Value: none
sub __print_message_summary
{
    ;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::ThreadTrack::Print::HTML first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
