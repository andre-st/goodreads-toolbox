# search.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Sort Goodreads search results by popularity or date published

From the _Goodreads Feedback_ forum,
[Pawel (2010)](https://www.goodreads.com/topic/show/423469-sorting-search-results)
or [obsessedwithbooks (2013)](https://www.goodreads.com/topic/show/1188302-sort-search-results)
or [Sonja (2016)](https://www.goodreads.com/topic/show/18177911-advanced-search-for-books)
or [Ferouk (2016)](https://www.goodreads.com/topic/show/18084428-we-want-to-find-good-books-fast)
or [David-Emmanuel (2017)](https://www.goodreads.com/topic/show/18541118-better-search)
or [Halordain (2017)](https://www.goodreads.com/topic/show/18496984-sorting-by-average-rating)
or [Kevin (2018)](https://www.goodreads.com/topic/show/19464605-sort-search-results-by-rating):

> I am trying to explore and discover the *best* books. I am not looking
> for the most relevant book. Probably all the books that contain
> "Linux" in the title are relevant to what I'm looking for. I am not
> interested in a particular book's algorithmically-determined
> "relevance score" to my search query. I'm strictly interested in star
> ratings.

In addition to [SL](https://www.goodreads.com/topic/show/19387052-search-needs-improvement)
or [Em__Jay (2015)](https://www.goodreads.com/topic/show/2279173-search-results)
or [Carri (2016)](https://www.goodreads.com/topic/show/18123885-search-functionality)
or [G.H. (2016)](https://www.goodreads.com/topic/show/18034964-search-results)
or [Epper (2016)](https://www.goodreads.com/topic/show/18223264-search-books-filter-results)
or [Shanna_redwind (2016)](https://www.goodreads.com/topic/show/18208444-search-very-frustrating)
or [Lisa (2017)](https://www.goodreads.com/topic/show/19114134-search-fundction-when-looking-for-books)
or [Jenna (2017)](https://www.goodreads.com/topic/show/18901296-please-improve-search-function)
or [Mimi (2018)](https://www.goodreads.com/topic/show/19272652-refined-search)
or [Ian (2016)](https://www.goodreads.com/topic/show/18115612-search-prioritise-exact-matches):

>I kind of wonder if I'm the only one who finds this annoying. If you search
>for a book and type in the title of the book, exact matches to what you type
>are rarely the first listed. 


## This

[![Screenshot](img/search.png?raw=true "Search result for 'Linux'")](https://andre-st.github.io/search-linux.html)


## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make
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
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read
 

