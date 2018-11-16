use lib 'lib';
use Test;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

plan 2;
my $fn = 'meta-data-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my PodCache::Processed $pr;
my Str $rv;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::To::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my PodCache::Render $pr .= new(:path( REP ) );
    $pr.processed-instance( :name($fn) );
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    There is no meta data here

    =end pod
    PODEND

is $pr.render-meta, '', 'No meta data is rendered';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    This text has no footnotes or indexed item.
    =AUTHOR An author is named

    =SUMMARY This page is about Perl 6
    =end pod
    PODEND

$rv = $pr.render-meta.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 1
like $rv, /
    \s* '<meta name="author" value="An author' .+ '"' .+ '/>'
    .+ '<meta name="summary" value="This page' .+ '/>'
    /, 'meta is rendered';
