package Mail::Message::Utils;

=head2 remove_subject_tag_like_string(str)

=cut

sub remove_subject_tag_like_string
{
    my ($str) = @_;
    $str =~ s/^\s*\W[-\w]+.\s*\d+\W//g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s*//g;
    $str;
}


1;
