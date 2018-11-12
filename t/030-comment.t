use lib 'lib';
use Test;
use Pod::Cached;
use Pod::Render;

plan 1;
my $fn = 'comment-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::Cached $cache .= new(:path(REP)); # dies if no cache
my Pod::Render::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> Pod::Render::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my Pod::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")));
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
