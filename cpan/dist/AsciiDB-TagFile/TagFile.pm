package AsciiDB::TagFile;

# Copyright (c) 1997,1998,1999 Jose A. Rodriguez. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

require Tie::Hash;
@ISA = (Tie::Hash);

use Cwd;

use vars qw($VERSION $catPathFileName);

BEGIN {
	eval "use File::Spec";
	$catPathFileName = ($@) ?
		sub { join('/', @_) } : # Unix way
		sub { File::Spec->catfile(@_) }; # Portable way
}

$VERSION = '1.05';

use Carp;
use AsciiDB::TagRecord;

sub TIEHASH {
	my $class = shift;
	my %params = @_;

	my $self = {};
	$self->{_DIRECTORY} = $params{DIRECTORY} || cwd;
	$self->{_SUFIX} = $params{SUFIX} || '';
	$self->{_SCHEMA} = $params{SCHEMA};
	$self->{_READONLY} = $params{READONLY};
	$self->{_FILEMODE} = $params{FILEMODE};
	$self->{_LOCK} = $params{LOCK} || 0;
	$self->{_CACHESIZE} = $params{CACHESIZE};

	unless (-d $self->{_DIRECTORY}) {
		croak "Directory '$params{DIRECTORY}' does not exist";
	}

	if (defined $self->{_CACHESIZE}) {
		$self->{_CACHESIZE} = int($self->{_CACHESIZE});

		if ($self->{_CACHESIZE} == 0) {
			undef $self->{_CACHESIZE};
		} elsif ($self->{_CACHESIZE} < 1) {
			croak "Cache size should be >= 0 (0 means no cache)";
			$self->{_CACHESIZE} = 1;
		}
	}

	# Number of internal keys (ie. '_key')
	$self->{_INTKEYCOUNT} = 1 + keys %$self;

	bless $self, $class;
}

sub FETCH {
	my ($self, $key) = @_;

	return $self->{$key} if exists ($self->{$key});

	return $self->newRecord($key);
}

sub STORE {
	my ($self, $key, $value) = @_;

	# Return if the user is assigning an object to itself ($a{A} = $a{A})
	return if exists $self->{$key} && $self->{$key} == $value;

	$self->newRecord($key) unless (exists $self->{$key});

	my $field;
	foreach $field (keys %{$self->{$key}}) {
		$self->{$key}{$field} = $value->{$field};
	}
}

sub FIRSTKEY {
	my $self = shift;

	# Current keys are the union of saved keys and new created but
	# not saved keys
	my %currentKeys;

	my $sufix = $self->{_SUFIX};

	map { $currentKeys{$_} = 1 } 
		map { $self->decodeKey($_) }
		grep { $_  =~ /(.+)\Q$sufix\E$/; $_ = $1 } 
		$self->getDirFiles();
	map { $currentKeys{$_} = 1 } grep(!/^_/, keys %$self);

	my @currentKeys = keys %currentKeys;
	$self->{_ITERATOR} = \@currentKeys;

	shift @{$self->{_ITERATOR}};
}

sub NEXTKEY {
	my $self = shift;
	
	shift @{$self->{_ITERATOR}};
}

sub EXISTS {
	my ($self, $key) = @_;

	$self->{$key} || -f $self->fileName($key) || 0;
}

sub DELETE {
	my ($self, $key) = @_;

	return if $self->{_READONLY};

	unlink $self->fileName($key);

	tied(%{$self->{$key}})->deleteRecord()
		if tied(%{$self->{$key}});

	delete $self->{$key} if exists $self->{$key};
}

sub sync {
	my $self = shift;

	my $record;
	foreach $record (grep { tied(%$_) } values %{$self}) {
		tied(%$record)->sync();
	}
}

sub purge {
	my $self = shift;
	my ($cacheSize) = @_;

	if (defined($cacheSize)) {
		my $dataRecords = scalar(keys %$self) - $self->{_INTKEYCOUNT};
		return if $dataRecords < $cacheSize;
	}

	# This works in 5.004 no 5.003
	#delete @$self{grep !/^_/, keys %{$self}};
	# instead we use this...
	foreach (grep !/^_/, keys %{$self}) {
		delete $self->{$_};
	}
}

sub newRecord {
	my $self = shift;
	my ($key) = @_;

	$self->purge($self->{_CACHESIZE}) if defined($self->{_CACHESIZE});

	my %record;
	tie %record, 'AsciiDB::TagRecord',
        	FILENAME => $self->fileName($key),
        	SCHEMA => $self->{_SCHEMA},
		READONLY => $self->{_READONLY},
		FILEMODE => $self->{_FILEMODE};
	
	$self->{$key} = \%record;
}

sub encodeKey {
	my $self = shift;
	my ($key) = @_;

	my $encodeSub = $self->{_SCHEMA}{KEY}{ENCODE};
	($encodeSub) ? &$encodeSub($key) : $key;
}

sub decodeKey {
	my $self = shift;
	my ($key) = @_;

	my $decodeSub = $self->{_SCHEMA}{KEY}{DECODE};
	($decodeSub) ? &$decodeSub($key) : $key;
}

sub fileName {
	my $self = shift;
	my ($key) = $self->encodeKey(@_);

	&$catPathFileName($$self{_DIRECTORY}, "$key$$self{_SUFIX}")
}

sub getDirFiles {
	my $self = shift;

	local *DIR;
	opendir(DIR, $$self{_DIRECTORY})
		|| die "Can't opendir $$self{_DIRECTORY}: $!";
	my @files = grep { -f &$catPathFileName($$self{_DIRECTORY}, $_) } 
		readdir(DIR);
	closedir DIR;

	@files;
}

