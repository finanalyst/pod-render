use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::Cached;
use Pod::Render;
plan 1;

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';
my $fn = 'basic-test-pod-file_0';

my Pod::Cached $cache .= new(:path(REP)); # dies if no cache

mktree 't/tmp/templates/html';

't/tmp/templates/html/para.mustache'.IO.spurt: '<p class="special {{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</p>';

my Pod::Render $renderer .= new(:path<t/tmp/ref>, :templates<t/tmp/templates>);
my Pod::Render::Processed $pf = $renderer.processed-instance(:name<a-second-pod-file>, :pod-tree( $renderer.pod('a-second-pod-file') ));

#--MARKER-- Test 1
like $pf.pod-body, /
    '<p class="special' \s* '">Some more text'
    /, 'Para template over-ridden';
