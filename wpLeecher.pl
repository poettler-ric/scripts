#!/usr/bin/perl

use Carp;
use common::sense;
use File::Basename;
use File::Find;
use File::Path;
use Getopt::Std;
use HTML::TreeBuilder;
use LWP::UserAgent;

# command line options
my %opts = ();
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# version of the script
our $VERSION = '$Revision: 1.6 $' =~ /([\d.]+)/ && $1;

getopts("abld:g:p:o:s:n", \%opts);

# default file containing the list of already downloaded files
my $fileLeeched = $ENV{"HOME"} . "/.leeched";

# destination for the images
my $dirImages = $opts{"o"} || $ENV{"HOME"} . "/wp";

# url to the skins.be index page
my $urlRoot = "http://www.skins.be/";
# pattern for the pages listing new images
my $urlNewestPattern = "http://www.skins.be/page/\@page/";
# pattern for the image url
my $urlImage = "http://wallpapers.skins.be/\@name/\@name-\@resolution-\@id.jpg";
# pattern for the pages of one specific babe
my $urlBabePagePattern = "http://www.skins.be/\@name/wallpapers/page/\@page/";

# precompiled regexp to geht some data out of a imagelink ($1 = name, $2 = id, # $3 = resolution)
my $nodeDataRegexp = qr/http:\/\/wallpaper.skins.be\/([\w-]+)\/(\d+)\/(\d+x\d+)\//;

# setting up the user agent
my $ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.8) Gecko/20071023 Firefox/2.0.0.8');
$ua->env_proxy;

# files which should be considered to be already donwloaded
my %downloaded = ();

sub HELP_MESSAGE {
	my ($fh) = @_;
	print $fh <<eof
usage:
$0 [-a] [-b] [-l] [-d <file>] [-g <name>] [-p <number>] [-o <directory>] [-s <number>] [-n]
	-a stop parsing pages automatically, if a page was parsed with no new pictures
	-b scanning is started from the last page to the newest one
	-l lists all downloaed images to stdout and exits (the 
	   resulting file can be used for the -d)
	-d takes a file, which contains a list of relative filenames 
	   which should be threaded as already downloaded
	-g name of the babe of which to retrieve all pictures
	-p specifies the number of pages which should be scanned
	-o species the output directory for the files (of from where 
	   the files should be listed)
   	-s skip a given number of pages
	-n skips loading of the ~/.leeched file

The script will also look for a file ~/.leeched and will load it's content
as if the file would be passed with the -d switch. This can be prevented with
the -n switch.

eof
}

sub VERSION_MESSAGE {
	my ($fh) = @_;
	print $fh <<eof
wpLeecher version $VERSION
	by Richard Poettler (richard dot poettler at gmail dot com)

eof
}

sub getNodeData {
	my ($node) = @_;

	# get the resolution
	my $resolutionListing = $node->look_down("_tag" => "ul",
			"class" => "resolutionListing");
	# if this is a ul with some porno ads
	return if (!defined($resolutionListing));
	my @resLinks = $resolutionListing->look_down("_tag" => "a");
	my $largest = (map {$_->attr("href")} @resLinks)[-1];

	# extracting the data from the link
	$largest =~ $nodeDataRegexp;

	# returning id, name , resolution
	return $2, $1, $3;
}

sub getLastPage {
	my $url = shift or croak "no url given";
	my $response = $ua->get($url);
	croak $response->message unless $response->is_success;

	# parsing the content
	my $tree = HTML::TreeBuilder->new_from_content($response->content);
	my $paginationDiv = $tree->look_down("_tag" => "div", "id" => "pagination");

	if (!$paginationDiv) {
		$tree->delete;
		return 1;
	}
	
	my $text = (($paginationDiv->content_list)[0]->content_list)[0];
	$tree->delete;
	$text =~ /Page \d+ of (\d+)/;
	return $1;
}

sub makeImageDirectoryName {
	my ($name) = @_;
	$name =~ s/(\w+)/\u$1/g;
	$name =~ s/-/_/g;
	return $name;
}

