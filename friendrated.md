# friendrated.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Books common among the people I follow

From the _Goodreads Feedback_ forum, [Sophie (2013)](https://www.goodreads.com/topic/show/1573755-most-popular-books-among-friends?page=1) or [Anne (2018):](https://www.goodreads.com/topic/show/19320371-recommendations)
> I often choose a book to read if many of the people I follow have read it
> (and rated it high). Anyway, to find these kind of books isn't always easy
> especially if they are published many years ago and do not pop up in my news
> feed daily.
> Could Goodreads develop a feature which recommends a book because it is
> common among the people I follow?


## This

![Screenshot](friendrated.png?raw=true "Screenshot")


## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make friendrated
$ ./friendrated.pl --help
$ ./friendrated.pl YOURGOODUSERNUMBER

Getting list of users known to #18418712... 164 users (0.18s)
[  0%] Aron Mellendar            #21254511    247 read      94 favs     0.41s
[  1%] Moshe Fiono               #3932835     520 read     126 favs     0.80s
[  2%] Peter Glowwa              #18936366    392 read     148 favs     0.58s
[  3%] DuyGeboad                 #73957929      9 read       0 favs     0.05s
[  3%] Michael                   #9482539      88 read      61 favs     0.15s
[  5%] Peter Prischl             #17272051   1034 read     913 favs     1.47s
[  6%] Steven Shoffork           #51011129     69 read      50 favs     0.15s
[  7%] 2mo                       #32504210     12 read       6 favs     0.07s
...
[ 99%] Charlene                  #2442665    1172 read     732 favs     2.41s
[100%] David                     #7634567     142 read      58 favs     0.01s

Perfect! Got favourites of 164 users.
Writing results to "friendrated-1234567.html"... 271 books (0.31s)
Total time: 18 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days (--cache parameter) and saves to
/tmp/FileCache/.

You will need to save your Goodreads cookie to the dotfile `.cookie` in the
project directory.  I use Chrome's DevTools Network-view to [copy the cookie
content](https://www.youtube.com/watch?v=o_CYdZBPDCg).

"0 read 0 favs" is either an empty shelf or a shelf accessible only to friends
of that person (depends on used cookie).


## Observations

- books in the upper value range are usually well-known titles, fiction, classics, no surprises
- female GR members mainly read fiction, tend to give 4 and 5 stars pretty generously, and their networks are female
  - start with harsh program settings: min rating of 5 and rated by min 5 followees


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [likeminded.pl](likeminded.md) - Find Goodreads members with similar book taste
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
