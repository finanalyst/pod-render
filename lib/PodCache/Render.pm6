#! /usr/bin/env perl6
use v6.c;

=begin pod
=TITLE Rendering pod

This module provides functionality to take a precompiled pod and generate
output based on templates. To the extent possible, all rendering specific (eg. html)
code is moved to templates.

Pod file names are assumed to have no spaces in them.

=begin SYNOPSIS

    use PodCache::Render;

    my PodCache::Render $renderer .= new(
        :path<path-to-pod-cache>,
        :templates<path-to-templates>,
        :output<path-to-output>,
        :rendering<html>,
        :assets<path-to-assets-folder>,
        :config<path-to-config-folder>
        );
    my $ok = $renderer.update-cache; # identify new or changed pod sources
    exit note('The following sources failed to compile', $renderer.list-files('Failed').join("/n/t"))
        unless $ok;

    # if the collection needs to be recreated
    $renderer.create-collection;

    # to update an existing Collection
    $renderer.update-collection;

    # Utility  functions

    $renderer.verbose = True; # presume output is required for testing
    $renderer.templates-changed;
    $renderer.gen-templates;
    $renderer.generate-config-files;
    $renderer.test-config;

    # After C<create-collection> or C<update-collection>
    say $renderer.report;

=end SYNOPSIS
=head Installation
=begin code
zef install PodCache::Module
=end code

=head Methods and Build options

=item new
=item2 instantiates object and verifies cache is present
=item2 creates or empties the output directory
=item2 sets up templates from default or over-riding directory

=item :path
=item2 location of perl6 compunit cache, as generated by Pod::To::Cached
=item2 defaults to '.pod-cache'

=item :templates
=item2 location of templates root directory
=item2 defaults to C<resources/templates>, which is where a complete set of templates exists

=item :rendering
=item2 the type of rendering chosen
=item2 default is html, and refers to templates/html in which a complete set of templates exists
=item2 any other valid directory name can be used, eg md, so long as templates/md contains a complete set of templates
=item2 Individual templates can be over-ridden by providing it in the templates/html directory

=item :output
=item2 the path where output is sent
=item2 default is a directory with the same name as C<rendering> in the current working directory
=item2 if C<output> does not exist, then a Fatal Exception will be thrown.

=item :assets
=item2 path to a directory which may have subdirectories, eg.  C<js>, C<css>, C<images>
=item2 the subdirectories/files are copied to the C<output> directory

=item :config
=item2  path to a directory containing configuration files (see below)
=item2 configuration files are rendered into a html files with links to the pod files.

=item :collection-unique
=item2 boolean default False
=item2 if true href links in <a> tags must all be relative to collection (podfile appended to local link)
=item2 if false, then links internal to the source need only be unique relative to the source

=item create-collection
=item2 Creates a collection from scratch.
=item2 Erases all previous rendering files, rewrites the rendering database file
=item2 If the file ｢<config directory>/rendering.json｣ is absent, then update-collection will do the same
=item2 Generates the index files

=item update-collection
=item2 Compares timestamp of sources in cache with timestamp of rendered files
=item2 Regenerates rendered files when source in cache is newer.
=item2 Regenerates the index files based on new files.

=item report( :errors,  :links , :cache, :rendered )
=item2 Returns an array of strings containing information
=item2 no adverbs:  all link responses, all cache statuses, all files when rendered.
=item2 :errors (default = False):  Failed link responses, files with cache status Valid, Failed, Old; no rendering info
=item2 :links  (default = True): Supply link responses, hence C<:!links> suppresses link reponses.
=item2 :cache (default = True): ditto for cache reponses.
=item2 :rendered (default = True): timestamp rendered by source-name

=head1 Usage

To render a document cache to HTML:
=item place pod sources in C<doc>,
=item create a writable directory C<html/>
=item instantiate a Render object, (C<$renderer>)
=item run create-collection (C<$render.create-collection>)
=item verify whether there are problems to solve (C<$renderer.report>)

=head2 Customisation

=head3 Sources

The cache and sources are managed using C<Pod::To::Cache> module, and the source and repository names can be changed,
as documented in that module.

The source directory may contain subdirectories. The 'name' of a source is the subdirectory/basename of the source without an
extension, which are by default C<pod | pod6>.

=head3 Rendering

All of the rendering is done via mustache templates.

Each template can be over-ridden individually by setting the C<:templates> option to a directory and placing the mustache file there.

Typically, the template C<source-wrap.mustache> will be over-ridden in order to provide links to custom css, js, and image files.