sub makeImageFileName {
	my ($id, $name, $resolution) = @_;
	return $name . "-" . $resolution . "-" . $id . ".jpg";
}

sub downloadImage {
	my ($id, $name, $resolution) = @_;

	my $dir = $dirImages . "/" .  makeImageDirectoryName($name);
	my $file = $dir . "/" . makeImageFileName($id, $name, $resolution);

	if (! checkDownloaded($id, $name, $resolution)) {
		# download the file
		my $urlTmp = $urlImage;
		$urlTmp =~ s/\@id/$id/g;
		$urlTmp =~ s/\@name/$name/g;
		$urlTmp =~ s/\@resolution/$resolution/g;

		print $urlTmp, "\n";

		my $response = $ua->get($urlTmp);
		croak $response->message unless $response->is_success;

		# create the directory
		mkpath($dir) if (! -d $dir);

		# saving the file
		open my $fh, ">", $file || croak $!;
		binmode $fh;
		print $fh $response->content;
		close $fh || croak $!;
		return 1;
	}
	return 0;
}

sub checkDownloaded {
	my ($id, $name, $resolution) = @_;
	my $relativeFile = makeImageDirectoryName($name) . "/" . makeImageFileName($id, $name, $resolution);
	return (-f $dirImages . "/" . $relativeFile) || defined $downloaded{$relativeFile};
}

sub loadDownloaded {
	for (@_) {
		print "loading: ", $_, "\n";
		open my $fh, "<", $_ || croak $!;
		for (<$fh>) {
			chomp $_;
			$downloaded{$_} = 1;
		}
		close $fh || croak $!;
	}
}

sub listDownloaded {
	find(\&wanted, $dirImages);
}

sub wanted {
	print basename($File::Find::dir), "/", $_, "\n" if (-f $File::Find::name);
}

sub doPage {
	my $page = shift or croak "no pageid given";
	my $url = shift or $urlNewestPattern;

	$url =~ s/\@page/$page/g;
	my $gotNewPicture = 0;

	print "doing: ", $url, "\n";

	# downloading the imagelist
	my $response = $ua->get($url);
	croak $response->message unless $response->is_success;

	my $tree = HTML::TreeBuilder->new_from_content($response->content);

	# getting the image nodes
	for my $node ($tree->look_down("_tag" => "div", "class" => "motive")) {
		my ($id, $name, $resolution) = getNodeData($node);
		# we got a porno add...
		next if (!$id);
		$gotNewPicture |= downloadImage($id, $name, $resolution);
	}

	$tree->delete;

	return $gotNewPicture;
}

if ($opts{"l"}) { # list downloaded files
	listDownloaded();
	exit 0;
}

loadDownloaded($opts{"d"}) if ($opts{"d"}); # load a file with a list of already downloaded files
loadDownloaded($fileLeeched) if (-f $fileLeeched && !$opts{"n"}); # loading the default file

my $urlPattern = "";
my $pageCount = 0;

if ($opts{"g"}) {
	my $name = $opts{"g"};
	$name = lc($name);
	$name =~ s/ /-/g;
	$name =~ s/_/-/g;

	$urlPattern = $urlBabePagePattern;
	$urlPattern =~ s/\@name/$name/g;
	(my $firstPage = $urlPattern) =~ s/\@page/1/g;
	$pageCount = getLastPage($firstPage);
} else {
	$urlPattern = $urlNewestPattern;
	$pageCount = getLastPage($urlRoot);
}

my @pages = (1 .. $pageCount);
@pages = reverse @pages if ($opts{"b"}); # iterate the new pages in reverse order
@pages = @pages[$opts{"s"} .. $#pages] if ($opts{"s"}); # skip some pages
@pages = @pages[0 .. ($opts{"p"} - 1)] if ($opts{"p"}); # set number of pages to process

foreach my $page (@pages) {
	doPage($page, $urlPattern) || $opts{"a"} && exit 0;
}
