package Path::Abstract::Fast;

use warnings;
use strict;

=head1 NAME

Path::Abstract::Fast - Path::Abstract without stringification overloading

=head1 SYNOPSIS

  use Path::Abstract::Fast;

  my $path = Path::Abstract::Fast->new("/apple/banana");

  # $parent is "/apple"
  my $parent = $path->parent;

  # $cherry is "/apple/banana/cherry.txt"
  my $cherry = $path->child("cherry.txt");

=cut

use Sub::Exporter -setup => {
	exports => [ path => sub { sub {
		return __PACKAGE__->new(@_)
	} } ],
};
use Scalar::Util qw/blessed/;
use Carp;

=head1 DESCRIPTION

This is a version of Path::Abstract without the magic "use overload ..." stringification.
You should experience a significant speedup if you use Path::Abstract::Fast instead of Path::Abstract

Unfortunately, without overloading, you can't do this:

    my $path = Path::Abstract::Fast->new("/a/path/to/somewhere");

    print "$path\n"; # Will print out something like "Path::Abstract::Fast=SCALAR(0xdffaa0)\n"

You'll have to do this instead:

    print $path->get, "\n"; Will print out "/a/path/to/somewhere\n"
    # Note, you can also use $path->stringify or $path->path

    # You could also do this (but it's safer to do one of the above):
    print $$path, "\n";

Thanks to JJORE, MKANAT, and KONOBI for discovering this

=head1 METHODS

=over 4

=cut

=item Path::Abstract::Fast->new( <path> )

=item Path::Abstract::Fast->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract::Fast> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract::Fast> object

=cut

sub new {
	my $path = "";
	my $self = bless \$path, shift;
	$self->set(@_);
	return $self;
}

=item Path::Abstract::Fast::path( <path> )

=item Path::Abstract::Fast::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract::Fast> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract::Fast> object

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
    @_ = map { my $part = blessed $_ && $_->isa("Path::Abstract::Fast") ? $_->get : $_ ; length $part ? $part : () } @_;
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

Returns the removed path as a C<Path::Abstract::Fast> object

=cut

sub pop {
	my $self = shift;
	return (ref $self)->new('') if $self->is_empty || $self->is_root;
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
	return (ref $self)->new(join '/', @popped);
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

1; # End of Path::Abstract::Fast
