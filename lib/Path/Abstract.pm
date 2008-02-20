package Path::Abstract;

use warnings;
use strict;

=head1 NAME

Path::Abstract - A fast and featureful class for UNIX-style path manipulation

=head1 VERSION

Version 0.080

=head1 SYNOPSIS

  use Path::Abstract;

  my $path = Path::Abstract->new("/apple/banana");

  # $parent is "/apple"
  my $parent = $path->parent;

  # $cherry is "/apple/banana/cherry.txt"
  my $cherry = $path->child("cherry.txt");

=cut

our $VERSION = '0.080';

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

=over 4

=item Path::Abstract->new( <path> )

=item Path::Abstract->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=item Path::Abstract::path( <path> )

=item Path::Abstract::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=item $path->clone

Returns an exact copy of $path

=item $path->set( <path> )

=item $path->set( <part>, [ <part>, ..., <part> ] )

Set the path of $path to <path> or the concatenation of each <part> (separated by "/")

Returns $path

=item $path->is_nil

=item $path->is_empty

Returns true if $path is equal to ""

=item $path->is_root

Returns true if $path is equal to "/"

=item $path->is_tree

Returns true if $path begins with "/"

	path("/a/b")->is_tree # Returns true
	path("c/d")->is_tree # Returns false

=item $path->is_branch

Returns true if $path does NOT begin with a "/"

	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=item $path->to_tree

Change $path by prefixing a "/" if it doesn't have one already

Returns $path

=item $path->to_branch

Change $path by removing a leading "/" if it has one

Returns $path

=item $path->list

=item $path->split

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

=item $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

=item $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

=item path

=item $path->get

=item $path->stringify

Returns the path in string or scalar form

	path("c/d")->list # Returns "c/d"
	path("/a/b/")->last # Returns "/a/b"

=item $path->push( <part>, [ <part>, ..., <part> ] )

=item $path->down( <part>, [ <part>, ..., <part> ] )

Modify $path by appending each <part> to the end of \$path, separated by "/"

Returns $path

=item $path->child( <part>, [ <part>, ..., <part> ] )

Make a copy of $path and push each <part> to the end of the new path.

Returns the new child path

=item $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract> object

=item $path->up( <count> )

Modify $path by removing <count> parts from the end of $path

Returns $path

=item $path->parent( <count> )

Make a copy of $path and pop <count> parts from the end of the new path

Returns the new parent path

=item $path->file

=item $path->file( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::File> object using $path as a base, and optionally extending it by each <part>

Returns the new file object

=back 

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
