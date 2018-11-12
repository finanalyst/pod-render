# Pod::Render

Render pod from cached pod created by Pod::Cached

This module provides functionality to take a precompiled pod and generate
output based on templates. The default templates are for html and for a separate
HTML file for each source pod.

## Install

This module is in the [Perl 6 ecosystem](https://modules.perl6.org), so you install it in the usual way:

    zef install Pod::Render


# SYNOPSIS
```perl6
    use Pod::Render;

    my Pod::Render $renderer .= new(
        :path<path-to-pod-cache>,
        :templates<path-to-templates>,
        :output<path-to-output>,
        :rendering<html>,
        :!global-links
        );
```

## new
    - instantiates object and verifies cache is present
    - creates or empties the output directory
    - verifies that <templates>/<rendering> directory exists and contains
        a full set of templates

## path
    - location of perl6 compunit cache, as generated by Pod::Cached
    - defaults to '.pod-cache'

## templates
    - location of templates root directory
    - defaults to 'resources/templates', which is where a complete set of templates exists

## rendering
    - the type of rendering chosen
    - default is html, and refers to templates/html in which a complete set of templates exists
    - any other valid directory name can be used, eg md, so long as templates/md contains
    a complete set of templates

>It is possible to specify the template/rendering options with only those templates that
    need to be over-ridden.

## output
    - the path where output is sent
    - default is a directory with the same name as C<rendering33>

## global-links
    - boolean default False
    - if true href links in <a> tags must all be relative to collection (podfile appended to local link)
    - if false links need only be unique relative to Processed


## LICENSE

You can use and distribute this module under the terms of the The Artistic License 2.0. See the LICENSE file included in this distribution for complete details.

The META6.json file of this distribution may be distributed and modified without restrictions or attribution.
