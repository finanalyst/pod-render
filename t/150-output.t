use lib 'lib';
use Test;
use Test::Output;
use File::Directory::Tree;
use Pod::To::Cached;
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
#--MARKER-- Test 2
lives-ok { $rv = $renderer.body-wrap($pf) }, 'body-wrap method lives';
#--MARKER-- Test 3
like $rv, / '<!-- Start of ' .+ $fn .+ '-->' /, 'body is wrapped';

#--MARKER-- Test 4
lives-ok { $renderer.file-wrap( $pf ) }, 'file-wrap works';
#--MARKER-- Test 5
ok (OUTPUT ~ "/$fn.html").IO ~~ :f, 'html with default filename created';
$renderer.file-wrap(:name<first>, $pf );
#--MARKER-- Test 6
ok (OUTPUT ~ '/first.html').IO ~~ :f, 'over-ride file name';
$rv = (OUTPUT ~ '/first.html').IO.slurp;
#--MARKER-- Test 7
like $rv, /
    \<\! 'doctype html' \s* '>'
    \s* '<html' .*? '>'
    \s* '<head>' .+ '</head>'
    \s* '<body' <-[>]>* '>'
    .+ '</body>'
    .* '</html>'
    / , 'html seems ok';


done-testing
