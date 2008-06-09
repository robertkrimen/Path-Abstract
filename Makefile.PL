use inc::Module::Install;

name 'Path-Abstract';
all_from 'lib/Path/Abstract.pm';

build_requires 'Test::More';
build_requires 'Test::Lazy';

requires 'Scalar::Util';
requires 'Sub::Exporter';
requires 'Carp';

recommends 'Path::Class';

auto_install;

WriteAll;

