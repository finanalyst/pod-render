use lib 'lib';
use Test;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

plan 5;
my $fn = 'lists-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my PodCache::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::To::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my PodCache::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")));
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

    We want to know the first through the door.
    =end pod
    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    '<section name="pod">'
    \s*'<p>The seven suspects are:</p>'
    \s* '<ul>'
    \s* '<li>' \s* '<p>Happy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Dopey</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Sleepy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Bashful</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Sneezy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Grumpy</p>' \s* '</li>'
    \s* '<li>' \s* '<p>Keyser Soze</p>' \s* '</li>'
    \s* '</ul>'
    \s* '<p>We want to know the first through the door.</p>'
    \s* '</section>'
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

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    =comment CORRECT...
    =begin item1
    The choices are:
    =end item1
    =item2 Liberty
    =item2 Death
    =item2 Beer
    =item4 non-alcoholic
    =end pod
    PODEND

#--MARKER-- Test 4
like $pr.pod-body.subst(/\s+/,' ',:g).trim,
    /
    '<ul>'
    \s* '<li>' \s* '<p>The choices are:</p>' \s* '</li>'
    \s* '<ul>'
    \s*     '<li>' \s* '<p>Liberty</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Death</p>' \s* '</li>'
    \s*     '<li>' \s* '<p>Beer</p>' \s* '</li>'
    \s*    '<ul>'
    \s*         '<ul>'
    \s*             '<li>' \s* '<p>non-alcoholic</p>' \s* ' </li>'
    \s*         '</ul>'
    \s*     '</ul>'
    \s* '</ul>'
    \s* '</ul>'
    /, 'hierarchical unordered list';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    Let's consider two common proverbs:

    =begin item
    I<The rain in Spain falls mainly on the plain.>

    This is a common myth and an unconscionable slur on the Spanish
    people, the majority of whom are extremely attractive.
    =end item

    =begin item
    I<The early bird gets the worm.>

    In deciding whether to become an early riser, it is worth
    considering whether you would actually enjoy annelids
    for breakfast.
    =end item

    As you can see, folk wisdom is often of dubious value.
    =end pod
    PODEND

#--MARKER-- Test 5
like $pr.pod-body.subst(/\s+/,' ',:g).trim,
    /
    '<p>Let\'s consider two common proverbs:</p>'
    \s* '<ul>'
    \s*     '<li>'
    \s*         '<p>' \s* '<em>The rain in Spain falls mainly on the plain.</em>' \s* '</p>'
    \s*         '<p>This is a common myth and an unconscionable slur on the Spanish people, the majority of whom are extremely attractive.</p>'
    \s*     '</li>'
    \s*     '<li>'
    \s*         '<p>' \s* '<em>The early bird gets the worm.</em>' \s* '</p>'
    \s*         '<p>In deciding whether to become an early riser, it is worth considering whether you would actually enjoy annelids for breakfast.</p>'
    \s*     '</li>'
    \s* '</ul>'
    \s* '<p>As you can see, folk wisdom is often of dubious value.</p>'
    /, 'List with embedded paragraphs';
