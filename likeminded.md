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

![Screenshot](likeminded.png?raw=true "Screenshot")



## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make likeminded
$ ./likeminded.pl YOURGOODUSERNUMBER [OPTIONAL_SHELFNAME_WITH_SELECTED_BOOKS]

Loading books from "ALL" may take a while... 108 books
Loading books of 95 authors:
[  1%] Schuberth, Richard         #2793763    6 books    0.03s
[  2%] Lohoff, Ernst              #1339033    4 books    0.05s
[  3%] Huang, Andrew "bunnie"     #2949412    6 books    0.04s
...
[ 97%] Pullum, Laura L.           #476506     2 books    0.05s
[ 98%] Patri, Giacomo             #379757     3 books    0.04s
[100%] Fertl, Herbert L.          #16159494   1 books    0.03s
Done.
Loading reviews for 1625 author books:
[  0%] Psychiatric Power: Lectures at the Coll   #119570      287 memb    0.07s
[  0%] What is an Author?                        #18456429    277 memb    0.05s
[  1%] Aesthetics, Method, and Epistemology      #80386       217 memb    0.03s
...
[ 99%] White Collar                              #3343671      49 memb    0.04s
[ 99%] Gravures Rebelles: 4 Romans Graphiques    #12369034      2 memb    0.00s
[100%] Abweichende Meinungen zu Israel           #33257775      1 memb    0.01s
Done.
Writing members (N=39129) with 5% similarity or better to "likeminded-18418712.html"...
Total time: 54 minutes
```


### Note:

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later without having to re-read all
online sources again, as reading from Goodreads.com is very time consuming.
The script internally uses a **file-cache** which is busted after 21 days
and saves to /tmp/FileCache/.



## Observations and serious limitations

- maximum of 300 members per book; this means there is a huge number of readers 
  not considered in our statistics, but 300 is better than nothing; everything else
  requires full access to the Goodreads database or indexing millions of members 
  and books from the outside which would take forever (throttled access)
- there are members with 94.857 ratings, likely bots
- lists members with private accounts (reviews still readable)
- your Goodreads account must be viewable by 
  ["anyone (including search engines)"](https://www.goodreads.com/user/edit?tab=settings) 
  which is the default
- slow but good enough since you run it 4x a year
- "_...most number of shared books would be a list of children's books_"—`likeminded.pl` has a shelf parameter (sort of selection)

**First version compared books, not authors:**
- turned out to be too narrow in order to produce satisfying results
- given 299 books and a minimum of 9 _common_ books (3% similarity), 
  I've got 10 of 31.398 members,
  with 5 members actually worth investigating, 
  and only 1 member already on my hand-curated list of 137 followees
- a minimum of 6 common books (2%) listed 43 members, more or less interesting
- we learn: book combinations tend to become unique quickly
- the new authors-version takes longer but yields better results, e.g.,
  more matches with my hand-curated followees list


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## Licence

Creative Commons BY-SA


## See also

- [friendrated.pl](friendrated.md) - Books common among the people I follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book


