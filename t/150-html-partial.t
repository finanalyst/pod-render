use v6.c;
use lib 'lib';
use Test;
use Test::Output;
use File::Directory::Tree;
use PodCache::Render;
use PodCache::Processed;

plan 13;
# Assumes the presence in cache of files defined in 140*

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant OUTPUT = 't/tmp/html';
constant CONFIG = 't/tmp/config';

for OUTPUT, CONFIG {
    .&rmtree;
    .&mktree
}

my PodCache::Render $renderer .= new(:path(REP), :output( OUTPUT ), :config( CONFIG ) );
my PodCache::Processed $pf;
my $rv;

my $fn = 'a-second-pod-file';
$pf = $renderer.processed-instance( :name($fn) );
#--MARKER-- Test 1
lives-ok { $renderer.source-wrap( $pf ) }, 'source-wrap works';
#--MARKER-- Test 2
ok (OUTPUT ~ "/$fn.html").IO ~~ :f, 'html with default filename created';
$renderer.source-wrap(:name<first>, $pf );
#--MARKER-- Test 3
ok (OUTPUT ~ '/first.html').IO ~~ :f, 'over-ride file name';
$rv = (OUTPUT ~ '/first.html').IO.slurp;
#--MARKER-- Test 4
like $rv, /
    \<\! 'doctype html' \s* '>'
    \s* '<html' .*? '>'
    \s* '<head>' .+ '</head>'
    \s* '<body' <-[>]>* '>'
    .+ '</body>'
    .* '</html>'
    / , 'html seems ok';

$renderer.generate-config-files;

(CONFIG ~ '/home-page.yaml').IO.spurt: q:to/HOMEPAGE/;
    source: myownhomepage.html
    HOMEPAGE
(CONFIG ~ '/myownhomepage.html').IO.spurt: q:to/HOMEPAGE/;
    <html>
        <head>
            <title>My own index</title>
        </head>
        <body>
            Nothing here really
        </body>
    </html>
    HOMEPAGE

#--MARKER-- Test 5
lives-ok { $renderer.create-collection }, 'writing whole collection';

#--MARKER-- Test 6
is (OUTPUT ~ '/index.html').IO.f, True, 'main index file generated';
#--MARKER-- Test 7
is (OUTPUT ~ '/global-index.html').IO.f, True, 'indexation file generated';

#--MARKER-- Test 8
is (OUTPUT ~ '/myownhomepage.html').IO.f, True, 'custom file generated';

#--MARKER-- Test 9
is +$renderer.report(:errors,:!cache,:!rendered ), 2, 'Two external links have errors';

my $mod-time = ( OUTPUT ~ '/a-second-pod-file.html').IO.modified;

( DOC ~ '/a-second-pod-file.pod6').IO.spurt(q:to/POD-CONTENT/);
    =begin pod
    =TITLE More and more

    Some more text

    =head2 This is a heading

    Some text after a heading

    This file has been altered to add a new L<link|headings-test-pod-file_1#t_2_2>

    =end pod
    POD-CONTENT
# re-instantiating detects new and tainted files
$renderer .= new(:path(REP), :output( OUTPUT ), :config( CONFIG ) );
# renews the collection
$renderer.update-collection;
#--MARKER-- Test 10
ok $mod-time < ( OUTPUT ~ '/a-second-pod-file.html').IO.modified, 'tainted source has led to new html file';
#--MARKER-- Test 11
ok +$renderer.report(:errors, :!links, :!rendered ), 'no cache errors to report';
#--MARKER-- Test 12
is +$renderer.report(:!cache,:!rendered), 1, 'a new link has been processed';
#--MARKER-- Test 13
is +$renderer.report(:!links, :!cache), +$renderer.hash-files.keys, 'all sources should be rendered';