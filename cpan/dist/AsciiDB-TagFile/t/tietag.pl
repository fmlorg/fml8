# Define test database properties

tie %tietag, 'AsciiDB::TagFile',
	DIRECTORY => 'tdata',
	SUFIX => '.tfr', 
	SCHEMA => { 
		ORDER => ['a', 'b', 'c', 'zero' ],
		KEY => {
			ENCODE => sub { $_[0] =~ s{/}{_SLASH_}g; $_[0] },
			DECODE => sub { $_[0] =~ s{_SLASH_}{/}g; $_[0] },
		},
	},
	@TEST_SETTINGS;

tied(%tietag) or print "not ";
