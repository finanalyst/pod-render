=begin pod

=begin code
perl6 --doc=HTML2 input.pm6 > output.html
=end code

Trying to process this file itself results in the following:
$ perl6 --doc=Markdown lib/Pod/To/Markdown.pm6
=begin code
===SORRY!===
 P6M Merging GLOBAL symbols failed: duplicate definition of symbol Markdown
=end code
Here is a hack to generate README.md from this Pod:
=begin code
perl6 lib/Pod/To/Markdown.pm6 > README.md
=end code

=end pod

sub MAIN() {
    print ::('Pod::To::HTML2').render($=pod);
}

unit class Pod::To::HTML2;
use PodCache::Processed;

sub render( $pod-tree ) is export {
    my PodCache::Processed $pp .= new(:$pod-tree);
    print $pp.rendition('file-wrap')
}
