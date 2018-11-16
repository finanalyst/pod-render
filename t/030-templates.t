use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;
plan 4;

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';
my $fn = 'basic-test-pod-file_0';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my $over-ride = 't/tmp/templates';
mktree "$over-ride/html";

"$over-ride/html/para.mustache".IO.spurt: '<p class="special {{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</p>';

my PodCache::Render $renderer .= new(:path(REP), :templates($over-ride));
my PodCache::Processed $pf = $renderer.processed-instance(:name<a-second-pod-file> );

#--MARKER-- Test 1
like $pf.pod-body, /
    '<p class="special' \s* '">Some more text'
    /, 'Para template over-ridden';

#--MARKER-- Test 2
like $renderer.template-test, / 'para' .+ 'from' .* $over-ride '/html' /, 'reports over-ridden template';

my $new = 't/tmp/new-templates';
mktree $new;
lives-ok {$renderer.gen-templates($new)}, 'gen-templates lives';
is +$new.IO.dir, +$renderer.engine.tmpl, 'correct number of template files generated';

rmtree $new;
rmtree $over-ride;
