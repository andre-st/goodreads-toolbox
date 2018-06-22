# André's Goodreads Toolbox

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)

[Goodreads.com](http://www.goodreads.com/) is the world largest book community 
and a tools provider for web-based (home-)library management.


## [recentrated.pl](recentrated.md)

Checks all the books in a Goodreads.com shelf for new ratings and notifies you
via e-mail. This helps discover new users with quality libraries.
You can [subscribe there](https://andre-st.github.io/goodreads/) if you don't
want to install anything.
It's a poor man's solution to the "follow book" feature request in the Goodreads forums. 
[Learn more](recentrated.md)


## [friendrated.pl](friendrated.md)

Prints all books which have been rated 4 or 5 stars by 3 or more persons you
follow (including friends). It's a poor man's solution to the "books common
among the people I follow" feature request in the Goodreads forums.
[Learn more](friendrated.md)


## [likeminded.pl](likeminded.md)

Prints Goodreads members who are interested in the same books as you.
It's a poor man's solution to the "Finding people based on the books they've read"
feature request in the Goodreads forums.
[Learn more](likeminded.md)


## ~~[amz-tradein.pl](amz-tradein.md)~~

This script fetched Amazon Trade-In prices for all books in a Goodreads.com
shelf ("resales" or "donations"). It automated regular manual bid-checking for 
hundreds of books, discovering sales opportunities. Amazon stopped its buyback 
program in 2015.
[Learn more](amz-tradein.md)


### www/

Static webpages that I use to offer [this software as a service](https://andre-st.github.io/goodreads/) 
to people who don't know Linux etc. You probably won't need this directory.



## further reading 

- [A few things](GOODTIPS.md) that improved my Goodreads experience: settings, browser extensions etc.


## suggestions

- all the books by a certain author that (friends of) your friends have read ([Simon](https://www.goodreads.com/topic/show/757601-find-out-all-the-books-by-a-certain-author-that-your-friends-have-read))


## modest remark

These programs are never as performant and usable as native Goodreads solutions
with direct _unthrottled_ access to their databases and seamless integration 
with their user interface etc. 
I avoid developing features I won’t personally use because I won’t notice when they break.
I only unit-test the base library.
