# likeminded.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Finding people based on the books they've read

From the _Goodreads Feedback_ forum, 
[Linda (2010)](https://www.goodreads.com/topic/show/298531-is-there-an-option-to-do-a-general-search-for-people-with-similar-readin)
or [Michael (2013)](https://www.goodreads.com/topic/show/1619830-finding-friends-using-compare-books)
or [Wren (2014)](https://www.goodreads.com/topic/show/1790589-what-if-there-was-a-recommended-friends-feature) 
or [Kara (2015)](https://www.goodreads.com/topic/show/17019858-compare-books-suggestion)
or [Samantha (2016)](https://www.goodreads.com/topic/show/18167287-users-like-you-feature-suggestion)
or [Jacob (2017)](https://www.goodreads.com/topic/show/18433578-find-me-a-friend-with-same-taste-for-books)
or [Superbunny (2018)](https://www.goodreads.com/topic/show/19361289-searching-others-with-similar-taste-to-mine)
or [Marc (2018)](https://www.goodreads.com/topic/show/19252693-new-suggestion-to-find-like-minded-people)
or [Mehran (2018)](https://www.goodreads.com/topic/show/19397936-finding-people-based-on-the-books-they-ve-read):
> Is there a way to search for people who have read books X, Y, and Z? Or maybe
> a way for you to find people who have many books in common with you, without
> going through people manually? If such features don't exist, Goodreads should
> definitely add them. They can provoke many conversations among people who have
> similar tastes in books. 



## This

![Screenshot](img/likeminded.png?raw=true "Screenshot")



## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make
$ ./likeminded.pl --help
$ ./likeminded.pl YOURGOODUSERNUMBER

Loading books from "ALL" may take a while... 108 books
Loading books of 95 authors:
[  1%] Schuberth, Richard         #2793763    6 books    1.03s
[  2%] Lohoff, Ernst              #1339033    4 books    1.05s
[  3%] Huang, Andrew "bunnie"     #2949412    6 books    1.04s
[  4%] Pullum, Laura L.           #476506     2 books    1.05s
[  5%] Patri, Giacomo             #379757     3 books    1.04s
...
[100%] Fertl, Herbert L.          #16159494   1 books    1.03s
Done.
Loading reviews for 1625 author books:
[  0%] First as Tragedy, Then as Farce           #6636487    2278 memb     134.20s
[  0%] The Parallax View                         #18910      1039 memb      66.35s
[  0%] The Year of Dreaming Dangerously          #15901602    949 memb      50.08s
[  0%] Descriptive Check List: Together With Sh  #6517166       0 memb       1.41s
[  0%] Old Fences, New Neighbors                 #17461487      0 memb       1.13s
[  0%] Little Brother (Little Brother, #1)       #25547383   5885 memb     324.83s
[  0%] The Hardware Hacker: Adventures in Makin  #30804383    219 memb      11.25s
[  0%] Hacking the Xbox: An Introduction to Rev  #984394      206 memb      10.26s
[  1%] The Essential Guide to Electronics in Sh  #33401673     27 memb       1.11s
[  1%] The Sublime Object of Ideology            #18912      2229 memb      69.87s
...
[100%] Maker Pro: Essays on Making a Living as   #24214717     33 memb       1.09s
Done.
Writing members (N=39129) with 5% similarity or better to "likeminded-18418712.html"...
Total time: 274 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days and saves to /tmp/FileCache/.



## Observations and limitations

**Latest version:**
- loading data could take a month with too many books: Prefer a separate "best-of" shelf
  (with 100 representative books) over the "All" or "Read" shelves.
  You can specify multiple shelves in a single run (--shelf parameter).
- the more popular your literature, the longer the program's runtime and the 
  more questionable its results (too generic, many unseen reviewers) - or: 
  add good but rare books to your "best-of" shelf
- make sure you have some _Gigabytes_ of free diskspace for /tmp/
- there's no way to load _all_ reviews of a book, but the program tries different 
  things to get as many reviews as possible.
  This means there is a number of readers not considered in our statistics,
  and we cannot randomize in a way which would produce samples of similar size.
  Although, we don't get _all_ members (for books with ten of thousand
  reviews), the final report still contains _enough_ members who read the 
  same N authors
- there are members with 94.857 ratings, likely bots
- lists members with private accounts
- slow but good enough since you run it 4x a year
- your Goodreads account must be viewable by 
  ["anyone (including search engines)"](https://www.goodreads.com/user/edit?tab=settings) 
  which is the default (alternatively try --cookie parameter)
- "_...most number of shared books would be a list of children's books_"—`likeminded.pl` has a shelf parameter (sort of selection)

**First version compared books, not authors:**
- turned out to be too narrow in order to produce satisfying results
- given 299 books and a minimum of 9 _common_ books (3% similarity), 
  I've got 10 of 31.398 members,
  with 5 members actually worth investigating, 
  and only 1 member already on my hand-curated list of 137 followees
- a minimum of 6 common books (2%) listed 43 members, more or less interesting
- we learn: book combinations tend to become unique quickly
- combinations of same books are more rare than combinations of same authors, while latter still satisfies the 'same taste' condition (assumption with books is that likeminded people have the same exposure to the same books, but that's questionable and comparing the _authors_ relaxes or widens this assumption)
- the new authors-version takes longer but yields better results, e.g.,
  more matches with my hand-curated followees list


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [search.pl](search.md)           - Sort books-search results by popularity or date published