The source-wrap template is called with the following elements:

=item    :title generated from the pod file's V<=TITLE>
=item    :subtitle generated from the pod file's V<=SUBTITLE>
=item    :metadata generated from the pod file's V<=AUTHOR, =SUMMARY, etc >
=item    :toc generated from the pod file's V<=HEAD>
=item    :index generated from the pod file's V< X<> elements>
=item    :footnotes generated from the pod file's V<N<> elements>
=item    :body generated from the pod file
=item    :path a string containing the original path of the POD6 file (if the doc-cache retains the information)

In order to see all the templates, instantiate a Render object pointing to a template directory, and run the C<gen-templates> method.
The templates C<toc> and C<index> may need tweaking for custom Table of Contents and Index (local index to the source) rendering.

=head3 CSS, JS, Images

All the contents (files and recursively subdirectories) in a directory provided to the C<:assets> option upon instantiation
will be copied to the subdirectory C<B<output>/assets/>, where B<output> is the directory for the rendered files.

=head Configuration

By default - that is without any configuration file(s) - a "landing page" index file, called C<index.B<ext>>, is generated
from the source cache with the documents
in the top directory of the cache listed by
TITLE, followed by the SUBTITLE, followed by the Table of Content for the cache file.
If the cache has subdirectories, then the name of the directory is made into a title, and the files under it are listed as above.

A separate file called C<global-index.B<ext>> is also generated by default containing
the indexed elements from all the pod-files in the cache.

These two files are rendered into html (by default), but if a different rendering has been specified, they will follow those rendering
templates.

If a C<config> directory is provided, Render will look for C<*.yaml> files and consider them customised index files.

The structure of the index file is documented in the default files (see below for generating default files). However, if B<a customised rendered file>
is required, eg., a customised C<index.html>, then the C<index.yaml> file (where B<index> could be any name) should contain the
single line C<source: R<filename.ext>>.

The R<filename.ext> should be the name of the file relative to the C<Configuration> directory and it will be copied to the C<Output>
directory.

Each configuration file will be converted from C<name.yaml> to C<name.B<ext>> where B<ext> is C<html> by default, but could, eg,
be C<md> if the rendering is to Markdown and templates are provided.

If there are sources in the document cache that are not included in customised C<*.yaml> index files, then a C<missing-sources.yaml>
configuration file will be generated and used to create an index file.

The indexation files are rendered using the templates C<indexation-file> and C<global-indexation-file>, respectively.
These templates can be over-ridden as required.

For more information, generate the default configuration files into the C<config> directory (see below).

=head2 Work Flow

The work flow to create a document collection might be:
=item create the collection (which will generate default configuration files)
=item remove creation errors (in pod sources)
=item edit configuration files into more content oriented forms
=item edit templates to customise content
=item run <test-indices> method to ensure that config files contain all source names and no typos create an invalid source
=item add customised css, js, and images

=item when source files are edited run C<update-collection> and check for errors using the C<report>method
=item2 eg C<die 'errors found: ' ~ $renderer.report(:all).join("\n") if +$renderer.report(:errors);>

=head2 Utilities

=item templates-changed
=item2 Generates a list of template names that have been over-ridden.

=item gen-templates
=item2 'templates/rendering' is interpreted as a directory, which must exist. All the mustache templates will be copied into it.
=item2 Only the templates required may be kept. Some templates, such as C<zero> do not need to be over-ridden as there is no rendering data.

=item generate-config-files
=item2 C<:config> is a writable directory that must exist, defaults to C<output>
=begin item2
    the two index files C<index.yaml> and C<global-index.yaml> are generated in that directory. The intent is to provide templates for
    customised config files. For more information generate a template.
=end item2
=item2 Care should be taken as any custom C<index.yaml> or C<global-index.yaml> files will be over-written by this method
=item2 The index files themselves are generated using the C<indexation-file>/C<global-indexation-file> templates
=item2 the extension of the final index files will be the same as C<rendering>
=item2 the filename of the index file will be same as the +.yaml files in the config directory

=item test-config-files
=item2 C<config> is a directory that should contain the config files.
=item2 if no .yaml files are in the config directory, the method will throw a Fatal Exception.
=item2 each pod6 file will be read and the filenames from V<=item> lines will be compared to the files in the doc-cache
=item2 any file present in I<the doc-cache>, but B<not> included in I<a config file> will be output into a config file called C<misc.pod6>
=item2 any filename included in I<a config file>, but B<not> in I<the doc-cache>, will be listed in a file called C<error.txt>

