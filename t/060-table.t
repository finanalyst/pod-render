use lib 'lib';
use Test;
use Pod::To::Cached;
use PodCache::Render;

plan 4;
my $fn = 'tables-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my PodCache::Render::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Render::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::To::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my PodCache::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")));
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =table
      col1  col2

    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    \s* '<table class="pod-table">'
    \s*   '<tbody>'
    \s*     '<tr>'
    \s*       '<td>col1</td>'
    \s*       '<td>col2</td>'
    \s*     '</tr>'
    \s*   '</tbody>'
    \s* '</table>'
    /, 'simple row';

$pr = cache_test(++$fn, q:to/PODEND/);
    =table
      H1    H2
      --    --
      col1  col2

    PODEND

#--MARKER-- Test 2
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    \s*   '<thead>'
    \s*     '<tr>'
    \s*       '<th>H1</th>'
    \s*       '<th>H2</th>'
    \s*     '</tr>'
    \s*   '</thead>'
    \s*   '<tbody>'
    \s*     '<tr>'
    \s*       '<td>col1</td>'
    \s*       '<td>col2</td>'
    \s*     '</tr>'
    \s*   '</tbody>'
    \s* '</table>'
    /,'simple header and row';


$pr = cache_test(++$fn, q:to/PODEND/);
    =begin table :class<sorttable>

      H1    H2
      --    --
      col1  col2

      col1  col2

    =end table

    PODEND

#--MARKER-- Test 3
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    '<table class="pod-table sorttable">'
    \s*   '<thead>'
    \s*     '<tr>'
    \s*       '<th>H1</th>'
    \s*       '<th>H2</th>'
    \s*     '</tr>'
    \s*   '</thead>'
    \s*   '<tbody>'
    \s*     '<tr>'
    \s*       '<td>col1</td>'
    \s*       '<td>col2</td>'
    \s*     '</tr>'
    \s*     '<tr>'
    \s*       '<td>col1</td>'
    \s*       '<td>col2</td>'
    \s*     '</tr>'
    \s*   '</tbody>'
    \s* '</table>'
    /, 'table with class';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin table :caption<Test Caption>

      H1    H2
      --    --
      col1  col2

    =end table

    PODEND

#--MARKER-- Test 4
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    '<table class="pod-table">'
    \s*   '<caption>Test Caption</caption>'
    \s*   '<thead>'
    \s*     '<tr>'
    \s*       '<th>H1</th>'
    \s*       '<th>H2</th>'
    \s*     '</tr>'
    \s*   '</thead>'
    \s*   '<tbody>'
    \s*     '<tr>'
    \s*       '<td>col1</td>'
    \s*       '<td>col2</td>'
    \s*     '</tr>'
    \s*   '</tbody>'
    \s* '</table>'
    /, 'table with caption';
