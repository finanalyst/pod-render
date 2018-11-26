use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;
plan 4;

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant TEMPL = 't/tmp/templates';

rmtree TEMPL;
mktree TEMPL ~ '/html';

my $fn = 'basic-test-pod-file_0';

my Pod::To::Cached $cache .= new(:path(REP), :templates(TEMPL)); # dies if no cache

(TEMPL ~ "/html/para.mustache").IO.spurt: '<p class="special {{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</p>';

my PodCache::Render $renderer .= new(:path(REP), :templates( TEMPL ));
my PodCache::Processed $pf = $renderer.processed-instance(:name<a-second-pod-file> );

#--MARKER-- Test 1
like $pf.pod-body, /
    '<p class="special' \s* '">Some more text'
    /, 'Para template over-ridden';

#--MARKER-- Test 2
like $renderer.templates-changed, / 'para' .+ 'from' .* {TEMPL}  '/html' /, 'reports over-ridden template';

#--MARKER-- Test 3
lives-ok {$renderer.gen-templates}, 'gen-templates lives';

#--MARKER-- Test 4
is +(TEMPL ~ '/html').IO.dir, +$renderer.engine.tmpl, 'correct number of template files generated';

rmtree TEMPL;
