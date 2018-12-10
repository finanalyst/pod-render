use v6.c;
use lib 'lib';
use Test;
use Test::Output;
use PodCache::Render;
use Data::Dump;

# Assumes 150* has run
# Assumes an internet link

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant OUTPUT = 't/tmp/html';
constant CONFIG = 't/tmp/config';

diag "links test - slow";
plan 3;
my $fn = 'links-pod-test_0';

my PodCache::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "/$fn.pod6").IO.spurt: $to-cache;
    my PodCache::Render $ren .= new(:path( REP ) );
    $ren.update-cache;
    $ren.processed-instance( :name($fn) );
}

my PodCache::Render $renderer .=new(:output(OUTPUT), :path(REP), :config( CONFIG ));
$renderer.process-cache;
my @responses = $renderer.links-test;
#--MARKER-- Test 1
is +@responses.grep( { m/^ 'Error'/ } ), 1, 'One of the external links has an error';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    We can L<link to an index test code|format-code-index-test-pod-file_2#t_an_item> with more text.

    =end pod
    PODEND
$renderer .= new(:path(REP), :output( OUTPUT ), :config( CONFIG ) );
# renews the collection
$renderer.verbose=True;
$renderer.update-collection;
say "pfiles: ",$renderer.pfiles.keys;
@responses = $renderer.links-test;
say @responses.join("\n");
#--MARKER-- Test 2
is +@responses.grep( { m/^ 'OK'/ } ), 3, 'Should now have three good links';

#--MARKER-- Test 3
is +@responses.grep( { m/^ 'OK: local'/ } ), 1, 'local link detected';
