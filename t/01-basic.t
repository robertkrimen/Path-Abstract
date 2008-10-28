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
        $path = path 'a.html.tar.gz';
        $path->pop;
        is($path, '');

        $path = path '/a.html.tar.gz';
        $path->pop;
        is($path, '/');

        $path = path 'a.html.tar.gz';
        $path->up;
        is($path, '');

        $path = path '/a.html.tar.gz';
        $path->up;
        is($path, '/');
    }

    {
        cmp_deeply([ path( 'a/b/c' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( '/a/b/c' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( '/a/b/c/' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( 'a/b/c/' )->list ], [qw/ a b c /]);

        cmp_deeply([ path( 'a/b/c' )->split ], [qw( a b c )]);
        cmp_deeply([ path( '/a/b/c' )->split ], [qw( /a b c )]);
        cmp_deeply([ path( '/a/b/c/' )->split ], [qw( /a b c/ )]);
        cmp_deeply([ path( 'a/b/c/' )->split ], [qw( a b c/ )]);
    }

    {
        my $path;
        # .append
        $path = path();

        $path->append("c/d");
        is("c/d", $path.'');
        is("d", $path->last());

        $path->append("ef");
        is("c/def", $path.'');
        is("def", $path->last());

        $path->append("", "g/");
        is("c/def/g/", $path.'');
        is("g", $path->last());
    }

    {
        my $path;
        # .extension
        $path = path("a.tar.gz.html");

        is(".html", $path->extension());
        is(".gz.html", $path->extension({ match => 2 }));
        is(".tar.gz.html", $path->extension({ match => 3 }));
        is(".tar.gz.html", $path->extension({ match => 4 }));
        is("a", $path->clone()->extension("", { match => 4 }));

        is("a.tar.gz.txt", $path->clone()->extension(".txt").'');
        is("a.tar.txt", $path->clone()->extension(".txt", 2).'');
        is("a.txt", $path->clone()->extension(".txt", 3).'');
        is("a.tar", $path->clone()->extension(".txt", 3)->extension(".tar").'');
        is("a", $path->clone()->extension(".txt", 3)->extension("").'');

        $path->set("");
        is("", $path->extension());
        is(".html", $path->clone()->extension("html").'');
        is(".html", $path->clone()->extension(".html").'');
        is("", $path->clone()->extension("").'');

        $path->set("/");
        is("", $path->extension());
        is("/.html.gz", $path->clone()->extension("html.gz").'');
        is("/.html.gz", $path->clone()->extension(".html.gz").'');
        is("/", $path->clone()->extension("").'');

        is(".html", path( "a/b/c.html" )->extension());
        is("", path( "a/b/c" )->extension());
        is(".gz", path( "a/b/c.tar.gz" )->extension());
        is(".tar.gz", path( "a/b/c.tar.gz" )->extension({ match => "*" }));
        is("a/b/c.txt", path( "a/b/c.html" )->extension( ".txt" ));
        is("a/b/c.zip", path( "a/b/c.html" )->extension( "zip" ));
        is("a/b/c", path( "a/b/c.html" )->extension( "" ));
        is("a/b/c.", path( "a/b/c.html" )->extension( "." ));

        $path = path("a/b/c");
        is("a/b/c.html", $path->extension(".html").'');
        is("a/b/c.html", $path->extension(".html").'');
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
        cmp_deeply([], [ $path->list ]);

        $path = path("/");
        is("/", $path . "");
        is("/", $path->get());
        is("", $path->at(0));
        is("", $path->at(-1));
        is("", $path->at(1));
        is("", $path->first());
        is("", $path->last());
        is("/", $path->beginning());
        is("/", $path->ending());
        cmp_deeply([], [ $path->list ]);
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
        cmp_deeply([ 'a' ], [ $path->list ]);
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
        is("a", $path->first());
        is("a", $path->last());
        is("/a", $path->beginning());
        is("a", $path->ending());
        cmp_deeply([qw/ a /], [ $path->list ]);
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
        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b", $path->ending());
        cmp_deeply([qw/ a b /], [ $path->list ]);
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
        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b/", $path->ending());
        cmp_deeply([qw/ a b /], [ $path->list ]);
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
        is("a", $path->first());
        is("c", $path->last());
        is("/a", $path->beginning());
        is("c", $path->ending());
        cmp_deeply([qw/ a b c /], [ $path->list ]);
        ok(!$path->is_empty());
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
        cmp_deeply([qw/ a b c /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());
    }
