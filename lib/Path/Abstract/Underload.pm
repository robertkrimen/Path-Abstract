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

	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=cut

sub is_branch {
	my $self = shift;
	return $$self && substr($$self, 0, 1) ne "/";
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

=head2 $path->split

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

=cut

sub list {
	my $self = shift;
#    my @list = split m/\//, $$self;
    return grep { length $_ } split m/\//, $$self;
#    return () if $$self eq "/";
##    my @list = split m/(?<!^)\//, $$self;
#    return @list;
}
for (qw(split)) { no strict 'refs'; *$_ = \&list }

=head2 $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

=cut

sub first {
	my $self = shift;
    return $self->at(0);
	return '' if $self->is_nil;
	my @path = $self->list;
	return shift @path;
}

=head2 $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

=cut

sub last {
	my $self = shift;
    return $self->at(-1);
	return '' if $self->is_nil;
	my @path = $self->list;
	return pop @path;
}

=head2 $path->at( $index )

Returns the part of path at $index, not including any slashes
You can use a negative $index to start from the end of path

    path("/a/b/c/").at(0)  # a (equivalent to $path->first)
    path("/a/b/c/").at(-1) # c (equivalent to $path->last)
    path("/a/b/c/").at(1)  # b

=cut

#        _at: function(position) {
#            if (this.isEmpty()) return -1;
#            if (1 == this._path.length && "" == this._path[0])
#                return -1;
#            if (0 > position)
#                position += this._path.length;
#            else if ("" == this._path[0])
#                position += 1;
#            if (position >= this._path.length)
#                return -1;
#            if (position == this._path.length - 1 && "" == this._path[position])
#                position -= 1;
#            return position;
#        },

#        at: function(position) {
#            position = this._at(position);
#            if (-1 == position)
#                return "";
#            return this._path[position];
#//            if (this.isEmpty()) return "";
#//            if (1 == this._path.length && "" == this._path[0])
#//                return "";
#//            if (0 > ii)
#//                ii += this._path.length;
#//            else if ("" == this._path[0])
#//                ii += 1;
#//            if (ii >= this._path.length)
#//                return "";
#//            if (ii == this._path.length - 1 && "" == this._path[ii])
#//                ii -= 1;
#//            return this._path[ii];
#        },

sub _at {
    my $self = shift;
}

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
#        $matcher = qr/(?:\.[^\.]+)$/;
    }
    else {
        $matcher = qr/$matcher/;
    }

    my $ending = $self->ending;
    if (! defined $extension) {
        return '' if $self->is_empty || $self->is_root;
#warn $ending, ' =~ ', $matcher;
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


#        extension: function(extension, $options) {
#            if (arguments.length == 1 && "object" == typeof extension) {
#                $options = extension;
#                extension = null;
#            }
#            else if (arguments.length) {
#                if (null == extension)
#                    extension = "";
#            }

#            if (!$options)
#                $options = {};
#            else {   
#                if (b9j.isFunction($options.exec)) { // $options is a RegExp object
#                    $options = { match: $options }
#                }
#                else if ("object" == typeof $options) {
#                }
#                else {
#                    $options = { match: $options }
#                }
#            }   

#            var matcher = $options.match || 1;
#            if ("*" == matcher)
#                matcher = "";
#            if ("" == matcher || "number" == typeof matcher) {

#                matcher = new RegExp("(\\.[^\\.]+){1," + matcher + "}$", "g");
#//                var _matcher = ""
#//                while (matcher--)
#//                    _matcher += "(\\.[^\\.]+)?"
#//                matcher = new RegExp(_matcher + "$", "g");
#            }
#            else if ("string" == typeof matcher) {
#                matcher = new RegExp(matcher);
#            }

#            var ending = this.ending();

#            if (null == extension) {
#                if (this.isEmpty() || this.isRoot())
#                    return "";
#                var match = matcher.exec(ending);
#                if (! match)
#                    return "";
#                return match[0];
#            }
#            else {
#                if ("" == extension)
#                    ;
#                else if (extension[0] != ".")
#                    extension = "." + extension

#                if (this.isEmpty() || this.isRoot())
#                    this.append(extension);
#                else {
#                    if (matcher.test(ending)) {
#                        ending = ending.replace(matcher, extension);
#                        this.pop();
#                        this.push(ending);
#                    }
#                    else {
#                        this.append(extension);
#                    }
#                }
#                return this;
#            }
#        },

#/*
# * =head2 path.extension()
# *
# * Returns the extension of path, including the leading the dot
# *
# * Returns "" if path does not have an extension
# *
# *          new b9j.path.Path( "a/b/c.html" ).extension() // .html
# *          new b9j.path.Path( "a/b/c" ).extension() // ""
# *          new b9j.path.Path( "a/b/c.tar.gz" ).extension() // .gz
# *          new b9j.path.Path( "a/b/c.tar.gz" ).extension({ match: "*" }) // .tar.gz
# *
# * =head2 path.extension( $extension )
# *
# * Modify path by changing the existing extension of path, if any, to $extension
# *
# *          new b9j.path.Path( "a/b/c.html" ).extension( ".txt" ) // a/b/c.txt
# *          new b9j.path.Path( "a/b/c.html" ).extension( "zip" ) // a/b/c.zip
# *          new b9j.path.Path( "a/b/c.html" ).extension( "" ) // a/b/c
# *
# * Returns path
# *
# */
#        extension: function(extension, $options) {
#            if (arguments.length == 1 && "object" == typeof extension) {
#                $options = extension;
#                extension = null;
#            }
#            else if (arguments.length) {
#                if (null == extension)
#                    extension = "";
#            }

#            if (!$options)
#                $options = {};
#            else {   
#                if (b9j.isFunction($options.exec)) { // $options is a RegExp object
#                    $options = { match: $options }
#                }
#                else if ("object" == typeof $options) {
#                }
#                else {
#                    $options = { match: $options }
#                }
#            }   

#            var matcher = $options.match || 1;
#            if ("*" == matcher)
#                matcher = "";
#            if ("" == matcher || "number" == typeof matcher) {

#                matcher = new RegExp("(\\.[^\\.]+){1," + matcher + "}$", "g");
#//                var _matcher = ""
#//                while (matcher--)
#//                    _matcher += "(\\.[^\\.]+)?"
#//                matcher = new RegExp(_matcher + "$", "g");
#            }
#            else if ("string" == typeof matcher) {
#                matcher = new RegExp(matcher);
#            }

#            var ending = this.ending();

#            if (null == extension) {
#                if (this.isEmpty() || this.isRoot())
#                    return "";
#                var match = matcher.exec(ending);
#                if (! match)
#                    return "";
#                return match[0];
#            }
#            else {
#                if ("" == extension)
#                    ;
#                else if (extension[0] != ".")
#                    extension = "." + extension

#                if (this.isEmpty() || this.isRoot())
#                    this.append(extension);
#                else {
#                    if (matcher.test(ending)) {
#                        ending = ending.replace(matcher, extension);
#                        this.pop();
#                        this.push(ending);
#                    }
#                    else {
#                        this.append(extension);
#                    }
#                }
#                return this;
#            }
#        },


=head2 $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract::Underload> object

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
			if ($1 && $1 eq '/' && ! length $$self) { 
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

=head2 $path->up( <count> )

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
