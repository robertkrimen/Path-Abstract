package Path::Abstract;

use warnings;
use strict;

=head1 NAME

Path::Abstract - Fast and featureful UNIX-style path manipulation

=head1 VERSION

Version 0.085

=head1 SYNOPSIS

  use Path::Abstract;

  my $path = Path::Abstract->new("/apple/banana");

  # $parent is "/apple"
  my $parent = $path->parent;

  # $cherry is "/apple/banana/cherry.txt"
  my $cherry = $path->child("cherry.txt");

=cut

our $VERSION = '0.085';

use Sub::Exporter -setup => {
	exports => [ path => sub { sub {
		return __PACKAGE__->new(@_)
	} } ],
};

use overload
	'""' => 'get',
	fallback => 1,
;

use base qw/Path::Abstract::Fast/;

=head1 METHODS

=head2 Path::Abstract->new( <path> )

=head2 Path::Abstract->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=head2 Path::Abstract::path( <path> )

=head2 Path::Abstract::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=head2 $path->clone

Returns an exact copy of $path

=head2 $path->set( <path> )

=head2 $path->set( <part>, [ <part>, ..., <part> ] )

Set the path of $path to <path> or the concatenation of each <part> (separated by "/")

Returns $path

=head2 $path->is_nil

=head2 $path->is_empty

Returns true if $path is equal to ""

=head2 $path->is_root

Returns true if $path is equal to "/"

=head2 $path->is_tree

Returns true if $path begins with "/"

	path("/a/b")->is_tree # Returns true
	path("c/d")->is_tree # Returns false

=head2 $path->is_branch

Returns true if $path does NOT begin with a "/"

	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=head2 $path->to_tree

Change $path by prefixing a "/" if it doesn't have one already

Returns $path

=head2 $path->to_branch

Change $path by removing a leading "/" if it has one

Returns $path

=head2 $path->list

=head2 $path->split

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

=head2 $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

=head2 $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

=head2 path

=head2 $path->get

=head2 $path->stringify

Returns the path in string or scalar form

	path("c/d")->list # Returns "c/d"
	path("/a/b/")->last # Returns "/a/b"

=head2 $path->push( <part>, [ <part>, ..., <part> ] )

=head2 $path->down( <part>, [ <part>, ..., <part> ] )

Modify $path by appending each <part> to the end of \$path, separated by "/"

Returns $path

=head2 $path->child( <part>, [ <part>, ..., <part> ] )

Make a copy of $path and push each <part> to the end of the new path.

Returns the new child path

=head2 $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract> object

=head2 $path->up( <count> )

Modify $path by removing <count> parts from the end of $path

Returns $path

=head2 $path->parent( <count> )

Make a copy of $path and pop <count> parts from the end of the new path

Returns the new parent path

=head2 $path->file

=head2 $path->file( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::File> object using $path as a base, and optionally extending it by each <part>

Returns the new file object

=head1 NOTES

The module formerly known as Path::Lite

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-path-lite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Abstract>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Path::Abstract

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Path-Abstract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Path-Abstract>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Abstract>

=item * Search CPAN

L<http://search.cpan.org/dist/Path-Abstract>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Joshua ben Jore, Max Kanat-Alexander, and Scott McWhirter for discovering the "use overload ..." slowdown issue.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Path::Abstract
