use lib 'lib';
use Test;
use PodCache::Render;
use PodCache::Processed;

plan 1;
my $fn = 'comment-test-pod-file_0';
diag 'Comments';

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';

my PodCache::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "/$fn.pod6").IO.spurt: $to-cache;
    my PodCache::Render $ren .= new(:path( REP ) );
    $ren.update-cache;
    $ren.processed-instance( :name($fn) );
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    =for comment
    foo foo not rendered
    bla bla    bla

    This isn't a comment
    =end pod
    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    ^
    '<section name="pod">'
    \s* '<p>This isn\'t a comment</p>'
    \s* '</section>'
    $
    /, 'commment is eliminated';
