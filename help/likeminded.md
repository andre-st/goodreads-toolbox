# likeminded.pl

![Maintenance](https://img.shields.io/maintenance/no/2022.svg)


## Finding people based on the books they've read

From the _Goodreads Feedback_ forum, 
[Linda (2010)](https://web.archive.org/web/20170427072407/http://www.goodreads.com/topic/show/298531-is-there-an-option-to-do-a-general-search-for-people-with-similar-readin)
or [Michael (2013)](https://web.archive.org/web/20190525014022/https://www.goodreads.com/topic/show/1619830-finding-friends-using-compare-books)
or [Wren (2014)](https://web.archive.org/web/20190525013926/https://www.goodreads.com/topic/show/1790589-what-if-there-was-a-recommended-friends-feature) 
or [Kara (2015)](https://web.archive.org/web/20190525013835/https://www.goodreads.com/topic/show/17019858-compare-books-suggestion)
or [Samantha (2016)](https://web.archive.org/web/20190525013741/https://www.goodreads.com/topic/show/18167287-users-like-you-feature-suggestion)
or [Jacob (2017)](https://web.archive.org/web/20190525013655/https://www.goodreads.com/topic/show/18433578-find-me-a-friend-with-same-taste-for-books)
or [Superbunny (2018)](https://web.archive.org/web/20190525013600/https://www.goodreads.com/topic/show/19361289-searching-others-with-similar-taste-to-mine)
or [Marc (2018)](https://web.archive.org/web/20190525013501/https://www.goodreads.com/topic/show/19252693-new-suggestion-to-find-like-minded-people)
or [Anna (2019)](https://help.goodreads.com/s/question/0D51H00004AEWwNSAX/is-there-a-way-to-find-people-who-have-similar-tastes-in-books-i-like-so-i-can-follow-them)
or [Mehran](https://web.archive.org/web/20190525013406/https://www.goodreads.com/topic/show/19397936-finding-people-based-on-the-books-they-ve-read):
> Is there a way to search for people who have read books X, Y, and Z? Or maybe
> a way for you to find people who have many books in common with you, without
> going through people manually? If such features don't exist, Goodreads should
> definitely add them. They can provoke many conversations among people who have
> similar tastes in books. 



## This

![Screenshot](img/likeminded.png?raw=true "Screenshot")



## How to generate this on a GNU/Linux operating system

1. [Install the toolbox](../README.md#Getting-started)
2. at the prompt, enter:
```console
$ ./likeminded.pl --help
$ ./likeminded.pl goodlogin@example.com

Enter GR password for goodlogin@example.com: ******************
Signing in to Goodreads... OK
Loading authors from "ALL" may take a while... 95 authors
Loading books of 95 authors:
[  1%] Schuberth, Richard         #2793763    6 books    1.03s
[  2%] Lohoff, Ernst              #1339033    4 books    1.05s
[  3%] Huang, Andrew "bunnie"     #2949412    6 books    1.04s
[  4%] Pullum, Laura L.           #476506     2 books    1.05s
[  5%] Patri, Giacomo             #379757     3 books    1.04s
...
[100%] Fertl, Herbert L.          #16159494   1 books    1.03s
Done.
Loading readers of 1625 author books:
[  0%] First as Tragedy, Then as Farce           #6636487    2278 memb    134.20s
[  0%] Descriptive Check List: Together With     #6517166       0 memb      1.41s
[  0%] Little Brother (Little Brother, #1)       #25547383   5885 memb    324.83s
[  0%] The Hardware Hacker: Adventures in Ma     #30804383    219 memb     11.25s
[  1%] Hacking the Xbox: An Introduction to      #984394      206 memb     10.26s
...
[100%] Maker Pro Essays on Making a Living a     #24214717     33 memb      1.09s
Done.
Dropping who read less than 5% of your authors... -20205 memb (99.998%)
Loading profiles of the remaining 420 members:
[  0%] goodreads.com/user/show/120456      1.21s     *
[  1%] goodreads.com/user/show/65482       2.10s     ****
[  1%] goodreads.com/user/show/45763483    0.90s
[  2%] goodreads.com/user/show/773911      2.23s     private account
[  2%] goodreads.com/user/show/1031286     3.01s
...
[100%] goodreads.com/user/show/818022      1.01s     **
Done.
Writing report (N=399) to "./list-out/likeminded-18418712.html"...
Total time: 294 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
file-cache which saves to /tmp/FileCache/.
The program is designed to run unattended, outwaits connection issues etc.


## Observations and limitations

#### Latest version:
- long runtime: Goodreads slows down all requests and we have to load a lot of data
- loading data could take a month given too many books
- prefer loading from a separate _"best-of"_ shelf:
	- use the program's `--shelf` option, avoid _"All"_ or _"Read"_ shelves
	- add _100_ good but rare books (&lt;5000 ratings)
	- the more popular your literature, the longer the program's runtime
	- the more popular your lit, the more generic the results (500 million sales of Harry Potter)
	- the more popular your lit, the less likely we detect reoccuring members (we cannot see all readers)
	- you can add books to your shelf more quickly in Goodreads' [batch edit](https://2.bp.blogspot.com/-MBcqYj2mK_I/UsyW06AX43I/AAAAAAAAEdE/5V5z2_XJaCI/s1600/Step+1&2.jpg) mode   
	- alternatively load from multiple smaller shelves: 
	  `./likeminded.pl --shelf=nonfiction --shelf=poetry ...`
- make sure you have some _Gigabytes_ of free diskspace in `/tmp/`: 
	- my last test run with 356 books filled 11 GB in ~24 hours (many small files)
- there's no way to get _all_ readers of a book:
	- the program tries different things to get as many as possible
	- you can tune this with the `--rigor` program option (increases runtime)
	- there is a number of readers not considered in our statistics
	- we cannot randomize in a way which would produce samples of similar size
	- although, we don't get _all_ readers (for books with ten of thousand readers), 
	  the final report still contains _enough_ members who read the same N authors
- does _not_ list members with private accounts anymore
- slow but good enough; you won't run it more often than 4x a year
- _"...most number of shared books would be a list of children's books"_ 
	- exclude them by passing one or many `--shelf` arguments to the program


#### Library sizes as ranking factor:
- there are members with many common authors just because they have huge libraries
- there are members with 94.857 ratings, likely bots
- in a previous program version,
  a member with 11 common authors and 3000 books in total was shown earlier than
  a member with 10 common authors and  300 books in total, 
  although the latter one is probably more "like-minded"
- getting the library sizes requires an additional profiles loading stage
	- increased runtime is accepted as weeding out members
	  by hand takes even longer


#### First version compared books, not authors:
- turned out to be too narrow in order to produce satisfying results
- given 299 books and a minimum of 9 _common_ books (3% similarity), 
  I've got 10 of 31.398 members,
  with 5 members actually worth investigating, 
  and only 1 member already on my hand-curated list of 137 followees
- a minimum of 6 common books (2%) listed 43 members, more or less interesting
- we learn: book combinations tend to become unique quickly
- combinations of same books are more rare than combinations of same authors, 
  while latter still satisfies the 'same taste' condition 
  (the assumption with 'same books' is that likeminded people had the same exposure to the exact same books, but that's questionable - and comparing the _authors_ relaxes this assumption)
- the new authors-version takes longer but yields better results, e.g.,
  more matches with my hand-curated followees list
	- try program argument `--maxauthorbooks=50` to reduce runtime (checks max. 50 books per author)
  

#### Alternatives to consider:
- _"I look for people who __dislike__ the same books that I do. I don't have a problem finding books to read. What I need is someone who can warn me about the books that everyone else seems to love."_
- current results based on stuff you already liked, model the past as identical to the future, based on who you are/were not who you want or could become (stuff that's out of your current wheelhouse but still has likeable features)
- maybe recommendations from our to-read lists are more interesting/up-to-date than our read-lists


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
- [search.pl](search.md)           - Sort books-search results by popularity or date published
- [savreviews.pl](savreviews.md)   - Get all reviews of a book

