use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Path::Abstract',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Path/Abstract.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Lazy' => 0,
    	'Scalar::Util' => 0,
    },
    requires => {
    	'Scalar::Util' => 0,
	'Sub::Exporter' => 0,
    	'Carp' => 0,
    },
    optional => {
    	'Path::Class' => 0,
    },
    add_to_cleanup      => [ 'Path-Abstract-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
