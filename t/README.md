# Unit Tests

## Objectives, Strategy, Coverage

The main reason for testing is the early detection of changes to the
Goodreads.com website that would cause our toolbox to read no or incorrect data.

A _design_ goal in this project is to have very little code in the user scripts 
by moving as much code as possible into the libraries (down the stack).
Covering only the libraries should cover the most critical code.
That's _good enough_ to gain confidence.

Currently, this only tests `lib/Goodscrapes.pm` which is the heart of the toolbox.

I run all tests before pushing local changes to the Github repository, 
reducing the chance of distributing buggy releases.

Tests can also serve as tutorial for the Goodscrapes library and reduce 
errors caused by incorrect use.

## Running all tests

```console
$ cd goodreads
$ prove
t/gisxxx.t ........... ok   
t/glogin.t ........... ok   
t/gmeter.t ........... ok   
t/greadauthorbk.t .... ok   
t/greadauthors.t ..... ok   
t/greadbook.t ........ ok   
t/greadfolls.t ....... ok   
t/greadreviews.t ..... ok   
t/greadshelf.t ....... ok    
t/greadsimilaraut.t .. ok   
t/greaduser.t ........ ok   
t/greadusergrp.t ..... ok   
t/gsearch.t .......... ok    
t/gverifyxxx.t ....... ok   
All tests successful.
Files=13, Tests=53, 11 wallclock secs ( 0.16 usr  0.03 sys +  9.75 cusr  0.48 csys = 10.42 CPU)
Result: PASS
```



