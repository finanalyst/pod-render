use lib 'lib';
use Test;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

plan 22;
diag "format codes";
my $fn = 'format-codes-test-pod-file_0';

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my PodCache::Processed $pr;
my Str $rv;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "/$fn.pod6").IO.spurt: $to-cache;
    my PodCache::Render $ren .= new(:path( REP ) );
    $ren.update-cache;
    $ren.processed-instance( :name($fn) );
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    This text has no footnotes or indexed item.

    =end pod
    PODEND

#--MARKER-- Test 1
is $pr.render-footnotes, '', 'No footnotes are rendered';
#--MARKER-- Test 2
is $pr.render-index, '', 'No index is rendered';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to say N<A footnote> in between words.

    This isn't a comment and I want to add a footnoteN<next to a word>.

    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 3
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to say'
    \s+ '<sup><a name="#fnret' .+ '" href="#fn' .+ '">[' \d+ ']</a></sup>'
    \s+ 'in between'
    .+ 'footnote<sup>'
    /, 'footnote references in text with and without spaces';

$rv = $pr.render-footnotes.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 4
like $rv, /
    \s* '<div class="footnotes">'
    \s* '<ol>'
    \s* '<li id="#fn' .+ '">A footnote<a class="footnote" href="#fnret' .+ '">Back</a></li>'
    \s* '<li' .+ '>next to a word<a'
    .+
    '</ol>'
    \s* '</div>'
    /, 'footnotes rendered later';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    When indexing X<an item> the X<X format> is used.

    It is possible to index X<an item> in repeated places.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 5
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'When indexing '
    \s* '<span id="#t' .+ '" class="indexed">an item</span>'
    \s* 'the'
    \s* '<span id="#t' .+ '" class="indexed">X format</span> is used.'
    .+ 'to index'
    \s* '<span id="#t' .+ '" class="indexed">an item</span>'
    \s* 'in repeated places.'
    /, 'X format in text';

$rv = $pr.render-index.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 6
like $rv, /
    '<div id="index">'
    \s* '<dl class="index">'
    \s*     '<dt>X format</dt>'
    \s*         '<dd><a href="#t' .+ '">' .+ '</a></dd>'
    \s*     '<dt>an item</dt>'
    \s*         '<dd><a href="#t' .+ '">' .+ '</a></dd>'
    \s*         '<dd><a href="#t' .+ '">' .+ '</a></dd>'
    \s* '</dl>'
    \s* '</div>'
    /, 'index rendered later';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to B<say> in between words.

    This isn't a comment and I want to add a formatB<next to a word>in the middle.

    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 7
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<strong>say</strong>'
    \s+ 'in between words.'
    /, 'bold when separated with a space';
#--MARKER-- Test 8
like $rv, /
    'I want to add a format<strong>next to a word</strong>' \s* 'in the middle.'
    /, 'bold without spaces';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to I<say> in between words.

    This isn't a comment and I want to add a formatI<next to a word>in the middle.

    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 9
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<em>say</em>'
    \s+ 'in between words.'
    /, 'Important when separated with a space';
#--MARKER-- Test 10
like $rv, /
    'I want to add a format<em>next to a word</em>' \s* 'in the middle.'
    /, 'Important without spaces';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to U<say> in between words.

    This isn't a comment and I want to add a formatU<next to a word>in the middle.

    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 11
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<u>say</u>'
    \s+ 'in between words.'
    /, 'Unusual when separated with a space';
#--MARKER-- Test 12
like $rv, /
    'I want to add a format<u>next to a word</u>'
    \s* 'in the middle.'
    /, 'Unusual without spaces';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to B<I<say> embedded> in between words.

    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 13
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<strong><em>say</em> embedded</strong>'
    \s+ 'in between words.'
    /, 'Embedded codes when separated with a space';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to C<say> in between words.
    =end pod
    PODEND
$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 14
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<code>say</code>'
    \s+ 'in between words.'
    /, 'C format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to K<say> in between words.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 15
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<kbd>say</kbd>'
    \s+ 'in between words.'
    /, 'K format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to R<say> in between words.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 16
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<var>say</var>'
    \s+ 'in between words.'
    /, 'R format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to T<say> in between words.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 17
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ '<samp>say</samp>'
    \s+ 'in between words.'
    /, 'T format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    Perl 6 makes considerable use of the E<171> and E<187> characters.
    Perl 6 makes considerable use of the E<laquo> and E<raquo> characters.
    Perl 6 makes considerable use of the E<0b10101011> and E<0b10111011> characters.
    Perl 6 makes considerable use of the E<0o253> and E<0o273> characters.
    Perl 6 makes considerable use of the E<0d171> and E<0d187> characters.
    Perl 6 makes considerable use of the E<0xAB> and E<0xBB> characters.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 18
like $rv, /
    '<section name="pod">'
    \s* [ .+? 'use of the ' [ '&laquo;' | '&#171;' ]  ' and ' [ '&raquo;' | '&#187;' ] ' characters' ] **6
    /, 'Unicode E format 6 times same';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Perl 6 is awesomeZ<Of course it is!> without doubt.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 19
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Perl 6 is awesome without doubt.'
    /, 'Z format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    We can L<Link to a place|https://docs.perl6.org> with no problem.

    This L<link should fail|https://xxxxxioioioi.com> with a bad response code.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 20
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'We can'
    \s* '<a href="https://docs.perl6.org">Link to a place</a>'
    \s* 'with no problem.'
    /, 'L format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing to V< B<say> C<in>> between words.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 21
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing to'
    \s+ 'B&lt;say&gt;'
    \s+ 'C&lt;in&gt; between words.'
    /, 'V format';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    Some thing F<a-filename.pod> between words.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 22
like $rv, /
    '<section name="pod">'
    \s* '<p>'
    \s* 'Some thing'
    \s+ 'F&lt;a-filename.pod&gt;'
    \s+ 'between words.'
    /, 'Unknown format';