1;
__END__

=head1 NAME

AsciiDB::TagFile - Tie class for a simple ASCII database

=head1 SYNOPSIS

 # Bind the hash to the class
 $tieObj = tie %hash, 'AsciiDB::TagFile',
        DIRECTORY => $directory,
        SUFIX => $sufix,
	LOCK => $bool,
	READONLY => $bool,
	CACHESIZE => $cacheSize,
	FILEMODE => $mode,
        SCHEMA => { 
		ORDER => $arrayRef 
		KEY => {
			ENCODE => $subRef,
			DECODE => $subRef
		}
	};

 # Save to disk all changed records
 $tieObj->sync(); 

 # Remove all records from memory (and save them if needed)
 $tieObj->purge(); 

 # Remove all records from memory (and save them if needed) 
 #	iif there are more than $cacheSize records in memory
 $tieObj->purge($cacheSize); 

 # Get all record keys
 @array = keys %hash; 

 # Check if a record exists
 exists $hash{$recordKey}

 # Get a field
 $scalar = $hash{$recordKey}{$fieldName};

 # Assign to a field
 $hash{$recordKey}{$fieldName} = $value; 

=head1 DESCRIPTION

The B<AsciiDB::TagFile> provides a hash-table-like interface to a simple ASCII
database.

The ASCII database stores each record in a file:

	$directory/recordKey1$sufix
	$directory/recordKey2$sufix
	...
	$directory/recordKeyI<N>$sufix

And a record has this format:

	[fieldName1]: value1
	[fieldName2]: value2
	...
	[fieldNameI<N>]: value2

After you've tied the hash you can access this database as access a hash of 
hashes:

	$hash{recordKey1}{fieldName1} = ...

To bind the %hash to the class AsciiDB::TagFile you have to use the tie
function:

	tie %hash, 'AsciiDB::TagFile', PARAM1 => $param1, ...;

The parameters are:

=over 4

=item DIRECTORY

The directory where the records will be stored or readed from.
The default value is the current directory.

=item SUFIX

The records are stored as files. The file name of a record is the
key plus this sufix (if supplied).

For example, if the record with key 'josear' and sufix '.record', will
be stored into file: 'josear.record'.

If this parameter is not supplied the records won't have a sufix.

=item LOCK

If you set this parameter to 1 TagFile will perform basic locking.
Record files will be share locked before reading them, and exclusive
locked when syncing (writing) them.

This basic locking only guarantees that a record file is always
written correctly, but as TagFile keep records in memory you can still suffer
consistency problems reading fields.

The default value is 0, i.e. the database won't be locked.

=item READONLY

If you set this parameter to 1 the database will be read only and
all changes will be discarted.

The default value is 0, i.e. the database can be changed.

=item CACHESIZE

Records loaded from disk (or simply created) are keeped in memory till
the tied hash is deleted. You can limit the number of records in memory
setting this option to a value ($cacheSize).

All records are purged from memory if their count reach $cacheSize.

You can purge the records manually using the purge() method.

Of course, the $caseSize should be a positive number, and you can use
the 0 value to turn off the caching (useful when testing).
 
The default value for CACHESIZE is 'infinite' (more or less...)

=item FILEMODE

Filemode assigned to new created files. 

If this parameter is not supplied the new created files will have the
default permissions.

=item SCHEMA

This parameter is a hash reference that contains the database definition.

With ORDER you can specify in which order fields will be saved into the
file.

For example,

 SCHEMA => {
	ORDER => [ 'fieldHi', 'field2There', 'fieldWorld' ]
 }

will save the record this way:

	[fieldHi]: ...
	[fieldThere]: ...
	[fieldWorld]: ...

Note: this parameter is mandatory, and you have to specify all the
fields. B<If you forget to list a field it will not be saved>.

With KEY,ENCODE and KEY,DECODE you can define an special encoding
for keys when used as filenames.

For example, if using this SCHEMA:

 SCHEMA => {
         ORDER => ['a', 'b', 'c'],
         KEY => {
                 ENCODE => sub { $_[0] =~ s{/}{_SLASH_}g; $_[0] },
                 DECODE => sub { $_[0] =~ s{_SLASH_}{/}g; $_[0] },
         }
 }

a record with the key 's1/s2' will be saved into filename 's1_SLASH_s2'.
The DECODE subroutine is used to traslate back to the original key.

NOTE: You should use this feature if you allow filesystem metacharacters
(as '/', used in Unix to split path components) in your keys. 

=back

The data will be saved to disk when the hash is destroyed (and garbage
collected by perl), so if you need for safety to write the updated data
you can call the B<sync> method to do it.

=head1 EXAMPLES

 $dbObj = tie %tietag, 'AsciiDB::TagFile',
        DIRECTORY => 'data',
        SUFIX => '.tfr',
        FILEMODE => 0644,
        SCHEMA => { ORDER => ['name', 'address'] };

 $tietag{'jose'}{'name'} = 'Jose A. Rodriguez';
 $tietag{'jose'}{'address'} = 'Granollers, Barcelona, SPAIN';
 $tietag{'cindy'}{'name'} = 'Cindy Crawford';
 $tietag{'cindy'}{'address'} = 'YouBetIwouldLikeToKnowIt';

 my $key;
 foreach $key (keys %tietag) {
	print $tietag{$key}{'name'}, "\t", $tietag{$key}{'address'}, 
		"\n";
 }
