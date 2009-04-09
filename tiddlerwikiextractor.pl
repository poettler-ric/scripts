#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use File::Path;
use File::Spec::Functions;
use XML::Parser;

my $wikifile = shift @ARGV | croak "No wikifile given";
my $outputdir = shift @ARGV | croak "No outputdirectory given";
#my $wikifile = catfile(qw/c: temp wiki.html/);
#my $outputdir = catdir(qw/c: temp wikiexport/);

sub getContentWithAttribute {
	my $tree = shift or die "no tree given";
	my $tag = shift;
	my $attribute = shift;
	my $value = shift;

	my $entryCount = scalar(@{$tree});
	my $iCounter = 0;

	if ($entryCount % 2) { # we have an ordinary element which might have attributes
		$iCounter = 1;
	}

	for ( ; $iCounter < $entryCount; $iCounter += 2) {
		my $treeTag = $tree->[$iCounter];
		my $treeContent = $tree->[$iCounter + 1];

		# checking attribute (watch out: a tag of "0" doesn't have a arrayref as content)
		if (($treeTag eq $tag)
				and (!$attribute
					or ($treeContent->[0]->{$attribute}
						and ($treeContent->[0]->{$attribute} eq $value)))) {
			return $treeContent;
		}
		# check it's children
		if (($treeTag ne "0")
				and (my $checkedTree = getContentWithAttribute($treeContent, $tag, $attribute, $value))) {
			return $checkedTree;
		}
	}
	return 0;
}

sub parseStoreDiv {
	my $tree = shift or die "no tree given";

	my $attributeHash = $tree->[0];

	# copy content into the attributes hash and return it
	my $preTree = getContentWithAttribute($tree, "pre", "", "");
	# out of lazyness we assume, that there is onyl the content left in the "pre" element
	$attributeHash->{'content'} = $preTree->[2];

	return $attributeHash;
}

my $parser = new XML::Parser(Style => "Tree");
my $tree = $parser->parsefile($wikifile);

my $storeDiv = getContentWithAttribute($tree, "div", "id", "storeArea")
	or die "no div with id equal to storeArea found";

if (! -d $outputdir) {
	mkpath $outputdir or die "couldn't create " . $outputdir;
}

my $entryCount = 0;
for (my $iCounter = 1; $iCounter < scalar(@{$storeDiv}); $iCounter += 2) {
	my $treeTag = $storeDiv->[$iCounter];
	my $treeContent = $storeDiv->[$iCounter + 1];

	if ($treeTag eq "div") {
		my $entry = parseStoreDiv($treeContent);
		print $entry->{'title'}, "\n";
		$entryCount++;

		# TODO: cleanup the wikititle
		my $outputfile = catfile($outputdir, $entry->{'title'} . ".txt");

		# dump content into wikifile
		open my $file, ">", $outputfile or die "couldn't open " . $outputfile . ": " . $!;
		print $file $entry->{'content'};
		close $file or die "couldn't open " . $outputfile . ": " . $!;
	}
}
print "parsed: ", $entryCount, " entries.\n";
