use v6.c;
use Template::Mustache;

constant TEMPLATES = 'resources/templates';
constant RENDERING = 'html';

unit class PodCache::Engine;

has %.tmpl = (
    #| templates defined here without explicit html
    #| markup specific templates defined in mustache files.
    #| simple ones can be overidden by mustache files
    :escaped<{{ contents }}>,
    :raw<{{{ contents }}}>,
    :format-c-index('C<{{ contents }}>'),
    :zero(' '),
    ); # templates as strings
has $!tmpl-engine = Template::Mustache.new;
has $!verbose;
has $!debug; # debug for rendition method

has Str $.rendering;
has Str $.t-dir;

# list of the templates needed (not defined as short templates below)
has @!template-list = <
    block-code body-wrap comment file-wrap footnotes
    format-b format-c format-i format-k format-l
    format-n format-r format-t format-u format-x
    global-indexation-defn-list global-indexation-file global-indexation-heading heading index
    indexation-entry indexation-file indexation-heading item list
    meta notimplemented output para section
    subtitle table title toc
    >;
has @.over-ridden = ();

submethod BUILD( :$templates = Str, :$rendering = Str,  :$!verbose = False, :$!debug = False ) {
    $!rendering = $rendering // RENDERING;
    $!t-dir = ( $templates // TEMPLATES ) ~ "/$!rendering";
    exit note "$!t-dir must be a directory" if ($templates or $rendering) and $!t-dir.IO ~~ :!d;

}

method TWEAK {
    my @missing = ();
    for @!template-list -> $tm {
        if "$!t-dir/$tm.mustache".IO ~~ :f {
            %!tmpl{$tm} = "$!t-dir/$tm.mustache".IO.slurp;
            @!over-ridden.push: "$tm"
        }
        else {
            %!tmpl{$tm} = (TEMPLATES ~ '/' ~ RENDERING ~ '/' ~ "/$tm.mustache").IO.slurp;
            @missing.push: "$tm"
        }
    }
    note "The following templates do not exist under $!t-dir"
        ~ @missing.join("\n\t")
        ~ "\nThe default templates in ｢" ~ TEMPLATES ~ '/' ~ RENDERING ~'｣ are used instead'
        if +@missing and $!verbose;
    note 'Templates verified' if $!verbose;
}

method rendition(Str $key, %params --> Str) {
    if $!debug {
        say "key is $key";
        say 'params are: ';
        say %params.perl;
        say 'end params';
        say "\%tmpl\{$key} is: ";
        say %!tmpl{$key}.perl;
        say "end template";
    }
    die "Cannot process non-existent template ｢$key｣" unless %!tmpl{$key}:exists;
    $!tmpl-engine.render( %!tmpl{$key}, %params, :literal );
}

method gen-templates {
    die "｢$!t-dir｣ must be a writable directory for Templates." unless $!t-dir.IO ~~ :d;
    for %!tmpl.kv -> $nm, $str { "$!t-dir/$nm.mustache".IO.spurt: $str }
}
