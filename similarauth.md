# similarauth.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Finding all similar authors

From the _Goodreads Feedback_ forum, 
[Anne (2018)](https://www.goodreads.com/topic/show/19438988-finding-similar-authors):
> I like Laura Kinsale and Loretta Chase. If I do some digging, I discover that
> I might like Judith Ivory too, because she is on the similar authors list of
> both authors. And if I like Judith Ivory, too, I certainly should try Sherry
> Thomas, because she is on all lists of those three authors



## This

![Screenshot](similarauth.png?raw=true "Screenshot")



## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make similarauth
$ ./similarauth.pl --help
$ ./similarauth.pl YOURGOODUSERNUMBER

Loading books from "ALL" may take a while... 108 books
Loading similar authors for 96 authors:
[  0%] Huhn, Willy               #17326001	  0 similar	  2.56s
[  1%] Gse, Don Murdoch          #8506208	 24 similar	  2.13s
[  2%] Foucault, Michel          #1260		 19 similar	  2.41s
[  3%] Siedersleben, Johannes    #1878894	  0 similar	  1.11s
[  4%] Mattheck, Claus           #1960		  0 similar	  3.27s
[  5%] Dillmann, Renate          #9835498	  0 similar	  1.51s
[  6%] Decker, Peter             #361391	  0 similar	  2.42s
[  7%] Bockelmann, Eske          #6219827	  0 similar	  2.20s
...
[100%] O'Neill, Ryan "Elfmaster" #15065556	  0 similar	  2.43s
Done.
Writing authors (N=360) to "similarauth-18418712.html"...
Total time: 8 minutes
```


**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days and saves to /tmp/FileCache/.



## Observations and limitations

- many authors (in my shelves) have no "similar authors" data on Goodreads
- actual value of this isn't the 'seen' part but just having a long list with
  similar but yet unknown authors



## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read 
- [search.pl](search.pl)           - Sort book-search results by popularity or year

