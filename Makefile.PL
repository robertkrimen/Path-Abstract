use inc::Module::Install;

name 'Path-Abstract';
all_from 'lib/Path/Abstract.pm';

{
    require ExtUtils::MakeMaker;
    use strict;
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.sw[p-z]$/;
        return $_[1];
    };
}

{
    map { my ($pk, $vr) = split m/\s/; build_requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Test::More
Test::Most
Test::Lazy
_END_

    map { my ($pk, $vr) = split m/\s/; requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Scalar::Util
Sub::Exporter
Carp
_END_

    map { my ($pk, $vr) = split m/\s/; recommends $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Path::Class
_END_
}

auto_install;

WriteAll;

