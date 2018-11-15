use Template::Mustache;
unit class PodCache::Engine;
has $!default;
has %!tmpl = (
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

has Str $!templates;
has Str $!rendering;
# list of the templates needed (not defined as short templates below)
has @!template-list = <
    block-code comment footnotes format-b format-c format-i format-k format-l format-n
    format-r format-t format-u format-x heading index item list main notimplemented
    output para section subtitle table title toc
    >;
has @!over-ridden = ();

submethod BUILD( :$!default, :$!templates, :$!rendering,  :$!verbose = False, :$!debug = False ) {}

method verify-templates {
    die "$!templates/$!rendering must be a directory" unless "$!templates/$!rendering".IO ~~ :d;
    my @missing = ();
    for @!template-list -> $tm {
        if "$!templates/$!rendering/$tm.mustache".IO ~~ :f {
            %!tmpl{$tm} = "$!templates/$!rendering/$tm.mustache".IO.slurp;
            @!over-ridden.push: "$tm"
        }
        else {
            %!tmpl{$tm} = "$!default/$tm.mustache".IO.slurp;
            @missing.push: "$tm"
        }
    }
    note "The following templates do not exist under $!templates/$!rendering"
        ~ @missing.join("\n\t")
        ~ "\nThe default templates in ｢$!default｣ are used instead"
        if +@missing and $!verbose;
    note 'Templates verified' if $!verbose;
}

method tmpl-report( --> Str) {
    [~] gather for @!template-list -> $tm {
        take "｢$tm\.mustache｣ from " ~ ((($tm ~~ any @!over-ridden) ?? "$!templates/$!rendering" !! $!default) ~ "\n")
    }
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
    $!tmpl-engine.render( %!tmpl{$key}, %params, :literal );
}
