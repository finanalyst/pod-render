use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::Cached;
use Pod::Render;
plan 3;

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';
my $fn = 'basic-test-pod-file_0';

my Pod::Cached $cache .= new(:path(REP)); # dies if no cache
my Pod::Render::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> Pod::Render::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my Pod::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")));
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin foo
    =end foo
    PODEND

#--MARKER-- Test 1
like $pr.pod-body, /'<section name="foo">' \s* '</section>' /, 'section test';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin foo
    some text
    =end foo
    PODEND
#--MARKER-- Test 2
like $pr.pod-body, / '<section name="foo">' \s* '<p>' \s* 'some text' \s* '</p>' \s* '</section>'/ , 'section + heading';

$pr = cache_test(++$fn, q:to/PODEND/);
    =head1 Talking about Perl 6
    PODEND

if  $*PERL.compiler.name eq 'rakudo'
and $*PERL.compiler.version before v2018.06 {
    skip "Your rakudo is too old for this test. Need 2018.06 or newer";
}
else {
#--MARKER-- Test 3
    unlike $pr.pod-body, / 'Perl 6' /, "no-break space is not converted to other space";
}
