use v6.c;
use PodCache::Engine;
constant TOP = '__top';
use Data::Dump;

unit class PodCache::Processed;
    has Str $.name;
    has Str $.title is rw;
    has Str $.sub-title is rw;
    has Str $.path; # may/may not exist, but is path of original document
    has Str $.top; # target for TITLE
    has $.pod-tree; # cached pod
    has Str $.pod-body; # generated html
    has @.toc = ();
    has %.index = ();
    has @.links = (); # for links outside the Processed
    has @.footnotes = ();
    has SetHash $.targets .= new; # target names are relative to Processed
    has Int @.counters is default(0);
    has Bool $.debug is rw;
    has Bool $.verbose;
    has @.itemlist = (); # for multilevel lists
    has @.metalist = ();
    has Bool $!global-links;

    my PodCache::Engine $engine;

    submethod BUILD  (
        :$!name,
        :$!title = $!name,
        :$!pod-tree,
        :$!debug = False,
        :$!verbose = False,
        :$templater,
        :$!global-links,
        :$!path = '',
        ) { $engine = $templater }

    submethod TWEAK {
        $!top = self.unique-target( TOP );
        self.process-pod;
    }

    method register-toc(:$level!, :$text! --> Str) {
        @!counters[$level - 1]++;
        @!counters.splice($level);
        my $target = self.unique-target('t_' ~ @!counters>>.Str.join: '_') ;
        @!toc.push: %( :$level, :$text, :$target);
        $target
    }
    method render-toc( --> Str ) {
        $engine.rendition('toc', { :toc( @!toc ) });
    }
    method register-index(:$text! is copy, :$place is copy --> Str) {
        $text = 'blank' if $text ~~ / ^ \s* $ /;
        $place = 'Here' if $place ~~ / ^ \s* $ /;
        %.index{$text} = Array unless %.index{$text}:exists;
        my $target = self.unique-target("t_$text") ;
        %.index{$text}.push: %(:$target, :$place);
        $target
    }
    method render-index(-->Str) {
        return '' unless +%!index.keys; #No render without any keys
        $engine.rendition( 'index', { :index([gather for %!index.sort {  take %(:text(.key), :refs( [.value.sort] )) } ]) }  )
    }
    method register-link(:$content! is copy, :$target!) {
        $content= $target if $content ~~ / ^ \s* $ /;
        @!links.push: %( :$content, :$target)
    }
    method register-footnote(:$text! --> Hash ) {
        my $fnNumber = +@!footnotes + 1;
        my $fnTarget = self.unique-target("fn$fnNumber") ;
        my $retTarget = self.unique-target("fnret$fnNumber");
        @!footnotes.push: {:$text, :$retTarget, :$fnNumber, :$fnTarget };
        (:$fnTarget, :$fnNumber, :$retTarget).hash
    }
    method render-footnotes(--> Str){
        return '' unless +@!footnotes; # no rendering of code if no footnotes
        $engine.rendition('footnotes', { :notes( @!footnotes ) } )
    }
    method register-meta( :$name, :$value ) {
        push @!metalist: %( :$name, :$value )
    }
    method render-meta {
        return '' unless +@!metalist;
        $engine.rendition('meta', { :meta( @!metalist ) })
    }
    method process-pod {
        say "Processing pod for $.name" if $!verbose;
        (say "pod-tree is:" and dd $!pod-tree) if $.debug;
        $!pod-body = [~] $!pod-tree>>.&handle( 0, self );
    }

    method unique-target(Str $name is copy --> Str ) {
        $name = $name.subst(/\s+\.*|\./,'_',:g).subst(/<-alnum>/,'',:g).substr(0,15);
        $name ~= '_1' if $name (<) $!targets;
        ++$name while $!targets{$name};
        my $prefix = '#' ~ ($!global-links ?? $!name.subst([\/], '_') !! '');
        $prefix ~ $name
    }

    method completion(Int $in-level, Str $key, %params --> Str) {
        my Str $rv = '';
        my $top-level = @.itemlist.elems;
        while $top-level > $in-level {
            if $top-level > 1 {
                @.itemlist[$top-level - 2][0] = '' unless @.itemlist[$top-level - 2][0]:exists;
                @.itemlist[$top-level - 2][* - 1] ~= $engine.rendition('list', {:items( @.itemlist.pop ) })
            }
            else {
                $rv ~= $engine.rendition('list', {:items( @.itemlist.pop ) })
            }
            $top-level = @.itemlist.elems
        }
        $rv ~= $engine.rendition($key, %params);
    }

    my enum Context <None Index Heading HTML Raw Output>;

    #| Multi for handling different types of Pod blocks.
    multi sub handle (Pod::Block::Code $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        my $addClass = $node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '';
        $pf.completion($in-level, 'block-code', {:$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf ) )} )
    }

    multi sub handle (Pod::Block::Comment $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'zero', {:contents([~] $node.contents>>.&handle($in-level, $pf ))})
    }

    multi sub handle (Pod::Block::Declarator $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'notimplemented', {:contents([~] $node.contents>>.&handle($in-level, $pf ))})
    }

    multi sub handle (Pod::Block::Named $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'section', { :name($node.name), :contents( [~] $node.contents>>.&handle($in-level, $pf ))  })
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'TITLE', Int $in-level, PodCache::Processed $pf --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $text = $pf.title = $node.contents[0].contents[0].Str;
        my $target = $pf.top;
        $pf.completion($in-level, 'title', {:$addClass, :$target, :$text } )
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'SUBTITLE', Int $in-level, PodCache::Processed $pf --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $content = $node.contents[0].contents[0].Str;
        $pf.completion($in-level, 'subtitle', {:$addClass, :$content } )
    }

    multi sub handle (Pod::Block::Named $node where $node.name ~~ any(<VERSION DESCRIPTION AUTHOR COPYRIGHT SUMMARY>),
        Int $in-level, PodCache::Processed $pf --> Str ) {
        $pf.register-meta(:name($node.name.lc), :value($node.contents[0].contents[0].Str));
        $pf.completion($in-level, 'zero', {:content(' ') } ) # make sure any list is correctly ended.
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'Html' , Int $in-level, PodCache::Processed $pf--> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.contents>>.&handle($in-level, $pf, HTML) ) } )
    }

    multi sub handle (Pod::Block::Named $node where .name eq 'output', Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'output', {:contents( [~] $node.contents>>.&handle($in-level, $pf, Output) ) } )
    }

    multi sub handle (Pod::Block::Named $node where .name eq 'Raw', Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.contents>>.&handle($in-level, $pf, Output) ) } )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, PodCache::Processed $pf, Context $context where * == Output  --> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.contents».&handle($in-level, $pf ) ) } )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, PodCache::Processed $pf , Context $context? = None --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'para', {:$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, PodCache::Processed $pf, Context $context where * != None  --> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.contents>>.&handle($in-level, $pf, $context) ) } )
    }

    multi sub handle (Pod::Block::Table $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my @headers = gather for $node.headers { take .&handle($in-level, $pf ) };
        $pf.completion($in-level,  'table', {
                :$addClass,
                :caption( $node.caption ?? $node.caption.&handle($in-level, $pf ) !! ''),
                :headers( +@headers ?? %( :cells( @headers ) ) !! Nil ),
                :rows( [ gather for $node.contents -> @r {
                    take %( :cells( [ gather for @r { take .&handle($in-level, $pf ) } ] )  )
                } ] ),
            } )
    }

    multi sub handle (Pod::Heading $node, Int $in-level, PodCache::Processed $pf --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $level = $node.level;
        my $text = [~] $node.contents>>.&handle($in-level, $pf, Heading);
        my $target = $pf.register-toc( :$level, :$text );
        $pf.completion($in-level, 'heading', {
            :$level,
            :$text,
            :$addClass,
            :$target,
            :top( $pf.top )
        })
    }

    multi sub handle (Pod::Item $node, Int $in-level is copy, PodCache::Processed $pf --> Str  ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $level = $node.level - 1;
        while $level < $in-level {
            --$in-level;
            $pf.itemlist[$in-level]  ~= $engine.rendition('list', {:items( $pf.itemlist.pop )} )
        }
        while $level >= $in-level {
            $pf.itemlist[$in-level] = []  unless $pf.itemlist[$in-level]:exists;
            ++$in-level
        }
        $pf.itemlist[$in-level - 1 ].push: $engine.rendition('item', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf ) ) } );
        return '' # explicitly return an empty string because callers expecting a Str
    }

    # note no template needed
    multi sub handle (Pod::Raw $node, Int $in-level, PodCache::Processed $pf --> Str ) { say 'is raw';
        $engine.rendition('raw', {:contents( [~] $node.contents>>.&handle($in-level, $pf ) ) } )
    }

    multi sub handle (Str $node, Int $in-level, PodCache::Processed $pf, Context $context? = None --> Str ) {
        $engine.rendition('escaped', {:contents(~$node)})
    }

    multi sub handle (Str $node, Int $in-level, PodCache::Processed $pf, Context $context where * == HTML --> Str ) {
        $engine.rendition('raw', {:contents(~$node)})
    }

    multi sub handle (Nil) {
        die 'Nil';
    }

    multi sub handle (Pod::Config $node, Int $in-level, PodCache::Processed $pf  --> Str ) {
        $pf.completion($in-level, 'comment',{:contents($node.type ~ '=' ~ $node.config.perl) } )
    }

    multi sub handle (Pod::FormattingCode $node, Int $in-level, PodCache::Processed $pf, Context $context where * == Raw   --> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.contents>>.&handle($in-level, $pf, $context) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'B', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        $pf.completion($in-level, 'format-b',{:$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) ) })
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'C', Int $in-level, PodCache::Processed $pf, Context $context? = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-c', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'C', Int $in-level, PodCache::Processed $pf, Context $context where * ~~ Index   --> Str ) {
        $pf.completion($in-level, 'format-c-index', {:contents( [~] $node.contents>>.&handle($in-level, $pf ) )})
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'E', Int $in-level, PodCache::Processed $pf, Context $context? = None   --> Str ) {
        $pf.completion($in-level, 'raw', {:contents( [~] $node.meta.map({ when Int { "&#$_;" }; when Str { "&$_;" }; $_ }) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'Z', Int $in-level, PodCache::Processed $pf, $context = None   --> Str ) {
        $pf.completion($in-level, 'zero',{:contents([~] $node.contents>>.&handle($in-level, $pf, $context)) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'I', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        $pf.completion($in-level, 'format-i',{:$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) ) })
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'X', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        my $text = [~] $node.contents>>.&handle($in-level, $pf, $context);
        my $place = [~] $node.meta;
        my $target = $pf.register-index( :$text, :$place );
        $pf.completion($in-level, 'format-x',{:$addClass, :$text, :$target,  :header( $context ~~ Heading ) })
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'N', Int $in-level, PodCache::Processed $pf, Context $context = None --> Str ) {
        my $text = [~] $node.contents>>.&handle($in-level, $pf,$context);
        $pf.completion($in-level, 'format-n', $pf.register-footnote(:$text) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'L', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $content = [~] $node.contents>>.&handle($in-level, $pf, $context);
        my $target = $node.meta eqv [] | [""] ?? $content !! $node.meta[0];
        $pf.register-link( :$content, :$target );
        # link handling needed here to deal with local links in global-link context
        $pf.completion($in-level, 'format-l', {:$target, :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'R', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-r', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'T', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-t', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'K', Int $in-level, PodCache::Processed $pf, Context $context? = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-k', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'U', Int $in-level, PodCache::Processed $pf, Context $context = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-u', {:$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'V', Int $in-level, PodCache::Processed $pf, Context , $context = None  --> Str ) {
        $pf.completion($in-level, 'raw', {:contents([~] $node.contents>>.&handle($in-level, $pf, $context ) ) } )
    }

    =begin takeout
    #| the following format codes are not in the POD documentation, but in Synopsis
    #| the following is code from BigPage.pm6, on which this module is based
    multi sub handle (Pod::FormattingCode $node where .type eq 'F', Int $in-level, PodCache::Processed $pf, $context = None   --> Str ) {
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-f', {:$addClass, :contents($node.contents>>.&handle($in-level, $pf, $context ) ) } );
    }
    # mustache would be:
    # <span class="filename{{# addClass }} {{ addClass }}{{/ addClass }}">{{ content }}</span>

    multi sub handle (Pod::FormattingCode $node where .type eq 'P', $context = None, :$pod-name?, :$part-number?, :$toc-counter?) {
        my $content = $node.contents>>.&handle($context).Str;
        my $link = $node.meta eqv [] | [""] ?? $content !! $node.meta;

        use LWP::Simple;
        my @url = LWP::Simple.parse_url($link);
        my $doc;
        given @url[0] {
            when 'http' | 'https' {
                $doc = LWP::Simple.get($link);
            }
            when 'file' {
                $doc = slurp(@url[3]);
            }
            when '' {
                $doc = slurp(@url[3]);
            }
        }
        if $doc {
            given @url[3].split('.')[*-1] {
                when 'txt' { return '<pre>' ~ $doc.&escape-markup ~ '</pre>'; }
                when 'html' | 'xhtml' { return $doc }
            }
        }
        warn "did not inline $link";
        q:c{<a href="{$link}">{$content}</a>}
    }


        # NYI
        # multi sub handle (Pod::Block::Ambient $node) {
        #   $node.perl.say;
        #   $node.contents>>.&handle;
        # }
    =end takeout