=end pod

constant RENDERING-DB = 'rendering.json';

use JSON::Fast;
use nqp;
use Pod::To::Cached;
use PodCache::Engine;
use PodCache::Processed;
use YAMLish;
use File::Directory::Tree;
use LibCurl::Easy;
use URI;

unit class PodCache::Render is Pod::To::Cached;

has PodCache::Engine $.engine;
has Bool $!collection-unique; # whether links must be unique to collection (True), or to Pod file (Default False)
has Bool $.verbose is rw;
has Bool $.debug is rw;

has $!config;
has $!assets;
has $!rendering;
has $!output;

has @!names; # ordered array of hash of names in cache, with directory paths
has %.global-index;
has @.global-links;
has SetHash $!links-tested .= new; # to avoid testing same external link twice
has @!link-responses; # keep responses for report method
has %.rendering-db; # rendering data base
has Bool $!cache-processed = False;

submethod BUILD(
    :$templates = Str,
    :$rendering = Str,
    :$output = Str,
    :$config = Str,
    :$!assets = Str,
    :$!collection-unique = False,
    :$!verbose = False,
    :$!debug = False,
    ) {
        $!engine .= new(:$templates, :$rendering,:$!verbose);
        $!rendering = $!engine.rendering; # this sequence so that default rendering is set only in Engine.pm6
        $!output = $output // $!rendering;
        $!config = $config // $!output;
        # both config and output directories must exist, no automatic generation
        die "Output destination ｢$!output｣ must be a directory" unless $!output.IO ~~ :d;
        die "Config location ｢$!config｣ must be a directory" unless $!config.IO ~~ :d;
        self.load-rendering-db
}

method gen-templates {
    $!engine.gen-templates
}

#| Generate default index files from the document cache
method generate-config-files {
    self.make-names unless +@!names;
    my @params ;
    my $last-head = '';
    for @!names {
        @params.push( %(:header( %(:level(.<level>), :text(.<dir>))))) if .<dir> ne $last-head;
        $last-head = .<dir>;
        @params.push( %(:item(  :filename( .<name> ) )) )
    };
    @params
        .push( %(:head( %( :level(1), :text('Global Index'), ) ) ) )
        .push(%(:item( %(:title('Index to all items in source files'), :link("global-index.$!rendering"), ) ) ) )
        ; # add to the bottom a link to the global index file.
    "$!config/index.yaml".IO.spurt: data('index-start') ~ save-yaml(%( :content( @params ) ,) ).subst(/^^  '---' $$ \s /,''); #take the top --- off the yaml file, its in data.
    "$!config/global-index.yaml".IO.spurt: data('global-index-start') ~ save-yaml(%( :content( proforma( +%.global-index.keys ) ) ,) ).subst(/^^  '---' $$ \s /,'')
}

method gen-missing-sources( @names ) {
    note 'missing-sources index generated' if $!verbose;
    if +@names {
        note 'missing-sources index generated' if $!verbose;
        my @content = @names.map( { %(:item( :filename( $_)))});
        "$!config/missing-sources.yaml".IO.spurt: data('missing-sources-start') ~ save-yaml(%( :@content ) ).subst(/^^  '---' $$ \s /,'');
    } else {
        if "$!config/missing-sources.yaml".IO ~~ :f {
            note 'missing-sources index removed' if $!verbose;
            "$!config/missing-sources.yaml".IO.unlink
        }
    }
}

method make-names {
    @!names =
        (gather for $.files.keys {
            take %( :name($_), :v([ .split('/')  ]) )  #gives a hash with origin and sort target
        }).sort({ .<v>.elems, .<v>.[0], .<v>.[1], .<v>.[2], .<v>.[3], .<v>.[4], .<v>.[5], .<v>.[6] }) #shortest first, then by part
            .map( { %(:name(.<name>), :level(.<v>.elems), :fn( .<v>.pop ), :dir( .<v>.join('/') ) ) } ) # rewrite elements to a hash
        ;    #should be no more than 7 layers
}

method source-wrap( PodCache::Processed $pf, :$name = $pf.name ) {
    # note that if $name has / chars, the file will be in a subdirectory
    unless "$!output/$name".IO.dirname.IO ~~ :d {
        mktree "$!output/$name".IO.dirname # make sure the sub-directory exists in the output directory
    }
    "$!output/$name.$!rendering".IO.spurt: $pf.source-wrap(:$name)
}

