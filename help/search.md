# search.pl

![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)


## Sort Goodreads search results by popularity or date published

From the _Goodreads Feedback_ forum,
[Pawel (2010)](https://web.archive.org/web/20190525015116/https://www.goodreads.com/topic/show/423469-sorting-search-results)
or [obsessedwithbooks (2013)](https://web.archive.org/web/20190525015022/https://www.goodreads.com/topic/show/1188302-sort-search-results)
or [Sonja (2016)](https://web.archive.org/web/20190525014930/https://www.goodreads.com/topic/show/18177911-advanced-search-for-books)
or [Ferouk (2016)](https://web.archive.org/web/20190525014842/https://www.goodreads.com/topic/show/18084428-we-want-to-find-good-books-fast)
or [David-Emmanuel (2017)](https://web.archive.org/web/20190525014755/https://www.goodreads.com/topic/show/18541118-better-search)
or [Halordain (2017)](https://web.archive.org/web/20190525014643/https://www.goodreads.com/topic/show/18496984-sorting-by-average-rating)
or [Kevin (2018)](https://web.archive.org/web/20190525014542/https://www.goodreads.com/topic/show/19464605-sort-search-results-by-rating):

> I am trying to explore and discover the *best* books. I am not looking
> for the most relevant book. Probably all the books that contain
> "Linux" in the title are relevant to what I'm looking for. I am not
> interested in a particular book's algorithmically-determined
> "relevance score" to my search query. I'm strictly interested in star
> ratings.

In addition to [Em__Jay (2015)](https://web.archive.org/web/20190525015950/https://www.goodreads.com/topic/show/2279173-search-results)
or [Carri (2016)](https://web.archive.org/web/20190525015857/https://www.goodreads.com/topic/show/18123885-search-functionality)
or [G.H. (2016)](https://web.archive.org/web/20190525015818/https://www.goodreads.com/topic/show/18034964-search-results)
or [Epper (2016)](https://web.archive.org/web/20190525015727/https://www.goodreads.com/topic/show/18223264-search-books-filter-results)
or [Shanna_redwind (2016)](https://web.archive.org/web/20190525015634/https://www.goodreads.com/topic/show/18208444-search-very-frustrating)
or [Lisa (2017)](https://web.archive.org/web/20190525015546/https://www.goodreads.com/topic/show/19114134-search-fundction-when-looking-for-books)
or [Jenna (2017)](https://web.archive.org/web/20190525015501/https://www.goodreads.com/topic/show/18901296-please-improve-search-function)
or [SL (2018)](https://web.archive.org/web/20190525020028/https://www.goodreads.com/topic/show/19387052-search-needs-improvement)
or [Mimi (2018)](https://web.archive.org/web/20190525015405/https://www.goodreads.com/topic/show/19272652-refined-search)
or [Ian (2016)](https://web.archive.org/web/20190525015312/https://www.goodreads.com/topic/show/18115612-search-prioritise-exact-matches):

>I kind of wonder if I'm the only one who finds this annoying. If you search
>for a book and type in the title of the book, exact matches to what you type
>are rarely the first listed. 


## This

[![Screenshot](img/search.png?raw=true "Search result for 'Linux'")](https://andre-st.github.io/search-linux.html)


## How to generate this on a GNU/Linux operating system

1. [Install the toolbox](../README.md#Getting-started)
2. at the prompt, enter:

```console
$ ./search.pl --help
$ ./search.pl YOURKEYWORD

Searching books:

 about..... YOURKEYWORD
 rated by.. 5 members or more
 order by.. stars, num_ratings, year
 progress.. 100%

Writing search result (N=275) to "./list-out/search-YOURKEYWORD.html"... 
Total time: 3 minutes
```


## Observations and limitations

- long runtime: Goodreads slows down all requests and we have to load a lot of data
- start the program with defaults and re-run to fine-tune with parameters later (previously downloaded resources are reused so it's faster than the first run); you might not know how many ratings actually exists, if `--ratings` is too high you will not get any results (`N=0`)
- [garbage in, garbage out](https://en.wikipedia.org/wiki/Garbage_in,_garbage_out)


## Feedback

If you like this project, give it a star on GitHub.
Report bugs or suggestions [via GitHub](https://github.com/andre-st/goodreads-toolbox/issues) 
or see the [AUTHORS.md](../AUTHORS.md) file.


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [friendnet.pl](friendnet.md)     - Social network analysis
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read
- [savreviews.pl](savreviews.md)   - Get all reviews of a book


