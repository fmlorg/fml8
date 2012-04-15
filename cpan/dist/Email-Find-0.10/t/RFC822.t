use Test::More tests => 2;

BEGIN {
    use_ok('Email::Find');
}


open(RFC, "t/rfc822.txt") or die $!;
my $text = join "", <RFC>;

# Commented out emails are those which are not fully-qualified domains.
# These will be supported at a later date.
my @Expect = (
#               'ddd@Org',
#               'JJV@BBN',
#               'ddd@Org',
#               'JJV@BBN',
#               'ddd@Org',
#               'JJV@BBN',
#               'ddd@Org',
#               'JJV@BBN',
              '":sysmail"@Some-Group.Some-Org',
              'Muhammed.Ali@Vegas.WBA',
#              '":sysmail"@Some-Group.Some-Org',  # these deal with LWSP
#              'Muhammed.Ali@Vegas.WBA',          # which we don't
#              '"Full Name"@Domain',
              'person@registry.organization',
              'user@host.network',
              'sender@registry-A.registry-1.organization-X',
              'recipient@registry-B.registry-1.organization-X',
              'recipient@registry-C.registry-2.organization-X',
              'First.Last@Registry.Org',
#              'mailbox.sub1.sub2@this-domain',
              'sub-net.mailbox@sub-domain.domain',
#              'Postmaster@domain',
#              'Neuman@BBN-TENEXA',
#              'Neuman@BBN-TENEXA',
#              'Neuman@BBN-TENEXA',
#              'Neuman@BBN-TENEXA',
              'Shared@Group.Arpanet',
              'Shared@Group.Arpanet',
              'Chamberlain@NBA.US',             # this is not quite right.
#              'WhoZiWhatZit@Cordon-Bleu',
              'Childs@WGBH.Boston',
#              'Cheapie@Discount-Liquors',
#              'Port@Portugal',
#              'Jones@SEA',
              'Another@Somewhere.SomeOrg',
              'Jones@Group.Org',
              'Jones@Group.Org',
#              'Jones@Group',
#              'Secy@Other-Group',
              'Shared@Group.Org',
#              'Secy@Other-Group',
              'Jones@Host.Net',
#              'Jones@Host',
              'Jones@Host.Net',
              'Smith@Other.Org',
#              'Doe@Somehwere-Else',
#              'Secy@Host',
#              'Group@Host',
#              'Secy@Host',
#              'Secy@Host',
#              'Secy@Registry',
#              'Secy@Registry',
#              'Jones@Registry',
#              'Jones@Host',
#              'Smith@Other-Host',
#              'Doe@Somewhere-Else',
#              'Secy@SHost',
              'Jones@Registry.Org',
              'Jones@Registry.Org',
              'Smith@Registry.Org',
#              'Group@Host',
#              'Secy@SHOST',
#              '"Al Neuman"@Mad-Host',
#              'Sam.Irving@Other-Host',
              'KDavis@This-Host.This-net',
#              'KSecy@Other-Host',
              'Sam.Irving@Reg.Organization',
              'some.string@DBM.Group',          # this is a message-ID
              'Group@Some-Reg.An-Org',
              'Al.Neuman@MAD.Publisher',
              'Balsa@Tree.Root',
#              '"Sam Irving"@Other-Host',
#              '/main/davis/people/standard@Other-Host',
#              '"<Jones>standard.dist.3"@Tops-20-Host',
              'rfc-admin@faqs.org',
             );

my @found = ();

find_emails($text, sub {
                my($email, $orig_email) = @_;
#                print $email->format, "\n";
                push @found, $email->format;
            });

ok( @found == @Expect,  'Found all addresses in RFC822' );
