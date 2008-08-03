#!perl -T

use strict;
use warnings;

use Test::Most;

use Path::Abstract::URI;

plan qw/no_plan/;

my $uri = Path::Abstract::URI->new("http://example.com?a=b");
is($uri, "http://example.com?a=b");

$uri->down(qw/apple/);
is($uri, "http://example.com/apple?a=b");

$uri->up;
$uri->up;
$uri->up;
is($uri, "http://example.com/?a=b");

$uri->down(qw/apple banana/);
is($uri, "http://example.com/apple/banana?a=b");

is($uri->parent, "http://example.com/apple?a=b");

$uri = $uri->parent;
$uri->down("");
is($uri, "http://example.com/apple?a=b");

$uri->down("/");
is($uri, "http://example.com/apple/?a=b");

$uri->query("c=d&e=f");
is($uri, "http://example.com/apple/?c=d&e=f");
