package Path::Abstract;

use warnings;
use strict;

=head1 NAME

Path::Abstract - A fast and featureful class for UNIX-style path manipulation.

=head1 VERSION

Version 0.071

=head1 SYNOPSIS

  use Path::Abstract;

  my $path = Path::Abstract->new("/apple/banana");

  # $parent is "/apple"
  my $parent = $path->parent;

  # $cherry is "/apple/banana/cherry.txt"
  my $cherry = $path->child("cherry.txt");

=cut

our $VERSION = '0.071';

use Sub::Exporter -setup => {
	exports => [ path => sub { sub {
		return __PACKAGE__->new(@_)
	} } ],
};
use Scalar::Util qw/blessed/;
use Carp;

use overload
	'""' => 'get',
	fallback => 1,
;

=over 4

=cut

=item Path::Abstract->new( <path> )

=item Path::Abstract->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=cut

sub new {
	my $path = "";
	my $self = bless \$path, shift;
	$self->set(@_);
	return $self;
}

=item Path::Abstract::path( <path> )

=item Path::Abstract::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=cut

=item $path->clone

Returns an exact copy of $path

=cut

sub clone {
	my $self = shift;
	my $path = $$self;
	return bless \$path, ref $self;
}

sub _canonize(@) {
	no warnings 'uninitialized';
    @_ = grep { length $_ } @_;
	my $leading = $_[0] && substr($_[0], 0, 1) eq '/';
	my $path = join '/', @_;
	my $trailing = $path && substr($path, -1) eq '/';

	# From File::Spec::Unix::canonpath
	$path =~ s|/{2,}|/|g;				# xx////xx  -> xx/xx
	$path =~ s{(?:/\.)+(?:/|\z)}{/}g;		# xx/././xx -> xx/xx
	$path =~ s|^(?:\./)+||s unless $path eq "./";	# ./xx      -> xx
	$path =~ s|^/(?:\.\./)+|/|;			# /../../xx -> xx
	$path =~ s|^/\.\.$|/|;				# /..       -> /
	$path =~ s|/\z|| unless $path eq "/";		# xx/       -> xx
	$path .= '/' if $path ne "/" && $trailing;

	$path =~ s/^\/+// unless $leading;
	return $path;
}

=item $path->set( <path> )

=item $path->set( <part>, [ <part>, ..., <part> ] )

Set the path of $path to <path> or the concatenation of each <part> (separated by "/")

Returns $path

=cut

sub set {
	my $self = shift;
	$$self = _canonize @_;
	return $self;
}

=item $path->is_nil

=item $path->is_empty

Returns true if $path is equal to ""

=cut

sub is_empty {
	my $self = shift;
	return $$self eq "";
}
for (qw(is_nil)) { no strict 'refs'; *$_ = \&is_empty }

=item $path->is_root

Returns true if $path is equal to "/"

=cut

sub is_root {
	my $self = shift;
	return $$self eq "/";
}

=item $path->is_tree

Returns true if $path begins with "/"

	path("/a/b")->is_tree # Returns true
	path("c/d")->is_tree # Returns false

=cut

sub is_tree {
	my $self = shift;
	return substr($$self, 0, 1) eq "/";
}

=item $path->is_branch

Returns true if $path does NOT begin with a "/"

	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=cut

sub is_branch {
	my $self = shift;
	return $$self && substr($$self, 0, 1) ne "/";
}

=item $path->to_tree

Change $path by prefixing a "/" if it doesn't have one already

Returns $path

=cut

sub to_tree {
	my $self = shift;
	$$self = "/$$self" unless $self->is_tree;
	return $self;
}

=item $path->to_branch

Change $path by removing a leading "/" if it has one

Returns $path

=cut

sub to_branch {
	my $self = shift;
	$$self =~ s/^\///;
	return $self;
}

=item $path->list

=item $path->split

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

=cut

sub list {
	my $self = shift;
	return ("/") if $$self eq "/";
	my @list = split m/(?<!^)\//, $$self;
	return @list;
}
for (qw(split)) { no strict 'refs'; *$_ = \&list }

=item $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

=cut

sub first {
	my $self = shift;
	return if $self->is_nil;
	my @path = $self->list;
	return shift @path;
}

=item $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

=cut

sub last {
	my $self = shift;
	return if $self->is_nil;
	my @path = $self->list;
	return pop @path;
}

=item path

=item $path->get

=item $path->stringify

Returns the path in string or scalar form

	path("c/d")->list # Returns "c/d"
	path("/a/b/")->last # Returns "/a/b"

=cut

sub get {
	my $self = shift;
	return $$self;
}
for (qw(path stringify)) { no strict 'refs'; *$_ = \&get }

=item $path->push( <part>, [ <part>, ..., <part> ] )

=item $path->down( <part>, [ <part>, ..., <part> ] )

Modify $path by appending each <part> to the end of \$path, separated by "/"

Returns $path

=cut

sub push {
	my $self = shift;
	$$self = _canonize $$self, @_;
	return $self;
}
for (qw(down)) { no strict 'refs'; *$_ = \&push }

=item $path->child( <part>, [ <part>, ..., <part> ] )

Make a copy of $path and push each <part> to the end of the new path.

Returns the new child path

=cut

sub child {
	my $self = shift;
	my $child = $self->clone;
	return $child->push(@_);
}

=item $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract> object

=cut

sub pop {
	my $self = shift;
	return __PACKAGE__->new('') if $self->is_empty || $self->is_root;
	my $count = 1;
	$count = shift @_ if @_;
	my @popped;

	while ($count--) {
		if ($$self =~ s/(.?)([^\/]+)$//) {
			my $popped = $2;
			CORE::unshift(@popped, $popped) if $popped;
			if ($1 && ! length $$self) {
				$$self = $1;
				last;
			}
			elsif (! $$self) {
				last;
			}
		}
	}
	return __PACKAGE__->new(join '/', @popped);
}

=item $path->up( <count> )

Modify $path by removing <count> parts from the end of $path

Returns $path

=cut

sub up {
	my $self = shift;
	return $self if $self->is_empty || $self->is_root;
	my $count = 1;
	$count = shift @_ if @_;
	while (! $self->is_empty && $count--) {
		if ($$self =~ s/(^|^\/|\/)([^\/]+)$//) {
			if ($1 && ! length $$self) {
				$$self = $1;
				last;
			}
			elsif (! $$self) {
				last;
			}
		}
	}
	return $self;
}

=item $path->parent( <count> )

Make a copy of $path and pop <count> parts from the end of the new path

Returns the new parent path

=cut

sub parent {
	my $self = shift;
	my $parent = $self->clone;
	return $parent->up(1, @_);
}

=item $path->file

=item $path->file( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::File> object using $path as a base, and optionally extending it by each <part>

Returns the new file object

=cut

=item $path->dir

=item $path->dir( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::Dir> object using $path as a base, and optionally extending it by each <part>

Returns the new dir object

=cut

BEGIN {
	no strict 'refs';
	eval { require Path::Class };
	if ($@) {
		*dir = *file = sub { croak "Path::Class is not available" };
	}
	else {
		*file = sub { return Path::Class::file($_[0]->get, @_) };
		*dir = sub { return Path::Class::dir($_[0]->get, @_) };
	}
}

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

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Path::Abstract
