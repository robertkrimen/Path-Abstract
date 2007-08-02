#!/usr/bin/perl -w

use strict;

use Path::Abstract;

my $count = shift @ARGV || 1000;
if (1) {
	my $path = new Path::Abstract;
	while ($count--) {
		$path = new Path::Abstract if $count % 10;
		$path = int rand 2 ? $path->child($count) : $path->child($count);
	}
}
elsif (1) {
	my $path = new Path::Abstract;
	while ($count--) {
		$path = int rand 2 ? $path->child($count) : $path->child($count);
	}
}
