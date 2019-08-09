# friendrated.pl

![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)


## Books common among the people you follow

From the _Goodreads Feedback_ forum, 
[Sophie (2013)](https://web.archive.org/web/20190525013028/https://www.goodreads.com/topic/show/1573755-most-popular-books-among-friends) or 
[Anne (2018):](https://web.archive.org/web/20190525012925/https://www.goodreads.com/topic/show/19320371-recommendations)
> I often choose a book to read if many of the people I follow have read it
> (and rated it high). Anyway, to find these kind of books isn't always easy
> especially if they are published many years ago and do not pop up in my news
> feed daily.
> Could Goodreads develop a feature which recommends a book because it is
> common among the people I follow?


## This

![Screenshot](img/friendrated2.png?raw=true "Screenshot")

The report also includes a table with the most liked authors among the friends and followees:

![Screenshot](img/friendrated3.png?raw=true "Screenshot")


## How to generate this on a GNU/Linux operating system

```console
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make        # Required Perl modules from CPAN
$ ./friendrated.pl --help
$ ./friendrated.pl goodlogin@example.com

Enter GR password for goodlogin@example.com: **************
Signing in to Goodreads...
Getting list of members known to #18418712... 164 members (0.18s)
[  0%] Aron Mellendar            #21254511    247 read      94 hits     0.41s
[  1%] Moshe Fiono               #3932835     520 read     126 hits     0.80s
[  2%] Peter Glowwa              #18936366    392 read     148 hits     0.58s
[  3%] DuyGeboad                 #73957929      9 read       0 hits     0.05s
[  3%] Michael                   #9482539      88 read      61 hits     0.15s
[  5%] Peter Prischl             #17272051   1034 read     913 hits     1.47s
[  6%] Steven Shoffork           #51011129     69 read      50 hits     0.15s
[  7%] 2mo                       #32504210     12 read       6 hits     0.07s
...
[ 99%] Charlene                  #2442665    1172 read     732 hits     2.41s
[100%] David                     #7634567     142 read      58 hits     0.01s

Perfect! Got favourites of 164 users.
Writing results to:
./friendrated-1234567-read.html           (271 books)
./friendrated-1234567-read-authors.htmml  (210 authors)

Total time: 18 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days and saves to /tmp/FileCache/.

"0 read 0 hits" is either an empty shelf or a shelf accessible only to friends
of that person (depends on your login).


## Alternative reports

- most _wished-for_ books among the members you follow: use `--toread` option
- most _hated_ books among the members you follow: use `--hated` option


## Observations and limitations

- long runtime: Goodreads slows down all requests and we have to load a lot of data
- books in the upper value range are usually well-known titles, fiction, classics, no surprises
- female GR members mainly read fiction, tend to give 4 and 5 stars pretty generously, 
  and their networks are female
  - start with harsh program settings: min rating of 5 and rated by min 5 followees
- "common authors" tables can be misleading, at the moment:
  it just counts the frequency of a name but does not take into account
  the aggregated ratings of a member for a specific author, example:
  20 members hate 10 books of an author except 1 book.
  the program would count 20x a love relationship for this author,
  although the books in general of this author are more often hated


## Feedback

If you like this project, give it a star on GitHub.
Report bugs or suggestions [via GitHub](https://github.com/andre-st/goodreads/issues) 
or see the [AUTHORS.md](AUTHORS.md) file.


## See also

- ~~[Popular books](https://www.goodreads.com/friend/popular_books) among my friends _this month_ (Goodreads feature)~~
- [likeminded.pl](likeminded.md)   - Find Goodreads members with similar book taste
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [similarauth.pl](similarauth.md) - Find all similar authors
- [search.pl](search.md)           - Sort books-search results by popularity or date published
- [savreviews.pl](savreviews.md)   - Get all reviews of a book
