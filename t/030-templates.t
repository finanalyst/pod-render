use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;
plan 2;

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';
my $fn = 'basic-test-pod-file_0';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache

mktree 't/tmp/templates/html';

't/tmp/templates/html/para.mustache'.IO.spurt: '<p class="special {{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</p>';

my PodCache::Render $renderer .= new(:path<t/tmp/ref>, :templates<t/tmp/templates>);
my PodCache::Processed $pf = $renderer.processed-instance(:name<a-second-pod-file>, :pod-tree( $renderer.pod('a-second-pod-file') ));

#--MARKER-- Test 1
like $pf.pod-body, /
    '<p class="special' \s* '">Some more text'
    /, 'Para template over-ridden';

#--MARKER-- Test 2
like $renderer.tmpl-report, / 'para' .+ 'from' .* 't/tmp/templates/html' /, 'reports over-ridden template';
