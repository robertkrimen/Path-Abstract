#!/usr/bin/perl -w

use strict;

use Path::Abstract;
use Path::Abstract::Fast;

use constant class => 1 ? qw/Path::Abstract/ : qw/Path::Abstract::Fast/;

srand 30;

my $count = shift @ARGV || 10000;
if (0) {
	my $path = class->new;
	while ($count--) {
		$path = class->new if $count % 10;
		$path = int rand 2 ? $path->child($count) : $path->child($count);
	}
}
elsif (1) {
	my $path = class->new;
    my $got;
	while ($count--) {
		$path = $path->child(sprintf '%x', int rand 3600);
        $got .= ref $path eq "Path::Abstract::Fast" ? $path->get : "$path";
	}
}
elsif (1) {
	my $path = class->new;
	while ($count--) {
		$path = $path->child(sprintf '%x', int rand 3600);
	}
}
elsif (1) {
	my $path = class->new;
	while ($count--) {
		$path = int rand 2 ? $path->child($count) : $path->child($count);
	}
}
