package Path::Abstract::URI;

use strict;
use warnings;

use URI;
use Path::Abstract;
use Scalar::Util qw/blessed/;

use overload
    '""' => sub { $_[0]->{uri}->as_string },
    '==' => sub { overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
    fallback => 1,
;

sub new {
    my $self = bless {}, shift;
    $self->uri(shift);
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
file
dir
_END_
        *$method = sub {
            my $self = shift;
            return $self->{path}->$method(@_);
        }
    }
}

1;