method processed-instance( :$name ) {
    PodCache::Processed.new(
        :$name,
        :pod-tree( self.pod($name) ),
        :path( $.files{$name}<path> ),
        :$!collection-unique,
        :$!engine,
        :$!debug,
        :$!verbose,
    )
}

method process-cache( @names = $.list-files(<Current Valid>)  ) { # ignore Failed & Old
    note "{+@names} sources for processing" if $!verbose;
    self.process-name($_) for @names;
    note 'writing rendering db' if $!verbose;
    self.write-rendering-db;
    note 'writing configuration files' if $!verbose;
    self.write-config-files;
    note 'testing links in processed files' if $!verbose;
    self.links-test;
    note 'cache processed' if $!verbose;
    $!cache-processed = True
}

method process-name( Str:D $source-name ) {
    my $pf = self.processed-instance( :name($source-name) );
    # add data needed for index files
    %!rendering-db{ $source-name }<title subtitle toc link> = $pf.title, $pf.subtitle, $pf.toc, $source-name;
    %.global-index{$source-name} = $pf.index if +$pf.index.keys;
    # Only need to test links related to files that are processed
    for $pf.links.list { # registered links out
        @!global-links.push: %(|$_, :source($source-name))
    }
    self.source-wrap($pf);
    %!rendering-db{$source-name}<rendered> = now;
}

method write-rendering-db {
    # %!rendering-db keys:
    # global-index = index items to be rendered in global-index, stored as source{item[target,place]}
    # files = files valid or current in cache, stored as {source{Instant:rendered, title, subtitle, toc}}
    # stored in file under key $!rendering (to allow for multiple renderings)
    my %rdb;
    %rdb = from-json( ($!config ~ '/' ~ RENDERING-DB).IO.slurp ) if ($!config ~ '/' ~ RENDERING-DB).IO ~~ :f;
    %rdb{$!rendering}<files global-index> = %!rendering-db, %!global-index;
    # do it this way to preserve other rendering data
    ($!config ~ '/' ~ RENDERING-DB).IO.spurt: to-json( %rdb )
}

method load-rendering-db {
    my $db = ($!config ~ '/' ~ RENDERING-DB).IO;
    try {
        CATCH {
            default {
                die 'Failure building Render object with ' ~ .payload
            }
        }
        if $db ~~ :f {
            my %inp = from-json( $db.slurp );
            %!rendering-db = %inp{$!rendering}<files>;
            .value<rendered> = DateTime.new( .value<rendered> ).Instant for %!rendering-db;
            %!global-index = %inp{$!rendering}<global-index>;
        }
        else {
            %!rendering-db = %();
            %!global-index = %();
        }
    }
}

method templates-changed {
    $!engine.over-ridden, 'from ' ~ $!engine.t-dir;
}

method links-test {
    # only test the links in newly processed files
    @!link-responses = ();
    $!links-tested = Nil;
    # generate a set of targets from the global-index in the form source#target
    # this form is specified by Pod and is rendering independent
    my Set $gtargets .= new: gather for %!global-index.kv -> $fn, %entries {
        for %entries.kv -> $en, @dp {
            for @dp { take "$fn#{ .<target> }" }
        }
    };
    for @.global-links.list -> %info {
        my Str $err;
        my $inf = "link with label ｢{%info<content> }｣ in source ｢{ %info<source> }｣ ";
        my $link = ~%info<target>;
        unless $gtargets{ $link } or $!links-tested{ $link }++ { #first time encountered links-tested{} 0 so false, duplicates >0
            # Any legitimate local target will be in the global-targets Set
            # So link is external untested or mal-formed internal
            $err = self.test-link( $link );
            if $err {
                # look to see if this is a possible local link
                my URI $uri .= new($link);
                $err ~= "\n\t\tIs there an error in a local target?" if $uri.scheme ne any(<http https>);
            }
            @!link-responses.append( $err
                ?? "Error: $inf\n\t$err"
                !! "OK: $inf with target ｢$link｣"
            )
        }
        @!link-responses.append( "OK: local target ｢$link｣ $inf")
            if ! $!links-tested{ $link } and $gtargets{ $link } # not in tested set because gtargets test shortcircuits in unless
    }
    note "Link responses are:\n", @!link-responses.join("\n") if +@!link-responses and $!verbose ;
}

