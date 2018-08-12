# search.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Sorting Goodreads search results by popularity or year

From the _Goodreads Feedback_ forum,
[Kevin](https://www.goodreads.com/topic/show/19464605-sort-search-results-by-rating)
or [Ferouk](https://www.goodreads.com/topic/show/18084428-we-want-to-find-good-books-fast)
or [Sonja](https://www.goodreads.com/topic/show/18177911-advanced-search-for-books)
or [Pawel](https://www.goodreads.com/topic/show/423469-sorting-search-results)
or [David-Emmanuel](https://www.goodreads.com/topic/show/18541118-better-search)
or [Halordain](https://www.goodreads.com/topic/show/18496984-sorting-by-average-rating)
or [obsessedwithbooks](https://www.goodreads.com/topic/show/1188302-sort-search-results):

> This seems to be a simple and straightforward feature to have so I its baffling
> to me why GoodReads does not allow one to sort search results. Specifically, if
> I am searching books by on specific author I want to sort the books to see
> which books have the highest rating. Please consider adding a Sort By drop down
> menu to sort alphabetically, by rating, relevancy, etc.


In addition to [SL](https://www.goodreads.com/topic/show/19387052-search-needs-improvement)
or [Carri](https://www.goodreads.com/topic/show/18123885-search-functionality)
or [Epper](https://www.goodreads.com/topic/show/18223264-search-books-filter-results)
or [Mimi](https://www.goodreads.com/topic/show/19272652-refined-search)
or [G.H.](https://www.goodreads.com/topic/show/18034964-search-results)
or [Lisa](https://www.goodreads.com/topic/show/19114134-search-fundction-when-looking-for-books)
or [Shanna_redwind](https://www.goodreads.com/topic/show/18208444-search-very-frustrating)
or [Em__Jay](https://www.goodreads.com/topic/show/2279173-search-results?comment=117130606#comment_117130606)
or [Jenna](https://www.goodreads.com/topic/show/18901296-please-improve-search-function)
or [Ian](https://www.goodreads.com/topic/show/18115612-search-prioritise-exact-matches):

>I kind of wonder if I'm the only one who finds this annoying. If you search
>for a book and type in the title of the book, exact matches to what you type
>are rarely the first listed. 


## This

![Screenshot](search.png?raw=true "Screenshot")


## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make search
$ ./search.pl --help
$ ./search.pl YOURKEYWORD

Searching books:

 about..... YOURKEYWORD
 rated by.. 5 members or more
 order by.. stars, num_ratings, year
 progress.. 100%

Writing search result (N=275) to "search-YOURKEYWORD.html"... 
Total time: 3 minutes
```


## Observations and limitations

- [GIGO](https://en.wikipedia.org/wiki/Garbage_in,_garbage_out)


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read
 

