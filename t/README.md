# Unit tests

## Testing objectives, strategy, coverage

1. Our main reason for testing is the early detection of changes to the
Goodreads.com website that would cause our toolbox to read no or incorrect data.
The GR website is a moving target and should be considered a long-term failure.

2. A _design_ goal of this project is to have very little code in the user scripts 
by moving as much code as possible into the libraries (down the stack).
So covering the libraries in the 'lib'-directory only should cover most fallible code.
This is _good enough_ to gain confidence.

3. User-facing scripts are checked manually when I change them.
If I forget the testing after small changes, at least a static 
check will _automatically_ take place before each commit
(see [../git-hooks/pre-commit](../git-hooks/pre-commit)).

4. All unit-tests _automatically_ run before changes are pushed to the Github repository, 
reducing the chance of distributing a buggy release 
(see [../git-hooks/pre-push](../git-hooks/pre-push)).

5. Tests can serve as tutorial for the Goodscrapes library and reduce 
errors caused by incorrect use.


## Setup

Rename `config.pl-example` to `config.pl` and edit the file. 
Replace the email, pass, user-id values.


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



