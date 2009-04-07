#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

my @files = ();
my @prefixes = ();
my @ignoreIncludes = ();
my @calls = ();
my $prog = "";

my $preBlankPattern = qr/^\s/;
my $postBlankPattern = qr/\s$/;

my $includePattern = qr/\{([[:alpha:]][[:word:].]*)/;

my $sectionPattern = qr/\[([[:alpha:]]+)\]/;

# variables to configure the behaviour of printDeptree
my $deptreeLinePrefix = "  ";
my $deptreePrintSeenIncludes = 0;
my $deptreePrintOnlyFilename = 1;

die "There must be a file given" if (scalar(@ARGV) < 1);

sub getIncludes {
	my @includes = ();

	for my $file (@_) {
		open my $fh, "<", $file or die $!;
		while (my $line = <$fh>) {
			$line =~ s/$preBlankPattern//;
			$line =~ s/$postBlankPattern//;

			push @includes, ($line =~ /$includePattern/g);
		}
		close $fh or die $!;
	}

	# clean up includes
	for my $ignore (@ignoreIncludes) {
		@includes = grep { !/$ignore/ } @includes;
	}
	return getRealName(@includes);
}

sub getRealName {
	my @realnames = ();
	
	for my $name (@_) {
		my $found = 0;
		for my $prefix (@prefixes) {
			my $filename = $prefix . "/" . $name;
			if (-f $filename) {
				push @realnames, $filename;
				$found++;
				last;
			}
		}
		warn $name . " not found!" if (!$found);
	}
	return @realnames;
}

sub getRecursiveIncludes {
	my %includes = map { $_ => 1 } getIncludes(@_);
	my @newIncludes = ();

	do {
		@newIncludes = grep { !$includes{$_} } getIncludes(keys %includes);
		map { $includes{$_} = 1 } @newIncludes;
	} while (@newIncludes);

	return keys %includes;
}

sub printDeptree {
	my $file = shift;
	my $seen = shift || {};
	my $prefix = shift || "";
	my $isIncluded = shift || 0;

	my $printname = "";

	# if this is the rootfile -> print the file and intend all includes
	if (!$isIncluded) {
		$printname = $deptreePrintOnlyFilename
			? basename($file) : $file;
		print $prefix, $printname, "\n";
		$prefix = $deptreeLinePrefix;
	}
	foreach my $include (getIncludes($file)) {
		$printname = $deptreePrintOnlyFilename
			? basename($include) : $include;
		if (!${$seen}{$include}) {
			print $prefix, $printname, "\n";
			${$seen}{$include} = 1;
			printDeptree($include, $seen, $prefix .  $deptreeLinePrefix, 1);
		} elsif ($deptreePrintSeenIncludes) {
			print $prefix, $printname, " => seen\n";
		}
	}
}

sub checkFilesForCalls {
	for my $file (@_) {
		open my $fh, "<", $file or die $!;

		while (my $line = <$fh>) {
			$line =~ s/$preBlankPattern//;
			$line =~ s/$postBlankPattern//;

			for my $callPattern (@calls) {
				if ($line =~ /$callPattern/) {
					print $file, ":", $., ": ", $line, "\n";
				}
			}
		}
		close $fh or die $!;
	}
}

sub parseProgramFile {
	my $programSections = {
		'files' => sub { push @files, @_; },
		'prefixes' => sub { push @prefixes, @_; },
		'ignoreIncs' => sub { push @ignoreIncludes, map { qr/^$_$/ } @_; },
		'calls' => sub { push @calls, map { qr/$_/ } @_; },
		'prog' => sub { $prog .= $_ for (@_); },
	};

	for my $file (@_) {
		my $sectionCode;

		open my $fh, "<", $file or die $!;

		while (my $line = <$fh>) {
			$line =~ s/$preBlankPattern//;
			$line =~ s/$postBlankPattern//;

			if ($line) {
				if ($line =~ /$sectionPattern/) { # change the sectioncode
					$sectionCode = $$programSections{$1}
				} else { # execute the sectioncode
					&$sectionCode($line);
				}
			}
		}

		close $fh or die $!;
	}
}

parseProgramFile(@ARGV);
eval($prog);

__END__

=head1 include.pl

=head2 NAME

include.pl scan progress files in a fast way with little efford

=head2 USAGE

  perl include.pl get_calls.prog
  
The script needs at least one filename supplied to parse what it should be doing.

=head2 METHODS

=head3 getIncludes

Determines all Progress include files which are included by the supplied list of files.

=over

=item B<input>

A list of files for which to determine all includes

=item B<output>

A list of files included by the input files. All includes matching a pattern in C<@ignoreIncludes> will be wiped out.

=back

=head3 getRealName

Determines the real name of a file by trying out all entries in 
C<@prefixes> and check, whether the file exists.

=over

=item B<input>:

A list of file names for which to get the real file names

=item B<output>:

A list of real filenames

=back

=head3 getRecursiveIncludes

Determines the included files of a list of files recursively (includes of the includes, and so on).
This subroutine is using the C<getIncludes> subroutine.

=over

=item B<input>:

A list of file names for which to determine the includes recursively

=item B<output>:

A list of includes (every include will only appear once)

=back

=head3 checkFilesForCalls

Searches a list of files for the occurence of some patterns. The results will be printed to C<STDOUT>. 
The format of the output would be:

  <file>:<line number>: <line content>

=over

=item B<input>:

A list of file which to check for occurences in C<@calls>

=back

=head3 parseProgramFile

Parses a program file do determine what to do. The format the program file will be described below.

=over

=item B<input>:

A list of files to parse

=back

=head2 FORMAT OF THE PROGRAM FILE

The program file is used to tell the script, where to search for what.
The file is divided in different sections The beginning of a section is marked by C<[section]>
where C<section> is the section's name. Starting a new section will end the previous one.

Following sections are available:

=over

=item B<files>:

This section contains a list of files, one file per line. The filenames will be 
stored in the C<@files> array and can/should be used in the C<prog> section.

=item B<prefixes>:

This section contains a list of directory prefixes, one directory per line. The directory
prefixes will be stored in the C<@prefixes> array and are used by the C<getRealName> routine to 
determine the real filenames for files.

=item B<ignoreIncs>:

This section contains a list of include patterns, one pattern per line. The patterns will be 
compiled and stored in the C<@ignoreIncludes> array and are used by the C<getIncludes> routine to
wipe out includes, which should not be reported.

=item B<calls>:

This section contains a list of patterns for which to search in the files, one pattern per line. 
The patterns will be compiled and stored in the C<@calls> array and are used by the C<checkFilesForCalls> 
routine to determine for what to look for.

=item B<prog>:

This section contains contains perl code, which should be executed, after parsing all the sections.
All the variables and methods described above can be used (and of course all other perl modules installed).

=back
