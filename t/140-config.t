use lib 'lib';
use Test;
use Test::Output;
use File::Directory::Tree;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

# Assumes the presence in cache of files defined in 010-basic.t

#plan 7;

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant OUTPUT = 't/tmp/html';
constant CONFIG = 't/tmp/config';

my PodCache::Render $renderer;
my PodCache::Processed $pf;
my $rv;

for OUTPUT, CONFIG {
    .&rmtree;
    .&mktree
}

my $content = q:to/PODEND/;
    =begin pod
    Some text
    =end pod
    PODEND

for <sub-dir-1 sub-dir-2 sub-dir-3> -> $d {
    mktree DOC ~ "/$d";
    (DOC ~ "/$d/a-file-$_.pod6").IO.spurt($content) for 1..4
}

#--MARKER-- Test 1
lives-ok { $renderer .= new(:path(REP), :output( OUTPUT ), :config( CONFIG ) ) }, 'renderer with Output & Config defined';
$renderer.update-cache;

my %test;
#--MARKER-- Test 2
lives-ok { %test = $renderer.test-index-files(:quiet) }, 'test non-existent index files';
#--MARKER-- Test 3
is-deeply %test<errors>, ('No index.yaml files, so will generate default files' , ), 'without files generated error';

#--MARKER-- Test 4
lives-ok {  $renderer.gen-index-files }, 'gen-index-files lives';

#--MARKER-- Test 5
ok (CONFIG ~ '/index.yaml').IO ~~ :f, 'index.yaml created';
#--MARKER-- Test 6
ok (CONFIG ~ '/global-index.yaml').IO ~~ :f, 'global-index.yaml created';
#--MARKER-- Test 7
stderr-like { %test = $renderer.test-index-files }, /
    'Errors found:' \s* 'None'
    .+ 'Number in cache' .+ \d+
    .+ 'not in config file(s):' \s* 'None'
    /, 'verbose sumary as expected';
#--MARKER-- Test 8
is +%test<duplicates-in-index>, 0, 'round-trip: no duplicates';
#--MARKER-- Test 9
is +%test<not-in-cache>, 0, 'round-trip: no non-cache';
#--MARKER-- Test 10
is +%test<not-in-index>, 0, 'round-trip: index covers all cache';
#--MARKER-- Test 11
is +%test<index-and-cache>, +$renderer.files.keys, 'round-trip: all files in index';

(CONFIG ~ '/index.yaml').IO.spurt(q:to/ENDYAML/); # pseudo index
    # from template
    ---
    title: test
    content:
        -
            item:
                filename: a-pod-file
        -
            item:
                filename: a-second-pod-file
        -
            item:
                filename: code-test-pod-file_1
        -
            item:
                filename: code-test-pod-file_2
        -
            item:
                filename: comment-test-pod-file_1
        -
            item:
                filename: format-codes-test-pod-file_1
        # template but distorted
        -
            item:
                filename: sub-dir-3/a-file-2xx
        -
            item:
                filename: sub-dir-3/a-file-3xx
        -
            item:
                filename: sub-dir-3/a-file-4xx
        # duplicated
        -
            item:
                filename: code-test-pod-file_2
        -
            item:
                filename: comment-test-pod-file_1
    ENDYAML

%test = $renderer.test-index-files(:quiet);
#--MARKER-- Test 12
is +%test<duplicates-in-index>, 2, 'pseudo index expected duplicates';
#--MARKER-- Test 13
is +%test<not-in-cache>, 3, 'pseudo index expected non-cache';
#--MARKER-- Test 14
is +%test<not-in-index>, +$renderer.files.keys - 6 , 'pseudo index expected index not covering cache';
#--MARKER-- Test 15
is +%test<index-and-cache>, 6, 'pseudo index expected in index and cache';

(CONFIG ~ '/index2.yaml').IO.spurt(q:to/ENDYAML/); # pseudo index 2
    ---
    title: test
    content:
        -
            item:
                filename: format-codes-test-pod-file_2
        -
            item:
                filename: format-codes-test-pod-file_3
        -
            item:
                filename: format-codes-test-pod-file_4
        -
            item:
                filename: format-codes-test-pod-file_5
    ENDYAML

%test = $renderer.test-index-files(:quiet);
#--MARKER-- Test 16
is +%test<duplicates-in-index>, 2, 'multiple psuedo index expected duplicates';
#--MARKER-- Test 17
is +%test<not-in-cache>, 3, 'multiple psuedo index expected non-cache';
#--MARKER-- Test 18
is +%test<not-in-index>, +$renderer.files.keys - 10 , 'multiple psuedo index expected index not covering cache';
#--MARKER-- Test 19
is +%test<index-and-cache>, 10, 'multiple psuedo index expected in index and cache';

# TODO some tests for global-index.

done-testing;
