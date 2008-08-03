package Path::Abstract::URI;

use strict;
use warnings;

=head1 NAME

Path::Abstract::URI - A URI-like object with Path::Abstract capabilities

=head1 SYNOPSIS

    my $uri = Path::Abstract::URI->new("http://example.com?a=b")

    $uri->down("apple")
    # http://example.com/apple?a=b

    $uri->query("c=d&e=f")
    # http://example.com/apple?c=d&e=f

    $uri->path("grape/blueberry/pineapple")
    # http://example.com/grape/blueberry/pineapple?c=d&e=f

=head1 DESCRIPTION

Path::Abstract::URI is a combination of the L<URI> and L<Path::Abstract> classes. It is essentially a URI
class that delegate path-handling methods to Path::Abstract

Unfortunately, this is not true:

    Path::Abstract::URI->new( http://example.com )->isa( URI )

Path::Abstract:URI supports the L<URI> generic and common methods

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

=head2 Path::Abstract::URI->new( <uri> )

Create a new Path::Abstract::URI object based on <uri>

<uri> should be of the L<URI> class or some sort of URI-like string

=head2 Path::Abstract::URI->new( <uri>, path => <path> )

Create a new Path::Abstract::URI object based on <uri> but overriding the path with <path>

    Path::Abstract::URI->new("http://example.com/cherry?a=b", path => "grape/lemon")
    # http://example.com/grape/lemon?a=b"

=head2 Path::Abstract::URI->new( <uri>, child => <child> )

Create a new Path::Abstract::URI object based on <uri> but modifying the path by <child>

    Path::Abstract::URI->new("http://example.com/cherry?a=b", child => "grape/lemon")
    # http://example.com/cherry/grape/lemon?a=b"

=head2 $uri->uri

Returns a L<URI> object that is a copy (not a reference) of the URI object inside $uri

=head2 $uri->path

Returns a L<Path::Abstract> object that is a copy (not a reference) of the Path::Abstract object inside $uri

=head2 $uri->path( <path> )

Sets the path of $uri, completely overwriting what was there before

The rest of $uri (host, port, scheme, query, ...) does not change

=head2 $uri->clone

Returns a Path::Abstract::URI that is an exact clone of $uri

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

=head2 URI delegated

See L<URI> for more information

=head2 $uri->scheme

=head2 $uri->fragment

=head2 $uri->as_string

=head2 $uri->canonical

=head2 $uri->eq

=head2 $uri->authority

=head2 $uri->query

=head2 $uri->query_form

=head2 $uri->query_keywords

=head2 $uri->userinfo

=head2 $uri->host

=head2 $uri->port

=head2 $uri->host_port

=head2 $uri->default_port

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

=head2 $uri->abs

Returns a L<Path::Abstract::URI> object

=head2 $uri->rel

Returns a L<Path::Abstract::URI> object

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

=head2 $uri->opaque

=head2 $uri->path_query

=head2 $uri->path_segments

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
opaque
path_query
path_segments
_END_
        *$method = sub {
            my $self = shift;
            my @result;
            if (wantarray) {
                @result = $self->{uri}->$method(@_);
            }
            else {
                $result[0] = $self->{uri}->$method(@_);
            }
            $self->path($self->{uri}->path, 1);
            return wantarray ? @result : $result[0];
        }
    }

=head2 Path::Abstract delegated

See L<Path::Abstract> for more information

=head2 $uri->child

=head2 $uri->parent

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

=head2 $uri->list

=head2 $uri->first

=head2 $uri->last

=head2 $uri->is_empty

=head2 $uri->is_nil

=head2 $uri->is_root

=head2 $uri->is_tree

=head2 $uri->is_branch

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

1;
