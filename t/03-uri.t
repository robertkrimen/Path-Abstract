#!perl -T

use strict;
use warnings;

use Test::Most;

use Path::Abstract::URI;
use URI::PathAbstract;

plan qw/no_plan/;

{
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

    $uri->path("grape/blueberry/pineapple");
    is($uri, "http://example.com/grape/blueberry/pineapple?c=d&e=f");

    $uri = Path::Abstract::URI->new("http://example.com/cherry?a=b", path => "grape/lemon");
    is($uri, "http://example.com/grape/lemon?a=b");

    $uri = Path::Abstract::URI->new("http://example.com/cherry?a=b", child => "grape/lemon");
    is($uri, "http://example.com/cherry/grape/lemon?a=b");

    $uri = Path::Abstract::URI->new(uri => "http://example.com/cherry?a=b", child => "grape/lemon");
    is($uri, "http://example.com/cherry/grape/lemon?a=b");
}

{
    my $uri = URI::PathAbstract->new("http://example.com?a=b");
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

    $uri->path("grape/blueberry/pineapple");
    is($uri, "http://example.com/grape/blueberry/pineapple?c=d&e=f");

    $uri = URI::PathAbstract->new("http://example.com/cherry?a=b", path => "grape/lemon");
    is($uri, "http://example.com/grape/lemon?a=b");

    $uri = URI::PathAbstract->new("http://example.com/cherry?a=b", child => "grape/lemon");
    is($uri, "http://example.com/cherry/grape/lemon?a=b");

    $uri = URI::PathAbstract->new(uri => "http://example.com/cherry?a=b", child => "grape/lemon");
    is($uri, "http://example.com/cherry/grape/lemon?a=b");
}
