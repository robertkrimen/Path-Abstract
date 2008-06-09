#!/usr/bin/perl -w

use strict;

use Path::Class;

srand 30;

my $count = shift @ARGV || 1000;

if (0) {
	my $path = dir;
	while ($count--) {
		$path = dir if $count % 10;
		$path = int rand 2 ? $path->subdir($count) : $path->subdir($count);
	}
}
elsif (1) {
	my $path = dir;
	while ($count--) {
		$path = $path->subdir(sprintf '%x', int rand 3600);
	}
}
elsif (1) {
	my $path = dir;
	while ($count--) {
		$path = int rand 2 ? $path->subdir($count) : $path->subdir($count);
	}
}
