package URI::PathAbstract;

use strict;
use warnings;

=head1 NAME

URI::PathAbstract - A URI-like object with Path::Abstract capabilities

=head1 SYNOPSIS

    my $uri = URI::PathAbstract->new("http://example.com?a=b")

    $uri->down("apple")
    # http://example.com/apple?a=b

    $uri->query("c=d&e=f")
    # http://example.com/apple?c=d&e=f

    $uri->path("grape/blueberry/pineapple")
    # http://example.com/grape/blueberry/pineapple?c=d&e=f

    $uri = $uri->parent
    # http://example.com/grape/blueberry?c=d&e=f

    $uri = $uri->child("xyzzy")
    # http://example.com/grape/blueberry/xyzzy?c=d&e=f

=head1 DESCRIPTION

URI::PathAbstract is a combination of the L<URI> and L<Path::Abstract> classes. It is essentially a URI
class that delegates path-handling methods to Path::Abstract

Unfortunately, this is not true:

    URI::PathAbstract->new( http://example.com )->isa( URI )

URI::PathAbstract supports the L<URI> generic and common methods

=cut

use URI;
use Path::Abstract;
use Scalar::Util qw/blessed/;
use Carp;

use overload
    '""' => sub { $_[0]->{uri}->as_string },
    '==' => sub { overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
    fallback => 1,
;

=head1 METHODS

=head2 URI::PathAbstract->new( <uri> )

Create a new URI::PathAbstract object based on <uri>

<uri> should be of the L<URI> class or some sort of URI-like string

=head2 URI::PathAbstract->new( <uri>, path => <path> )

Create a new URI::PathAbstract object based on <uri> but overriding the path with <path>

    URI::PathAbstract->new("http://example.com/cherry?a=b", path => "grape/lemon")
    # http://example.com/grape/lemon?a=b"

=head2 URI::PathAbstract->new( <uri>, child => <child> )

Create a new URI::PathAbstract object based on <uri> but modifying the path by <child>

    URI::PathAbstract->new("http://example.com/cherry?a=b", child => "grape/lemon")
    # http://example.com/cherry/grape/lemon?a=b"

=head2 $uri->uri

Returns a L<URI> object that is a copy (not a reference) of the URI object inside $uri

=head2 $uri->path

Returns a L<Path::Abstract> object that is a copy (not a reference) of the Path::Abstract object inside $uri

=head2 $uri->path( <path> )

Sets the path of $uri, completely overwriting what was there before

The rest of $uri (host, port, scheme, query, ...) does not change

=head2 $uri->clone

Returns a URI::PathAbstract that is an exact clone of $uri

=cut

sub new {
    my $self = bless {}, shift;

    if (@_ == 1 ) {
        $self->uri(shift);
    }
    elsif (@_ % 2) {
        $self->uri(shift);
        my %given = @_;
        $self->path($given{path}) if exists $given{path};
        $self->down($given{child}) if exists $given{child};
    }
    elsif (@_) {
        my %given = @_;
        $self->uri($given{uri});
        $self->path($given{path}) if exists $given{path};
        $self->down($given{child}) if exists $given{child};
    }
    else {
        $self->uri(URI->new);
    }

    return $self;
}

sub uri {
    my $self = shift;
    return $self->{uri}->clone unless @_;
    my $uri = shift;
    $uri = URI->new($uri) unless blessed $uri;
    $self->path($uri->path, 1);
    $self->{uri} = $uri->clone;
    return $self;
}

sub path {
    my $self = shift;
    return $self->{path}->clone unless @_;
    my $path = shift;
    $path = "" unless defined $path;
    $path = Path::Abstract->new("$path");
    my $skip_modifying = shift;
    $path->to_tree;
    $self->{path} = $path;
    $self->{uri}->path($path->get) unless $skip_modifying;
    return $self;
}

sub clone {
    my $self = shift;
    my $class = ref $self;
    return $class->new($self->uri);
}

{

=head2 * L<URI> *

See L<URI> for more information

=head2 scheme

=head2 fragment

=head2 as_string

=head2 canonical

=head2 eq

=head2 authority

=head2 query

=head2 query_form

=head2 query_keywords

=head2 userinfo

=head2 host

=head2 port

=head2 host_port

=head2 default_port

=cut

    no strict 'refs';

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
scheme
fragment
as_string
canonical
eq
authority
query
query_form
query_keywords
userinfo
host
port
host_port
default_port
_END_
        *$method = sub {
            my $self = shift;
            return $self->{uri}->$method(@_);
        }
    }

=head2 abs

Returns a L<URI::PathAbstract> object

=head2 rel

Returns a L<URI::PathAbstract> object

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
abs
rel
_END_
        *$method = sub {
            my $self = shift;
            my $uri = $self->{uri}->$method(@_);
            my $class = ref $self;
            return $class->new($uri);
        }
    }

=head2 opaque

=head2 path_query

=head2 path_segments

=head2 * L<Path::Abstract> *

See L<Path::Abstract> for more information

=head2 child

=head2 parent

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
child
parent
_END_
        *$method = sub {
            my $self = shift;
            my $path = $self->{path}->$method(@_);
            my $clone = $self->clone;
            $clone->path($path);
            return $clone;
        }
    }

=head2 up

=head2 pop

=head2 down

=head2 push

=head2 to_tree

=head2 to_branch

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
up
pop
down
push
to_tree
to_branch
#set
_END_
        *$method = sub {
            my $self = shift;
            my $path = $self->{path};
            my @result;
            if (wantarray) {
                my @result = $path->$method(@_);
            }
            else {
                $result[0] = $path->$method(@_);
            }
            $self->path($$path);
            return wantarray ? @result : $result[0];
        }
    }
    
=head2 list

=head2 first

=head2 last

=head2 is_empty

=head2 is_nil

=head2 is_root

=head2 is_tree

=head2 is_branch

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
#get
list
first
last
is_empty
is_nil
is_root
is_tree
is_branch
_END_
        *$method = sub {
            my $self = shift;
            return $self->{path}->$method(@_);
        }
    }
}

=head1 SEE ALSO

L<Path::Abstract>

L<Path::Resource>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/path-abstract/tree/master>

    git clone git://github.com/robertkrimen/path-abstract.git Path-Abstract

=cut

1;
