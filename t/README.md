# Unit Tests

## Strategy, Coverage

This only tests `lib/Goodscrapes.pm` which is the heart of the toolbox.

One design objective in this project is to have very few code in the user scripts
by moving as much code as possible to the libraries (down the stack).
Covering just the libraries should cover most critical code, 
which is _good enough_ for gaining confidence into this project.

The primary reason of testing here, however, is early detecting changes 
on the Goodreads.com website markup.


## Running all tests

```console
$ cd goodreads
$ prove
t/gisxxx.t ........... ok   
t/glogin.t ........... ok   
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



