use lib 'lib';
use Test;
use Pod::To::Cached;
use PodCache::Render;
use PodCache::Processed;

plan 2;
my $fn = 'headings-test-pod-file_0';

constant REP = 't/tmp/ref';
constant DOC = 't/tmp/doc/';

my Pod::To::Cached $cache .= new(:path(REP)); # dies if no cache
my PodCache::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "$fn.pod6").IO.spurt: $to-cache;
    my Pod::To::Cached $cache .=new(:path( REP ));
    $cache.update-cache;
    my PodCache::Render $pr .= new(:path( REP ) );
    $pr.processed-instance(:name("$fn"), :pod-tree($pr.pod("$fn")));
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    =head1 Heading 1

    =head2 Heading 1.1

    =head2 Heading 1.2

    =head1 Heading 2

    =head2 Heading 2.1

    =head2 Heading 2.2

    =head2 <a href="/routine/message#class_Exception">(Exception) method message</a>

    =head3 Heading 2.2.1

    =head3 X<Heading> 2.2.2

    =head1 Heading C<3>

    =end pod
    PODEND

my $html = $pr.pod-body.subst(/\s+/,' ',:g).trim;

#put $html;
#--MARKER-- Test 1
like $html, /'h2 id="#t_2_2"' .+ '"u">Heading 2.2'/, 'Heading 2.2 has expected id';
#--MARKER-- Test 2
like $html, /'class="indexed-header">Heading' .+ '2.2.2</a>' / , 'Heading 2.2.2 is indexed';
