use lib 'lib';
use Test;
use File::Directory::Tree;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

# Assumes the presence in cache of files defined in 010-basic.t

#plan 7;

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';
constant OUTPUT = 't/tmp/html';

mktree OUTPUT;

my PodCache::Render $renderer;
my PodCache::Processed $pf;
my $rv;

lives-ok { $renderer .= new(:path(REP), :output( OUTPUT ) ) }, 'renderer with output defined';

my $fn = 'a-second-pod-file';
$pf = $renderer.processed-instance( :name($fn) );
lives-ok { $rv = $renderer.body-wrap($pf) }, 'body-wrap method lives';
like $rv, / '<!-- Start of ' .+ $fn .+ '-->' /, 'body is wrapped';

lives-ok { $renderer.file-wrap( $pf ) }, 'file-wrap works';
ok (OUTPUT ~ "/$fn.html").IO ~~ :f, 'html with default filename created';
$renderer.file-wrap(:name<first>, $pf );
ok (OUTPUT ~ '/first.html').IO ~~ :f, 'over-ride file name';
$rv = (OUTPUT ~ '/first.html').IO.slurp;
like $rv, /
    \<\! 'doctype html' \s* '>'
    \s* '<html' .*? '>'
    \s* '<head>' .+ '</head>'
    \s* '<body' <-[>]>* '>'
    .+ '</body>'
    .* '</html>'
    / , 'html seems ok';

done-testing;
