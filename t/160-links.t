use v6.c;
use lib 'lib';
use Test;
use Test::Output;
use PodCache::Render;

# Assumes the presence in cache of files defined in 140-basic.t
# Assumes the presence of html files generated in 150-html-partial.t

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant OUTPUT = 't/tmp/html';
constant CONFIG = 't/tmp/config';

diag "links test - slow";

my PodCache::Render $renderer .=new(:output(OUTPUT), :path(REP), :config( CONFIG ));

my @responses = $renderer.links-test;

is +@responses, 1, 'One of the external links has an error';

done-testing;
