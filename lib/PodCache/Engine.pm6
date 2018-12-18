use v6.c;
use Template::Mustache;

constant TEMPLATES = "templates";
constant RENDERING = 'html';

unit class PodCache::Engine;

has %.tmpl = tmpl-data; # templates as strings defined at bottom. All can be over-ridden with mustache files
has $!tmpl-engine = Template::Mustache.new;
has $!verbose;
has $!debug; # debug for rendition method

has Str $.rendering;
has Str $.t-dir;
has Bool $!tmpls-given;

# list of the templates needed (not defined as short templates below)
has @!template-list = %!tmpl.keys;
has @.over-ridden = ();

submethod BUILD( :$templates = Str, :$rendering = Str,  :$!verbose = False, :$!debug = False ) {
    $!tmpls-given = so ($templates or $rendering );
    $!rendering = $rendering // RENDERING;
    $!t-dir = ( $templates // TEMPLATES ) ~ "/$!rendering";
    exit note "$!t-dir must be a directory" if $!tmpls-given and $!t-dir.IO ~~ :!d
}

method TWEAK {
    return unless $!tmpls-given;
    my SetHash $missing .= new: %!tmpl.keys;
    for $!t-dir.IO.dir( :test(/ '.mustache' $/ ) ) -> $tm {
        my $tm-name = $tm.basename.substr(0,*-9);
        if $missing{ $tm-name }-- { # is true if tm is removed from missing, which means it is a valid key
            %!tmpl{ $tm-name } = $tm.slurp;
            @!over-ridden.push: $tm-name
        }
    }
    note "The following templates do not exist under $!t-dir\n\t"
        ~ $missing.keys.join("\n\t")
        if $!verbose;
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

sub tmpl-data {
    %(
    :escaped<{{ contents }}>,
    :raw<{{{ contents }}}>,
    :format-c-index('C<{{{ contents }}}>'),
    :zero(' '),

    'block-code' => '<pre class="pod-block-code{{# addClass }} {{ addClass }}{{/ addClass}}">{{# contents }}{{{ contents }}}{{/ contents }}</pre>
    ',

    'comment' => '<!-- {{{ contents }}} -->',

    'defn' => '<dl><dt>{{ term }}</dt><dd>{{{ contents }}}</dd></dl>
    ',

    'source-wrap' => '<!doctype html>
    <html lang="en">
        <head>
            <title>{{ title }}</title>
            <meta charset="UTF-8" />
            <link rel="stylesheet" type="text/css" href="assets/pod.css" media="screen" title="default" />
            {{# metadata }}{{{ metadata }}}{{/ metadata }}
        </head>
        <body class="pod">
            {{# toc }}{{{ toc }}}{{/ toc }}
            {{# index }}{{{ index }}}{{/ index }}
            <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                {{{ body }}}
            </div>
            {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}
            {{# path }}<footer>Rendered from {{ path }}</footer>{{/ path }}
        </body>
    </html>
    ',

    'footnotes' => '<div class="footnotes">
        <ol>{{# notes }}
                <li id="{{ fnTarget }}">{{{ text }}}<a class="footnote" href="#{{ retTarget }}">Back</a></li>
                {{/ notes }}
        </ol>
    </div>
    ',

    'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>',

    'format-c' => '<code{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</code>
    ',

    'format-i' => '<em{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</em>',

    'format-k' => '<kbd{{# addClass }}class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</kbd>
    ',

    'format-l' => '<a href="{{ target }}"{{# addClass }} class="{{ addClass }}"{{/ addClass}}>{{{ contents }}}</a>
    ',

    'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
    ',

    'format-p' => '<div{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{^ html }}<pre>{{/ html }}{{{ contents }}}{{^ html }}</pre>{{/ html }}</div>',

    'format-r' => '<var{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</var>',

    'format-t' => '<samp{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</samp>',

    'format-u' => '<u{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</u>',

    'format-x' => '{{^ header }}<a name="{{ target }}"></a>{{/ header }}{{# text }}<span class="index-entry{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ text }}}</span>{{/ text }} ',

    'global-indexation-defn-list' => '<dl class="global-indexation">
        {{# list }}
            <dt>{{ text }}</dt> {{# refs }}<dd><a href="{{ source }}#{{ target }}">{{{ location }}} : {{{ place }}}</a></dd>{{/ refs }}
        {{/ list }}
    </dl>
    ',

    'global-indexation-file' => '<!doctype html>
    <html lang="en">
        <head>
            <title>{{ title }}</title>
            <meta charset="UTF-8" />
            <link rel="stylesheet" type="text/css" href="assets/pod.css" media="screen" title="default" />
        </head>
        <body class="pod">
            <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                {{{ body }}}
            </div>
            {{# path }}<footer>Rendered from {{ path }}</footer>{{/ path }}
        </body>
    </html>
    ',

    'global-indexation-heading' => '<h{{ level }} class="global-indexation-heading">{{ text }}</h{{ level }}>
    ',

    'heading' => '<h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ text }}}</a></h{{# level }}{{ level }}{{/ level }}>
    ',

    'index' => '<div id="index"><h2 class="source-index">Index</h2>
        <dl class="index">
            {{# index }}
                <dt>{{{ text }}}</dt> {{# refs }}<dd><a href="#{{ target }}">{{{ place }}}</a></dd>{{/ refs }}
            {{/ index }}
        </dl>
    </div>
    ',

    'indexation-entry' => '<div class="indexation-entry">
        <a href="{{ link }}">{{ title }}</a>
        {{# subtitle }}{{ subtitle }}{{/ subtitle }}
        {{# toc }}<table class="indexation-entry-toc">
            <tr class="entry-toc-level-{{ level }}">
                <td class="entry-toc-text"><a href="{{ link }}#{{ target }}">{{{ text }}}</a></td>
            </tr>
        </table>
        {{/ toc }}
    </div>
    ',

    'indexation-file' => '<!doctype html>
    <html lang="en">
        <head>
            <title>{{ title }}</title>
            <meta charset="UTF-8" />
            <link rel="stylesheet" type="text/css" href="assets/pod.css" media="screen" title="default" />
        </head>
        <body class="pod">
            <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                {{{ body }}}
            </div>
            {{# path }}<footer>Rendered from {{ path }}</footer>{{/ path }}
        </body>
    </html>
    ',

    'indexation-heading' => '<h{{ level }} class="indexation-heading">{{ text }}</h{{ level }}>
    {{# subtitle }}<p>{{ subtitle }}</p>{{/ subtitle }}
    ',

    'item' => '<li{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</li>
    ',

    'list' => '<ul>
        {{# items }}{{{ . }}}{{/ items}}
    </ul>
    ',

    'meta' => '{{# meta }}
    <meta name="{{ name }}" value="{{ value }}" />
    {{/ meta }}
    ',

    'named' => '<section name="{{ name }}">
        <h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ name }}}</a></h{{# level }}{{ level }}{{/ level }}>
        {{{ contents }}}
        </section>
    ',

    'notimplemented' => '<span class="pod-block-notimplemented">{{{ contents }}}</span>',

    'output' => '<pre class="pod-output">{{{ contents }}}</pre>',

    'para' => '<p{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</p>',

    'section' => '<section name="{{ name }}">{{{ contents }}}
    </section>',

    'subtitle' => '<p class="subtitle{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</p>',

    'table' => '<table class="pod-table{{# addClass }} {{ addClass }}{{/ addClass }}">
        {{# caption }}<caption>{{{ caption }}}</caption>{{/ caption }}
        {{# headers }}<thead>
            <tr>{{# cells }}<th>{{{ . }}}</th>{{/ cells }}</tr>
        </thead>{{/ headers }}
        <tbody>
            {{# rows }}<tr>{{# cells }}<td>{{{ . }}}</td>{{/ cells }}</tr>{{/ rows }}
        </tbody>
    </table>
    ',

    'title' => '<h1 class="title{{# addClass }} {{ addClass }}{{/ addClass }}" id="{{ target }}">{{{ text }}}</h1>',

    'toc' => '<nav class="indexgroup">
        <table id="TOC">
            <caption><h2 id="TOC_Title">Table of Contents</h2></caption>
            {{# toc }}
            <tr class="toc-level-{{ level }}">
                <td class="toc-text"><a href="#{{ target }}">{{ text }}</a></td>
            </tr>
            {{/ toc }}
        </table>
    </nav>
    ',
    )
}
