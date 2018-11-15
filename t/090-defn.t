#!perl6

use Test;

# do NOT move this below `Pod::To::HTML` line, the module exports a fake Pod::Defn
constant no-pod-defn = ::('Pod::Defn') ~~ Failure;

plan :skip-all<Compiler does not support Pod::Defn> if no-pod-defn;
plan 1;

use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

my $fn = 'defn-test-pod-file_0';

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

    =defn  MAD
    Affected with a high degree of intellectual independence.

    =defn  MEEKNESS
    Uncommon patience in planning a revenge that is worth while.

    =defn MORAL
    Conforming to a local and mutable standard of right.
    Having the quality of general expediency.

    =end pod

    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    '<dl>'
    \s* '<dt>MAD</dt>'
    \s* '<dd><p>Affected with a high degree of intellectual independence.</p>'
    \s* '</dd>'
    \s* '<dt>MEEKNESS</dt>'
    \s* '<dd><p>Uncommon patience in planning a revenge that is worth while.</p>'
    \s* '</dd>'
    \s* '<dt>MORAL</dt>'
    \s* '<dd><p>Conforming to a local and mutable standard of right. Having the quality of general expediency.</p>'
    \s* '</dd>'
    \s* '</dl>'
    /  , 'generated html for =defn';
