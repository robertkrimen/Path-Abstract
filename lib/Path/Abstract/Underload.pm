package Path::Abstract::Underload;

use warnings;
use strict;

=head1 NAME

Path::Abstract::Underload - Path::Abstract without stringification overloading

=head1 SYNOPSIS

  use Path::Abstract::Underload;

  my $path = Path::Abstract::Underload->new("/apple/banana");

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

require Path::Abstract::Fast; # For now...

=head1 DESCRIPTION

This is a version of Path::Abstract without the magic "use overload ..." stringification.

Unfortunately, without overloading, you can't do this:

    my $path = Path::Abstract::Underload->new("/a/path/to/somewhere");

    print "$path\n"; # Will print out something like "Path::Abstract::Underload=SCALAR(0xdffaa0)\n"

You'll have to do this instead:

    print $path->get, "\n"; Will print out "/a/path/to/somewhere\n"
    # Note, you can also use $path->stringify or $path->path

    # You could also do this (but it's safer to do one of the above):
    print $$path, "\n";

Or, just use L<Path::Abstract>

=head1 Different behavior since 0.093

Some methods of Path::Abstract have changed since 0.093 with the goal of having better/more consistent behavior

Unfortunately, this MAY result in code that worked with 0.093 and earlier be updated to reflect the new behavior

The following has changed:

=over

=item $path->list

The old behavior (kept the leading slash but dropped trailing slash):

    path('/a/b/c/')->list    # ( '/a', 'b', 'c' )
    path('a/b/c/')->list     # ( 'a', 'b', 'c' )

The new behavior (neither slash is kept):

    path('/a/b/c/')->list    # ( 'a', 'b', 'c' )
    path('a/b/c/')->list     # ( 'a', 'b', 'c' )

In addition, $path->split was an alias for $path->list, but this has changed. Now split
WILL keep BOTH leading and trailing slashes (if any):

    path('/a/b/c/')->split    # ( '/a', 'b', 'c/' )
    path('a/b/c/')->split     # ( 'a', 'b', 'c/' )
    path('a/b/c')->split      # ( 'a', 'b', 'c' ) Effectively equivalent to ->list

=item $path->split

See the above note on $path->list

=item $path->first

The old behavior:

    1. Would return undef for the empty path
    2. Would include the leading slash (if present)
    3. Would NOT include the trailing slash (if present)
    
    path(undef)->first  # undef
    path('')->first     # undef
    path('/a')->first   # /a
    path('/a/')->first  # /a
    path('a')->first    # a

The new behavior:

    1. Always returns at least the empty string
    2. Never includes any slashes

    path(undef)->first  # ''
    path('')->first     # ''
    path('/a')->first   # a
    path('/a/')->first  # a
    path('a')->first    # a

For an alternative to ->first, try ->beginning

=item $path->last

Simlar to ->first

The old behavior:
    
    1. Would return undef for the empty path
    2. Would include the leading slash (if present)
    3. Would NOT include the trailing slash (if present)
    
    path(undef)->last  # undef
    path('')->last     # undef
    path('/a')->last   # /a
    path('/a/')->last  # /a
    path('a')->last    # a
    path('a/b')->last  # b
    path('a/b/')->last # b

The new behavior:

    1. Always returns at least the empty string
    2. Never includes any slashes

    path(undef)->last  # ''
    path('')->last     # ''
    path('/a')->last   # a
    path('/a/')->last  # a
    path('a')->last    # a
    path('a/b')->last  # b
    path('a/b/')->last # b

For an alternative to ->last, try ->ending

=item $path->is_branch

The old behavior:
    
    1. The empty patch ('') would not be considered a branch
    
The new behavior:
    
    1. The empty patch ('') IS considered a branch

=back

=head1 METHODS

=cut

=head2 Path::Abstract::Underload->new( <path> )

=head2 Path::Abstract::Underload->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract::Underload> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract::Underload> object

=cut

sub new {
	my $path = "";
	my $self = bless \$path, shift;
	$self->set(@_);
	return $self;
}

