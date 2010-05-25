#!/usr/bin/perl

use common::sense;

use Config::General qw(ParseConfig);
use File::HomeDir;
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile catdir rel2abs);
use Getopt::Std;
use HTML::TreeBuilder;
use LWP::UserAgent;
use Parallel::ForkManager;
use String::Util qw(trim);


my $videoPattern = qr/var videourl="([^"]+)"/;
my $titlePattern = qr/<title>([^-]+).*<\/title>/;
my $timePattern = qr/((\d+):)?(\d{1,2}):(\d{1,2})/;
my $linkfilePattern = qr/((\w+)|)?(http:\/\/.*)/;

my $searchUrlPattern = "http://www.tube8.com/search.html?q=%s&page=%d";

my $ua = LWP::UserAgent->new(
	'agent' =>
	'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.8) Gecko/20071023 Firefox/2.0.0.8'); 

# options from the command line
my %opts = ();
getopts("s", \%opts);

# read the config file
my %conf = ();
foreach my $configfile (catfile(File::HomeDir->my_home, "_tube"),
		catfile(File::HomeDir->my_home, ".tube")) {
	%conf = ParseConfig($configfile) if (-r $configfile);
}

# TODO: make linkfile configurable
my $linkFile = "todo.txt";

my $pm = new Parallel::ForkManager($conf{'MAX_PROCESSES'} or 3);

my $outputDir = eval($conf{'OUTPUT_DIR'});

# links holding all links for pages to parse
my %links;


sub downloadVideoFromPage {
	my $url = shift or warn "no url given";
	my $actualDir = catdir($outputDir, shift);

	say "starting: ", $url;

	my $response = $ua->get($url);
	die "error while getting page: " . $response->message
		unless $response->is_success;

	# TODO: handle case, when output file already exists
	$response->content =~ $videoPattern;
	my $videoUrl = $1;
	$response->content =~ $titlePattern;
	my $outputFile = trim($1);

	say "doing: ", $outputFile;

	$outputFile =~ s/ /_/g;
	$outputFile .= ".flv";
	$outputFile = catfile($actualDir, $outputFile);

	make_path($actualDir);

	$response = $ua->get($videoUrl, ':content_file' => $outputFile);
	die "error while getting video: " . $response->message
		unless $response->is_success;
}

sub searchForLinks {
	my @pages = @_;
	my $page = shift @pages || 1;

	my $url = sprintf($searchUrlPattern, join("+", @ARGV), $page);
	my $folder = join("_", @ARGV);

	my $response = $ua->get($url);
	die "error while getting page: " . $response->message
		unless $response->is_success;
	my $tree = HTML::TreeBuilder->new_from_content($response->content);

	my @thumbWrappers = $tree->look_down("_tag" => "div", "class" => "thumb-wrapper");
	foreach my $thumbWrapper (@thumbWrappers) {
		my $link = ($thumbWrapper->look_down("_tag" => "a"))[1]->attr("href");
		my $time = ($thumbWrapper->look_down("_tag" => "strong"))[1]->as_text;
		$time =~ /$timePattern/;
		my $minutes = $2 * 60 + $3;

		next if ($conf{'MIN_MINUTES'} && ($minutes < $conf{'MIN_MINUTES'}));

		say $folder, "|", $link;
	}

	# if we are on the first page, check which pages we have to go
	if ($page == 1) {
		my $paginationDif = $tree->look_down("_tag" => "div", "class" => "footer-pagination");
		# TODO: at the moment only 12 pages get recognized
		@pages = grep { /\d+/ && !/^$page$/}
			map { $_->as_text } $paginationDif->look_down("_tag" => "li");
	}

	$tree->delete;

	searchForLinks(@pages) if (@pages);
}

sub onFileFinish {
	my ($pid, $exit_code, $link) = @_;

	say "finished ", $link;

	# save only outstanding links
	syncLinkFile($link);
}

sub syncLinkFile {
	# read linkfile
	die "linkfile (", $linkFile, ") is not a readable file" if (!-r $linkFile);
	open my $file, "<", $linkFile or die "can't open linkfile for reading";
	%links = map {/$linkfilePattern/; $3 => $2} <$file>;
	close $file or die "can't close linkfile";

	# remove unwanted links
	delete $links{$_} foreach (@_);

	# write linkfile
	die "linkfile (", $linkFile, ") is not a writeable file" if (-e $linkFile && !-w _);
	open my $file, ">", $linkFile or die "can't open linkfile for writing";
	while (my ($key, $value) = each %links) {
		print $file $value, "|", $key, "\n";
	}
	close $file or die "can't close linkfile";
}

if ($opts{'s'}) {
	say "searching";
	searchForLinks();
} else {
	say "doing file";

	syncLinkFile();

	$pm->run_on_finish(\&onFileFinish);

	# iterate over the links (we don't use foreach, because it holds an unalterable
	# copy of the array, so the changes to the array don't have any effect)
	while (my ($url, $directory) = each %links) {
		my $pid = $pm->start($url) and next;
		downloadVideoFromPage($url, $directory);
		$pm->finish;
	}

	$pm->wait_all_children;
}