method test-link($target --> Str ) {
    state LibCurl::Easy $curl .=new(:!verbose, :followlocation );
    my Str $err;
    CATCH {
        when X::LibCurl {
            $err = "｢$target｣ caused Exception ｢{$curl.response-code}｣ with error ｢{$curl.error}｣";
            .resume # need to try an alternative
        }
    }
    $curl.setopt(:URL( $target ));
    $curl.perform; # this is where Exception should happen if it does
    unless $curl.success or $err  {
        $err = "｢$target｣ generated response ｢{$curl.response-code}｣ with error ｢{$curl.error}｣"
    }
    $err # Will return with undefined string if success
}

method update-collection {
    $.update-cache;
    unless "{$!output}/assets".IO ~~ :d {
        mktree("$!output/assets") or die "Cannot create output directory at ｢{$!output}/assets｣";
        with $!assets {
            for $!assets.IO.dir {
                mktree .dirname unless .dirname.IO ~~ :d;
                .copy: "$!output/assets/"
            }
        }
        else {
            # no assets given, so copy pod.css
            %?RESOURCES<assets/pod.css>.copy: "$!output/assets/pod.css"
        }
    }
    self.process-cache(
        $.list-files(<Current Valid>).grep({
            %.rendering-db{$_}:!exists
            or $.cache-timestamp( $_ ) > %.rendering-db{$_}<rendered> })
    )
}

method create-collection {
    # remove from output
    #    all  files except *.yaml (if output = config)
    #    all subdirectories except assets
    # remove from config RENDERING-DB (if output != config)
    for $!output.IO.dir {
        next if .d and .basename eq 'assets';
        .&rmtree if .d;
        .unlink if .f and .extension ne 'yaml'
    };
    ($!config ~ '/' ~ RENDERING-DB).IO.unlink if ($!config ~ '/' ~ RENDERING-DB).IO ~~ :f;
    %.rendering-db = Empty;
    %!global-index = Empty;
    self.update-collection
}

method test-config-files( :$quiet  = False  ) {
    # No need to test global-index files because if there are items not in the section headers,
    # then they will be put into the Misc section
    my @index-files = dir($!config, :test(/ '.yaml' /) );
    unless +@index-files {
        note 'No *.yaml files so generating defaults' if $!verbose;
        # testing index files without any existing ones, generates an error, to make this a quicker test.
        return
            %( :not-in-index( $.files.keys ),
                :not-in-cache( Nil ),
                :duplicates-in-index( Nil ),
                :index-and-cache( Nil ),
                :errors( 'No *.yaml files' , ) )
    }
    my $residue = SetHash.new: $.files.keys;
    my $cache = Set.new: $.files.keys;
    my @index-and-cache = ();
    my @not-in-cache = ();
    my @duplicates-in-index = ();
    my @errors = ();
    for @index-files -> $fn {
        next if ~$fn ~~ /'missing-sources'/; # will regenerate missing...
        my %single-index = load-yaml( $fn.slurp );
        CATCH {
            default {
                @errors.push: "With ｢{ $fn.basename }｣: { .payload }"
            }
        } # leaves for block if error found
        next if %single-index<source>:exists; # A custom index file is desired, so ignore it.
        if %single-index<type>:exists and %single-index<type> eq 'global-index' {
            #TODO
            # Question is what sort of behaviour is wrong
            # Perhaps test viability of regexen ?
        }
        else {
            @errors.push("With ｢$fn｣: No title") unless %single-index<title>:exists;
            with %single-index<content> {
                for %single-index<content>.kv -> $entry, %info {
                    @errors.push("With ｢$fn｣: No header text at entry # $entry")
                        if %info<header>:exists and %info<header><text>:!exists;
                    if %info<item>:exists {
                        if %info<item><filename>:exists {
                            my $ifn = %info<item><filename>;
                            if $residue{ $ifn }-- {
                                @index-and-cache.push: $ifn
                            }
                            else {
                                if $cache{ $ifn } {
                                    @duplicates-in-index.push: ~$ifn
                                }
                                else {
                                    @not-in-cache.push: ~$ifn
                                }
                            }
                        }
                        else {
                            @errors.push("With ｢$fn｣: No item filename or ( link & title) at entry # $entry")
                                unless %info<item><link>:exists and  %info<item><title>:exists
                        }
                    }
                }
            }
            else {
                @errors.push("With ｢$fn｣: No content list")
            }
        }
    }
    unless $quiet {
        note "Errors found: " ~
            (+@errors ?? ("\n\t" ~ @errors.join("\n\t")) !! "None" );
        note "Pod sources summary";
        note "Number in cache and in config file(s): ", +@index-and-cache;
        note "Source names in cache but not in config file(s): " ~
            (+$residue.keys ?? ("\n\t" ~ $residue.keys.join("\n\t")) !! "None" );
        note "Source names duplicated in config file(s): ",
            (+@duplicates-in-index ?? ("\n\t" ~ @duplicates-in-index.join("\n\t")) !! "None" );
        note "Source names not in cache but in config file(s): ",
            (+@not-in-cache ?? ("\n\t" ~ @not-in-cache.join("\n\t")) !! "None" );
    }
    my @not-in-index = $residue.keys>>.Str;
    self.gen-missing-sources(@not-in-index )
        if +@not-in-index;
    %( :@not-in-index,
        :@not-in-cache,
        :@duplicates-in-index,
        :@index-and-cache,
        :@errors )
}

