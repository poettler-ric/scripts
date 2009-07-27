# http://thedailywtf.com/Articles/Programming-Praxis-Russian-Peasant-Multiplication.aspx

use strict;
use warnings;

use Test;

sub russian {
	my ($a, $b) = @_;
	if ($a == 1) {
		return $b;
	}
	return ($a % 2 ? $b : 0) + russian(int($a / 2), $b * 2);
}

sub russian_seq {
	my ($a, $b) = @_;
	my $result = 0;
	while ($a) {
		$result += $b if ($a % 2);
		$b *= 2;
		$a = int($a / 2);
	}
	return $result;
}

plan(tests => 6);
ok(russian(18, 23), 414);
ok(russian_seq(18, 23), 414);
ok(russian(9, 8), 72);
ok(russian_seq(9, 8), 72);
ok(russian(8, 9), 72);
ok(russian_seq(8, 9), 72);
