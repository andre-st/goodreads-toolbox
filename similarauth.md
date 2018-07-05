# likeminded.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Finding _all_ similar authors

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
$ ./likeminded.pl YOURGOODUSERNUMBER [OPTIONAL_SHELFNAME_WITH_SELECTED_BOOKS]

Loading books from "ALL" may take a while... 108 books
Loading similar authors for 96 authors:
[  0%] Huhn, Willy               #17326001	  0 similar	  0.00s
[  1%] Gse, Don Murdoch          #8506208	 24 similar	  0.00s
[  2%] Foucault, Michel          #1260		 19 similar	  0.00s
[  3%] Siedersleben, Johannes    #1878894	  0 similar	  0.00s
[  4%] Mattheck, Claus           #1960		  0 similar	  0.00s
[  5%] Dillmann, Renate          #9835498	  0 similar	  0.00s
[  6%] Decker, Peter             #361391	  0 similar	  0.00s
[  7%] Bockelmann, Eske          #6219827	  0 similar	  0.00s
[  8%] Sanglard, Fabien          #7456185	  0 similar	  0.00s
[  9%] Kraft, Philip             #1180805	  0 similar	  0.00s
[ 10%] Koop, Andreas             #4166708	  0 similar	  0.00s
[ 11%] Gerrard, Paul             #3170891	  0 similar	  0.00s
[ 12%] Zinsmeister, Annett       #5828020	  0 similar	  0.00s
...
[ 99%] Rubinštejn, Alexander N. #9879051	  0 similar	  0.00s
[100%] O'Neill, Ryan "Elfmaster" #15065556	  0 similar	  0.00s
Done.
Writing authors (N=360) to "similarauth-18418712.html"...
Total time: 8 minutes
```


**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later without having to re-read all
online sources again, as reading from Goodreads.com is very time consuming.
The script internally uses a **file-cache** which is busted after 21 days
and saves to /tmp/FileCache/.



## Observations and serious limitations

- many authors (in my shelf) have no similar authors (data from Goodreads)



## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [friendrated.pl](friendrated.md) - Books common among the people I follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read 