method write-config-files {
    my @index-files = dir($!config, :test(/ '.yaml' /) );
    if +@index-files {
        my %test = self.test-config-files(:quiet( ! $!verbose)); # make sure we can read the index files
        exit note "Cannot write index files because: " ~ %test<errors>.join("\n\t") if +%test<errors>;
    }
    else {
        #defaults when no config files given in CONFIG
        self.generate-config-files;
        @index-files = <index global-index>.map( { "$!config/$_.yaml".IO } );
        # these do not need to be tested because they are generated correctly
    }
    # index files are written based on information in %.rendering-db
    for @index-files {
        my %params = self.process-config( $_  );
        next unless %params; # Empty params if a index is copied from a source
        my $fn = .basename.substr( 0, *-5 ); #get rid of yaml
        "$!output/$fn.$!rendering".IO.spurt:
            $!engine.rendition((%params<type> eq 'global-index' ?? 'global-indexation-file' !! 'indexation-file'), %params);
    }
}

method process-config( $fn ) {
    my %index = load-yaml( $fn.slurp );
    if %index<source>:exists {
        "$!config/{%index<source>}".IO.copy: "$!output/{%index<source>}" # extension should be provided
            if "$!config/{%index<source>}".IO ~~ :f;
        note "No source corresponding to $!config/{%index<source>} exists"
            if $!verbose and ! ("$!config/{%index<source>}".IO ~~ :f);
        return Empty
    }
    my %params = :title(%index<title>), :body( '' ), :path( ~$fn ), :type( %index<type> // 'normal' );
    my $body := %params<body>;
    $body ~=
        $!engine.rendition('title', %( :text(%index<title>), :target<__top> ) )
        ~ ( %index<subtitle>:exists ?? $!engine.rendition('subtitle', %(:contents( %index<subtitle>) ) ) !! '' );
    if %index<type>:exists and %index<type> eq 'global-index' {
        # reform the global-index
        # from { <source>{<entry>[<target><place>]} }
        # to { <entry>[<source-title><target><place>] }
        my %gindex;
        for %!global-index.kv -> $source, %info {
            my $location = %!rendering-db{$source}<title>;
            for %info.kv -> $entry, @data {
                for @data -> %dp {
                    with %gindex{$entry} { %gindex{ $entry }.push: %( |%dp, :$location, :$source ) }
                    else { %gindex{$entry} = [ %( |%dp, :$location, :$source ), ] }
                }
            }
        }
        my SetHash $residue .= new: %gindex.keys;
        for %index<content>.list -> %entry {
            $body ~= $!engine.rendition('global-indexation-heading', %(
                :level( %entry<level>),
                :text( %entry<head>),
            ) );
            my $rg = %entry<regex>;
            my @sect-entries;
            for $residue.keys.sort {
                if m/ <$rg> / {
                    $residue{$_}--; # remove from set at first match
                    @sect-entries.push: %( :text( $_ ), :refs( %gindex{$_} )  )
                }
            }
            $body ~= $!engine.rendition('global-indexation-defn-list', %( :list(@sect-entries)))
        }
        if +$residue.keys {
            # Not all the index entries have been used up by the regexes
            $body ~= $!engine.rendition('indexation-heading', {
                :2level,
                :text('Miscellaneous'),
            } );
            my @sect-entries;
            for $residue.keys.sort {
                @sect-entries.push: %( :text( $_ ), :refs( %gindex{$_} )  )
            }
            $body ~= $!engine.rendition('global-indexation-defn-list', %( :list(@sect-entries)))
        }
    }
    else {
        for %index<content>.list -> %entry {
            $body ~= $!engine.rendition('indexation-heading', %(
                :level( %entry<header><level>),
                :text(%entry<header><text>) ,
                :subtitle( %entry<header><subtitle> // ''),
            ) ) if %entry<header>:exists;
            $body ~= $!engine.rendition('indexation-entry', self.source-params( %entry<item> ) )
                if %entry<item>:exists;
        }
    }
    %params
}

method source-params( %info ) {
    if %info<filename>:exists and %!rendering-db{%info<filename>}:exists {
        my $source-info := %!rendering-db{%info<filename>};
        # a link in the config file is ignored
        # if there is a use case for specifying links in the config, this is where the
        # code should probably exist. But links would need to be rewritten.
        %(
            :title( %info<title> // $source-info<title> // 'No title' ),
            :subtitle( %info<subtitle> // $source-info<subtitle> // ' ' ),
            :toc( (%info<toc>:!exists or (%info<toc>:exists and %info<toc>)) ?? $source-info<toc> !! '' ), # default = no <toc> = show toc
            :link( $source-info<link> )
        )
    }
    else { # this is used when another file is linked to, in which case a title should be provided and a link.
        %(
            :title( %info<title> // 'No file name or title defined' ),
            :subtitle( %info<subtitle> // '' ),
            :toc( '' ), #No toc where no pod
            :link( %info<link> // '' )
        )
    }
}

method report( Bool :$errors = False, Bool :$links = True, Bool :$cache = True, Bool :$rendered = True ) {
    my @rv;
    @rv = @!link-responses.grep({ ! $errors or m/ ^ 'Error' /  }) if $links;
    @rv = @.error-messages if $cache;
    @rv.append( $.hash-files.fmt ) if ! $errors and $cache;
    @rv.append( $.hash-files(<Old Failed Valid>).fmt ) if $errors and $cache;
    @rv.append( %.rendering-db.map({ .key ~ "\trendered on " ~ .value<rendered>.DateTime.truncated-to('second') }).sort )
        if $rendered and ! $errors;
    @rv
}

sub proforma( Int $elems --> Array ) {
    given $elems {
        when * <= 10 {
            [
                %( :head('A(a) to P(p)'),  :regex( " ^ <[A..P,a..p]>  " ), :2level, ),
                %( :head('Q(q) to Z(z)'),  :regex( " ^ <[Q..Z,q..z]>  " ), :2level, ),
            ]
        }
        when 10 < * <= 50 {
            [
                %( :head('A(a) to E(e)'),  :regex( " ^ <[A..E,a..e]>  " ), :2level, ),
                %( :head('F(f) to J(j)'),  :regex( " ^ <[F..J,f..j]>  " ), :2level, ),
                %( :head('K(k) to O(o)'),  :regex( " ^ <[K..O,k..o]>  " ), :2level, ),
                %( :head('P(p) to S(s)'),  :regex( " ^ <[P..S,p..s]>  " ), :2level, ),
                %( :head('T(t) to Z(z)'),  :regex( " ^ <[T..Z,t..z]>  " ), :2level, ),
            ]
        }
        when * > 50 {
            [
                %( :head('A(a) to B(b)'),  :regex( " ^ <[A..B,a..b]>  " ), :2level, ),
                %( :head('C(c) to D(d)'),  :regex( " ^ <[C..D,c..d]>  " ), :2level, ),
                %( :head('E(e) to F(f)'),  :regex( " ^ <[E..F,e..f]>  " ), :2level, ),
                %( :head('G(g) to H(h)'),  :regex( " ^ <[G..H,g..h]>  " ), :2level, ),
                %( :head('I(i) to J(j)'),  :regex( " ^ <[I..J,i..j]>  " ), :2level, ),
                %( :head('K(k) to L(l)'),  :regex( " ^ <[K..L,k..l]>  " ), :2level, ),
                %( :head('M(m) to N(n)'),  :regex( " ^ <[M..N,m..n]>  " ), :2level, ),
                %( :head('O(o) to P(p)'),  :regex( " ^ <[O..P,o..p]>  " ), :2level, ),
                %( :head('Q(q) to R(r)'),  :regex( " ^ <[Q..R,q..r]>  " ), :2level, ),
                %( :head('S(s) to T(t)'),  :regex( " ^ <[S..T,s..t]>  " ), :2level, ),
                %( :head('U(u) to V(V)'),  :regex( " ^ <[U..V,u..v]>  " ), :2level, ),
                %( :head('W(w) to Z(z)'),  :regex( " ^ <[W..Z,w..z]>  " ), :2level, ),
            ]
        }
    }
}

sub data($item) {
    given $item {
        when 'index-start' {
            q:to/DATA/;
                ---
                # This is a configuration file that will be interpreted by C<PodCache::Render>
                # to create an index file containing all the files in the document cache
                # This file is generated with the intent that it can be a template for customised
                # index files.
                # Styling and presentation information should be contained in the template
                # used to render the index viz., indexation-file.
                # The indexation-file template should typically be over-ridden.

                # The structure of an index file is as follows
                # - title: text in the title # mandatory
                # - subtitle: paragraph immediately following the title # optional
                # - head:
                #    level: an optional attribute and will be used for the header level
                #    text: a required attribute. Is the text of the header
                #    subtitle: optional. Paragraph following heading.
                # - item:
                #      filename: the name of file in the document cache
                #        # if the filename is missing, no error is generated
                #        # if the file corresponding to the filename does not exist, no error is generated
                #        # Consequently, links other files, such as other index files, can be included by
                #        # ommiting the filename, or using one not in the cache, whilst providing
                #        # a link and text  (see below)
                #     # the following are optional and when absent, the data is taken from the pod file attributes
                #     title: the text to be used to refer to the filename in place of the pod's TITLE attribute
                #     subtitle: text used instead of the pod's SUBTITLE attribute
                #     link: the link to be used to refer to the file instead of the URL generated from the pod file name
                #     toc: whether or not to include the pod file's toc. Defaults to True

                title: Perl 6 Documentation
                subtitle: Links to the rendered pod files, one for each file in the document cache. Listed alphabetically.
                    Where pod files are arranged in sub-directories, the path is used as a heading.

                DATA
        }
        when 'global-index-start' {
            q:to/DATA/
                ---
                # This is a configuration file that will be interpreted by C<PodCache::Render>
                # to create a global index file containing all entries indexed in all the sources in the document cache
                # This file is generated with the intent that it can be a template for customised
                # index files.
                # Styling and presentation information should be contained in the template
                # used to render the global-index viz., global-indexation-file.
                # The global-indexation-file template should typically be over-ridden for custom css and js

                # The structure of the global-index.yaml file is as follows
                # - type: global-index # mandatory for the global-index
                #    # the intent of this option is to allow a different rendering for
                #    # landing page index files and global-indices
                # - title: To be in the title # mandatory
                # - subtitle: Paragraph immediately following the title # optional
                # - head: Separator between sections of index
                #   level: The heading level - typically 2
                #   text: The text in the header
                #   regex: The regex to be applied to the index entry for inclusion in this section
                #  # To generate the rendered global-index, the index entries are sorted alphabetically, compared
                #  # to the regex, and added to the first section whose regex matches.
                #
                # Any missing indexed entries not matched by a section will be added to
                # a Miscellaneous Section at the end.

                type: global-index
                title: Global Index of Perl 6 Documentation
                subtitle: Links to indexed items in all files in document collection.

                DATA
        }
        when 'missing-sources-start' {
            q:to/DATA/;
                ---
                # This is a configuration file that will be interpreted by C<PodCache::Render>
                # to create an index file containing the sources missing in existing indices
                # The indexation-file template should typically be over-ridden.

                # The structure of an index file is as follows
                # - title: text in the title # mandatory
                # - subtitle: paragraph immediately following the title # optional
                # - head:
                #    level: an optional attribute and will be used for the header level
                #    text: a required attribute. Is the text of the header
                #    subtitle: optional. Paragraph following heading.
                # - item:
                #      filename: the name of file in the document cache
                #        # if the filename is missing, no error is generated
                #        # if the file corresponding to the filename does not exist, no error is generated
                #        # Consequently, links other files, such as other index files, can be included by
                #        # ommiting the filename, or using one not in the cache, whilst providing
                #        # a link and text  (see below)
                #     # the following are optional and when absent, the data is taken from the pod file attributes
                #     title: the text to be used to refer to the filename in place of the pod's TITLE attribute
                #     subtitle: text used instead of the pod's SUBTITLE attribute
                #     link: the link to be used to refer to the file instead of the URL generated from the pod file name
                #     toc: whether or not to include the pod file's toc. Defaults to True

                title: Perl 6 Missing Sources
                subtitle: Links to the rendered pod files, one for each file in the document cache. Listed alphabetically.
                    Where pod files are arranged in sub-directories, the path is used as a heading.

                DATA
        }
    }
}
