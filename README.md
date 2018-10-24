# Pod::Render

Render pod from cached pod created by Pod::Cached

## Install

This module is in the [Perl 6 ecosystem](https://modules.perl6.org), so you install it in the usual way:

    zef install Pod::Render


# SYNOPSIS
```perl6
use Pod::Render;

my Pod::Render $cache .= new(:path<path-to-cache>);

for $cache.files -> $filename, %info {
    given %info<status> {
        when 'OK' {say "$filename has valid cached pod"}
        when 'Updated' {say "$filename has valid pod, just updated"}
        when 'Tainted' {say "$filename has been modified since the cache was last updated"}
        when 'Failed' {say "$filename has been modified, but contains invalid pod"}
    }
    some-routine-for-processing pod( $cache.pod( $filename ) );
}
```

- Str $!path = 'pod-cache'
    path to the directory where the cache will be created/kept

- verbose = True
    Whether processing information is sent to stderr.

- new
    Instantiates class. On instantiation, the module verifies that
        - the cache is valid

- files
    public attribute
    a hash of filenames with keys
        - `status` One of 'OK', 'Tainted', 'Updated', 'Failed'
        -  `cache-key` the key needed to access the compunit cache
        - `handle` the cache handle
        -  `path` the path to the pod file

- pod
    method pod(Str $filename:D )
    Returns the Pod Object Module generated from the file with the filename.

TBContinued

## LICENSE

You can use and distribute this module under the terms of the The Artistic License 2.0. See the LICENSE file included in this distribution for complete details.

The META6.json file of this distribution may be distributed and modified without restrictions or attribution.