=head2 Path::Abstract::Underload::path( <path> )

=head2 Path::Abstract::Underload::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract::Underload> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract::Underload> object

=cut

=head2 $path->clone

Returns an exact copy of $path

=cut

sub clone {
	my $self = shift;
	my $path = $$self;
	return bless \$path, ref $self;
}

sub _canonize(@) {
	no warnings 'uninitialized';
    @_ = map {
        $_ = ref && (ref eq "Path::Abstract::Underload" || blessed $_ && $_->isa("Path::Abstract::Underload")) ? $$_ : $_;
        length() ? $_ : ();
    } map {
        ref eq "ARRAY" ? @$_ : $_
    } @_;
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

=head2 $path->set( <path> )

=head2 $path->set( <part>, [ <part>, ..., <part> ] )

Set the path of $path to <path> or the concatenation of each <part> (separated by "/")

Returns $path

=cut

sub set {
	my $self = shift;
	$$self = _canonize @_;
	return $self;
}

=head2 $path->is_nil

=head2 $path->is_empty

Returns true if $path is equal to ""

=cut

sub is_empty {
	my $self = shift;
	return $$self eq "";
}
for (qw(is_nil)) { no strict 'refs'; *$_ = \&is_empty }

=head2 $path->is_root

Returns true if $path is equal to "/"

=cut

sub is_root {
	my $self = shift;
	return $$self eq "/";
}

=head2 $path->is_tree

Returns true if $path begins with "/"

	path("/a/b")->is_tree # Returns true
	path("c/d")->is_tree # Returns false

=cut

sub is_tree {
	my $self = shift;
	return substr($$self, 0, 1) eq "/";
}

=head2 $path->is_branch

Returns true if $path does NOT begin with a "/"

	path("")->is_branch # Returns true
	path("/")->is_branch # Returns false
	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=cut

sub is_branch {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
#    return $$self && substr($$self, 0, 1) ne "/";
    return ! $$self || substr($$self, 0, 1) ne "/";
}

=head2 $path->to_tree

Change $path by prefixing a "/" if it doesn't have one already

Returns $path

=cut

sub to_tree {
	my $self = shift;
	$$self = "/$$self" unless $self->is_tree;
	return $self;
}

=head2 $path->to_branch

Change $path by removing a leading "/" if it has one

Returns $path

=cut

sub to_branch {
	my $self = shift;
	$$self =~ s/^\///;
	return $self;
}

=head2 $path->list

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

NOTE: This behavior is different since 0.093 (see above)

=cut

sub list {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return grep { length $_ } split m/\//, $$self;
}
for (qw()) { no strict 'refs'; *$_ = \&list }

=head2 $path->split

=cut

sub split {
    my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    my @split = split m/(?<=.)\/(?=.)/, $$self;
    return @split;
}

=head2 $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

This is equivalent to $path->at(0)

=cut

sub first {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return $self->at(0);
}

=head2 $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

This is equivalent to $path->at(-1)

=cut

sub last {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return $self->at(-1);
}

=head2 $path->at( $index )

Returns the part of path at $index, not including any slashes
You can use a negative $index to start from the end of path

    path("/a/b/c/").at(0)  # a (equivalent to $path->first)
    path("/a/b/c/").at(-1) # c (equivalent to $path->last)
    path("/a/b/c/").at(1)  # b

=cut

sub at {
    my $self = shift;
    return '' if $self->is_empty;
    my @path = split '/', $$self;
    return '' if 1 == @path && '' eq $path[0];
    my $index = shift;
    if (0 > $index) {
        $index += @path;
    }
    elsif (! defined $path[0] || ! length $path[0]) {
        $index += 1
    }
    return '' if $index >= @path;
    $index -= 1 if $index == @path - 1 && ! defined $path[$index] || ! length $path[$index];
    return '' unless defined $path[$index] && length $path[$index];
    return $path[$index];
}

=head2 $path->beginning

Returns the first part of path, including the leading slash, if any

    path("/a/b/c/")->beginning # /a
    path("a/b/c/")->beginning  # a

=cut

sub beginning {
    my $self = shift;
    my ($beginning) = $$self =~ m{^(\/?[^/]*)};
    return $beginning;
}

=head2 $path->ending

Returns the first part of path, including the leading slash, if any

    path("/a/b/c/")->ending # c/
    path("/a/b/c")->ending  # c

=cut

sub ending {
    my $self = shift;
    my ($ending) = $$self =~ m{([^/]*\/?)$};
    return $ending;
}

=head2 $path->get

=head2 $path->stringify

Returns the path in string or scalar form

	path("c/d")->list # Returns "c/d"
	path("/a/b/")->last # Returns "/a/b"

=cut

sub get {
	my $self = shift;
	return $$self;
}
for (qw(path stringify)) { no strict 'refs'; *$_ = \&get }

=head2 $path->push( <part>, [ <part>, ..., <part> ] )

=head2 $path->down( <part>, [ <part>, ..., <part> ] )

Modify $path by appending each <part> to the end of \$path, separated by "/"

Returns $path

=cut

sub push {
	my $self = shift;
	$$self = _canonize $$self, @_;
	return $self;
}
for (qw(down)) { no strict 'refs'; *$_ = \&push }

=head2 $path->child( <part>, [ <part>, ..., <part> ] )

Make a copy of $path and push each <part> to the end of the new path.

Returns the new child path

=cut

sub child {
	my $self = shift;
	my $child = $self->clone;
	return $child->push(@_);
}

=head2 $path->append( $part1, [ $part2 ], ... )

Modify path by appending $part1 WITHOUT separating it by a slash. Any, optional,
following $part2, ..., will be separated by slashes as normal

      $path = path( "a/b/c" )
      $path->append( "d", "ef/g", "h" ) # "a/b/cd/ef/g/h"

=cut

sub append {
    my $self = shift;
    return $self unless @_;
    $self->set($$self . join '/', @_);
    return $self;
}


=head2 $path->extension

Returns the extension of path, including the leading the dot

Returns "" if path does not have an extension

      path( "a/b/c.html" )->extension // .html
      path( "a/b/c" )->extension // ""
      path( "a/b/c.tar.gz" )->extension // .gz
      path( "a/b/c.tar.gz" )->extension({ match: "*" }) // .tar.gz

=head2 $path->extension( $extension )

Modify path by changing the existing extension of path, if any, to $extension

      path( "a/b/c.html" )->extension( ".txt" ) // a/b/c.txt
      path( "a/b/c.html" )->extension( "zip" ) // a/b/c.zip
      path( "a/b/c.html" )->extension( "" ) // a/b/c

Returns path

=cut

sub extension {
    my $self = shift;

    my $extension;
    if (@_ && ! defined $_[0]) {
        $extension = '';
    }
    elsif (ref $_[0] eq '') {
        $extension = shift;
    }

    my $options;
    if (ref $_[0] eq 'HASH') {
        $options = shift;
    }
    else {
        $options = { match => shift };
    }

    my $matcher = $options->{match} || 1;
    if ('*' eq $matcher) {
        $matcher = '';
    }
    if (ref $matcher eq 'Regexp') {
    }
    elsif ($matcher eq '' || $matcher =~ m/^\d+$/) {
        $matcher = qr/((?:\.[^\.]+){1,$matcher})$/;
    }
    else {
        $matcher = qr/$matcher/;
    }

    my $ending = $self->ending;
    if (! defined $extension) {
        return '' if $self->is_empty || $self->is_root;
        return join '', $ending =~ $matcher;
    }
    else {
        if ('' eq $extension) {
        }
        elsif ($extension !~ m/^\./) {
            $extension = '.' . $extension;
        }

        if ($self->is_empty || $self->is_root) {
            $self->append($extension);
        }
        else {
            if ($ending =~ s/$matcher/$extension/) {
                $self->pop;
                $self->push($ending);
            }
            else {
                $self->append($extension);
            }
        }
        return $self;
    }
    
}

=head2 $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract::Underload> object

=cut

my %pop_re = (
    '' => qr{(/)?([^/]+)(/)?$},
    '$' => qr{(/)?([^/]+/?)()$},
);

sub _pop {
	my $self = shift;
	return '' if $self->is_empty;
	my $count = shift @_;
    $count = 1 unless defined $count;
    my ($greedy_lead, $re);
    if ($count =~ s/([\^\$\*])$//) {
        $greedy_lead = 1 if $1 ne '$';
        $re = $pop_re{'$'} if $1 ne '^';
    }
    $re = $pop_re{''} unless $re;
    $count = 1 unless length $count;

    {
	    my @popped;
        no warnings 'uninitialized';

        while ($count--) {
            if ($$self =~ s/$re//) {
                my $popped = $2;
                unshift(@popped, $popped) if $popped;
                if (! length $$self) {
                    if ($greedy_lead) {
                        substr $popped[0], 0, 0, $1;
                    }
                    else {
                        $$self .= $1;
                    }
                    last;
                }
            }
            else {
                last;
            }
        }

	    return \@popped;
    }
}

#my %pop_re = (
#    '' => qr{(.)?([^/]+)/?$},
#    '+' => qr{(.)?([^/]+)/?$},
#    '*' => qr{(.)?([^/]+/?)$},
#);

#sub _pop {
#    my $self = shift;
#    return '' if $self->is_empty;
#    my $count = shift @_;
#    $count = 1 unless defined $count;
#    my ($greed, $greed_plus, $greed_star);
#    if ($count =~ s/([+*])$//) {
#        $greed = $1;
#        if ($greed eq '+')  { $greed_plus = 1 }
#        else                { $greed_star = 1 }
#    }
#    else {
#        $greed = '';
#    }
#    my $re = $pop_re{$greed};
#    $count = 1 unless length $count;
#    my @popped;

#    while ($count--) {
#        if ($$self =~ s/$re//) {
#            my $popped = $2;
#            unshift(@popped, $popped) if $popped;
#            if ($1 && $1 eq '/' && ! length $$self) { 
#                if ($greed) {
#                    substr $popped[0], 0, 0, $1;
#                }
#                else {
#                    $$self = $1;
#                }
#                last;
#            }
#            elsif (! $$self) {
#                last;
#            }
#        }
#    }
#    return \@popped;
#}

sub pop {
	my $self = shift;
	return (ref $self)->new('') if $self->is_empty;
    my $popped = $self->_pop(@_);
	return (ref $self)->new(join '/', @$popped);
}

=head2 $path->up( <count> )

Modify $path by removing <count> parts from the end of $path

Returns $path

=cut

sub up {
    my $self = shift;
    return $self if $self->is_empty;
    $self->_pop(@_);
    return $self;
}

#sub up {
#    my $self = shift;
#    return $self if $self->is_empty;
#    my $count = 1;
#    $count = shift @_ if @_;
#    while (! $self->is_empty && $count--) {
#        if ($$self =~ s/(^|^\/|\/)([^\/]+)$//) {
#            if ($1 && ! length $$self) {
#                $$self = $1;
#                last;
#            }
#            elsif (! $$self) {
#                last;
#            }
#        }
#    }
#    return $self;
#}

=head2 $path->parent( <count> )

Make a copy of $path and pop <count> parts from the end of the new path

Returns the new parent path

=cut

sub parent {
	my $self = shift;
	my $parent = $self->clone;
	return $parent->up(1, @_);
}

=head2 $path->file

=head2 $path->file( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::File> object using $path as a base, and optionally extending it by each <part>

Returns the new file object

=cut

=head2 $path->dir

=head2 $path->dir( <part>, [ <part>, ..., <part> ] )

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
		*file = sub { return Path::Class::file(shift->get, @_) };
		*dir = sub { return Path::Class::dir(shift->get, @_) };
	}
}

1; # End of Path::Abstract::Underload
