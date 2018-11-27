use v6.c;
use lib 'lib';
use Test;
use Test::Output;
use File::Directory::Tree;
use PodCache::Render;
use PodCache::Processed;

# Assumes the presence in cache of files defined in 140-basic.t

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
lives-ok { $rv = $renderer.body-wrap($pf) }, 'body-wrap method lives';
#--MARKER-- Test 2
like $rv, / '<!-- Start of ' .+ $fn .+ '-->' /, 'body is wrapped';

#--MARKER-- Test 3
lives-ok { $renderer.file-wrap( $pf ) }, 'file-wrap works';
#--MARKER-- Test 4
ok (OUTPUT ~ "/$fn.html").IO ~~ :f, 'html with default filename created';
$renderer.file-wrap(:name<first>, $pf );
#--MARKER-- Test 5
ok (OUTPUT ~ '/first.html').IO ~~ :f, 'over-ride file name';
$rv = (OUTPUT ~ '/first.html').IO.slurp;
#--MARKER-- Test 6
like $rv, /
    \<\! 'doctype html' \s* '>'
    \s* '<html' .*? '>'
    \s* '<head>' .+ '</head>'
    \s* '<body' <-[>]>* '>'
    .+ '</body>'
    .* '</html>'
    / , 'html seems ok';

$renderer.gen-index-files;
#--MARKER-- Test 7
lives-ok {$renderer.write-indices }, 'index files to html';
#--MARKER-- Test 8
is (OUTPUT ~ '/index.html').IO.f, True, 'main index file generated';
#--MARKER-- Test 9
is (OUTPUT ~ '/global-index.html').IO.f, True, 'indexation file generated';

#--MARKER-- Test 10
lives-ok { $renderer.create-collection }, 'writing whole collection';

my $mod-time = ( OUTPUT ~ '/a-second-pod-file.html').IO.modified;

( DOC ~ '/a-second-pod-file.pod6').IO.spurt(q:to/POD-CONTENT/);
    =begin pod
    =TITLE More and more

    Some more text

    =head2 This is a heading

    Some text after a heading
    
    This file has been altered

    =end pod
    POD-CONTENT
# re-instantiating detects new and tainted files
$renderer .= new(:path(REP), :output( OUTPUT ), :config( CONFIG ) );
# renews the collection
$renderer.update-collection; 
#--MARKER-- Test 11
ok $mod-time < ( OUTPUT ~ '/a-second-pod-file.html').IO.modified, 'tainted source has led to new html file';

done-testing
