use lib 'lib';
use Test;
use Pod::Cached;
use Pod::Render;

plan :skip-all<Lists being refactored>;
plan 3;
my $fn = 'lists-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::Cached $cache .= new(:path(REP)); # dies if no cache
my Pod::Render::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> Pod::Render::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my Pod::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")),:debug(2));
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    The seven suspects are:

    =item  Happy
    =item  Dopey
    =item  Sleepy
    =item  Bashful
    =item  Sneezy
    =item  Grumpy
    =item  Keyser Soze
    =end pod
    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    '<p>The seven suspects are:</p>'
    \s* '<ul>'
    \s* '<li>' \s* '<p>Happy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Dopey</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Sleepy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Bashful</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Sneezy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Grumpy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Keyser Soze</p>' \s* '</li>'
    \s* '</ul>'
    /, 'simple list ok';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    =item1  Animal
    =item2     Vertebrate
    =item2     Invertebrate

    =item1  Phase
    =item2     Solid
    =item2     Liquid
    =item2     Gas
    =item2     Chocolate
    =end pod

    PODEND

#--MARKER-- Test 2
like $pr.pod-body.subst(/\s+/,' ',:g).trim,
    /
    '<ul>'
    \s* '<li>' \s* '<p>Animal</p>' \s* '</li>'
    \s* '<ul>'
    \s*     '<li>' \s* '<p>Vertebrate</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Invertebrate</p>' \s* '</li>'
    \s* '</ul>'
    \s* '<li>' \s* '<p>Phase</p>' \s* '</li>'
    \s* '<ul>'
    \s*     '<li>' \s* '<p>Solid</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Liquid</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Gas</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Chocolate</p>' \s* '</li>'
    \s* '</ul>'
    \s* '</ul>'
    /, 'multi-layer list';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    =comment CORRECT...
    =begin item1
    The choices are:
    =end item1
    =item2 Liberty
    =item2 Death
    =item2 Beer
    =end pod
    PODEND

#--MARKER-- Test 3
like $pr.pod-body.subst(/\s+/,' ',:g).trim,
    /
    '<ul>'
    \s* '<li>' \s* '<p>The choices are:</p>' \s* '</li>'
    \s* '<ul>'
    \s*     '<li>' \s* '<p>Liberty</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Death</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Beer</p>' \s* '</li>'
    \s* '</ul>'
    \s* '</ul>'
    /, 'hierarchical unordered list';
