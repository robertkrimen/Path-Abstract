#!perl -T

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Path::Abstract qw/path/;

{
    my $path;

    $path = path [qw/a b c d ef g h/];
    is($path, "a/b/c/d/ef/g/h");
    $path = $path->child([qw/.. ij k lm/]);
    is($path, "a/b/c/d/ef/g/h/../ij/k/lm");

    $path = path "/a/b/c/d";
    is($path, "/a/b/c/d");
    $path->pop(8);
    is($path, "/");
}

    {
        my $path;
        $path = path();
        is("", $path . "");
        is("", $path->get());
        is("", $path->at(0));
        is("", $path->at(-1));
        is("", $path->at(1));
        is("", $path->first());
        is("", $path->last());
        is("", $path->beginning());
        is("", $path->ending());
        ok($path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok(!$path->is_branch());
#        test.areEqual(new Array().toString(), $path->list().toString());

        $path = path("/");
        is("/", $path . "");
        is("/", $path->get());
        is("", $path->at(0));
        is("", $path->at(-1));
        is("", $path->at(1));
#        is("", $path->first());
#        is("", $path->last());
        is("/", $path->beginning());
        is("/", $path->ending());
#        test.areEqual([].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok($path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("a");
        is("a", $path . "");
        is("a", $path->get());
        is("a", $path->at(0));
        is("a", $path->at(-1));
        is("", $path->at(1));
        is("a", $path->first());
        is("a", $path->last());
        is("a", $path->beginning());
        is("a", $path->ending());
#        test.areEqual([ "a" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());

        $path = path("/a");
        is("/a", $path . "");
        is("/a", $path->get());
        is("a", $path->at(0));
        is("a", $path->at(-1));
        is("", $path->at(1));
#        is("a", $path->first());
#        is("a", $path->last());
        is("/a", $path->beginning());
        is("a", $path->ending());
#        test.areEqual([ "a" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b");
        is("/a/b", $path . "");
        is("/a/b", $path->get());
        is("a", $path->at(0));
        is("b", $path->at(-1));
        is("b", $path->at(1));
#        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b", $path->ending());
#        test.areEqual([ "a", "b" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b/");
        is("/a/b/", $path . "");
        is("/a/b/", $path->get());
        is("a", $path->at(0));
        is("b", $path->at(-1));
        is("b", $path->at(1));
#        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b/", $path->ending());
#        test.areEqual([ "a", "b" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b/c");
        is("/a/b/c", $path . "");
        is("/a/b/c", $path->get());
        is("a", $path->at(0));
        is("c", $path->at(-1));
        is("b", $path->at(1));
#        is("a", $path->first());
        is("c", $path->last());
        is("/a", $path->beginning());
        is("c", $path->ending());
#        test.areEqual([ "a", "b", "c" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("a/b/c");
        is("a/b/c", $path . "");
        is("a/b/c", $path->get());
        is("a", $path->at(0));
        is("c", $path->at(-1));
        is("b", $path->at(1));
        is("a", $path->first());
        is("c", $path->last());
        is("a", $path->beginning());
        is("c", $path->ending());
#        test.areEqual([ "a", "b", "c" ].toString(), $path->list().toString());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());
    }
