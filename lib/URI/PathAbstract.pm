package URI::PathAbstract;

use strict;
use warnings;

use base qw/Path::Abstract::URI/;

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

=head1 DESCRIPTION

URI::PathAbstract is a combination of the L<URI> and L<Path::Abstract> classes. It is essentially a URI
class that delegate path-handling methods to Path::Abstract

Unfortunately, this is not true:

    URI::PathAbstract->new( http://example.com )->isa( URI )

URI::PathAbstract supports the L<URI> generic and common methods

=cut

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

=head2 * URI *

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

=head2 $uri->abs

Returns a L<URI::PathAbstract> object

=head2 $uri->rel

Returns a L<URI::PathAbstract> object

=head2 $uri->opaque

=head2 $uri->path_query

=head2 $uri->path_segments

=head2 * Path::Abstract *

See L<Path::Abstract> for more information

=head2 $uri->child

=head2 $uri->parent

=head2 $uri->list

=head2 $uri->first

=head2 $uri->last

=head2 $uri->is_empty

=head2 $uri->is_nil

=head2 $uri->is_root

=head2 $uri->is_tree

=head2 $uri->is_branch

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
