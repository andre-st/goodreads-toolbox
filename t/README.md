# Unit Tests

I just test `lib/Goodscrapes.pm` which is the heart of everything.

My usual design goal is to have very few code in the usecase scripts
and move as much as possible to the libraries (down the stack).
Covering just the libraries is good enough for gaining confidence.

The primary point of testing here, however, is to detect changes 
on the side of the Goodreads markup early.


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



