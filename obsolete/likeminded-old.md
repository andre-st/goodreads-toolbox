# likeminded.pl

![Maintenance](https://img.shields.io/maintenance/no/2018.svg)


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
```
Members (N=31398) with 2% similarity or better:
 1.    6 books    2%    https://www.goodreads.com/user/show/1651956
 2.    6 books    2%    https://www.goodreads.com/user/show/70085980
...
34.    9 books    3%    https://www.goodreads.com/user/show/67562484
35.    9 books    3%    https://www.goodreads.com/user/show/655723
36.   10 books    3%    https://www.goodreads.com/user/show/31846270
37.   11 books    3%    https://www.goodreads.com/user/show/30088931
38.   11 books    3%    https://www.goodreads.com/user/show/4100763
39.   11 books    3%    https://www.goodreads.com/user/show/5759543
40.   13 books    4%    https://www.goodreads.com/user/show/34285875
41.   14 books    4%    https://www.goodreads.com/user/show/269235
42.   22 books    7%    https://www.goodreads.com/user/show/71105042
43.   36 books   12%    https://www.goodreads.com/user/show/17281774

```


## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make likeminded
$ ./likeminded.pl YOURGOODUSERNUMBER [OPTIONAL_SHELFNAME_WITH_SELECTED_BOOKS]

Loading books from "ALL" may take a while...
Loading reviews for 299 books:
[  1%] Bärentango: Mit Risikomanagement Projekte zu    300 memb    24.17s
[  1%] Metadata                                         110 memb    10.09s
[  2%] Politik der Mikroentscheidungen: Edward Snowd      7 memb     2.13s
[  2%] Toolbox for the Agile Coach - Visualization       57 memb     9.01s
[  3%] IT-Projektmanagement Kompakt                      24 memb     3.00s
[  3%] Introduction to Mathematical Thinking            300 memb     0.33s
...
[ 98%] Gilgamesch, Graphic Novel                          7 memb     3.01s
[ 99%] Simulation neuronaler Netze                        5 memb     0.50s
[100%] C64 Benutzerhandbuch Deutsch                       1 memb     2.11s

Members (N=31398) with 2% similarity or better:
 1.    6 books    2%    https://www.goodreads.com/user/show/1651956
 2.    6 books    2%    https://www.goodreads.com/user/show/70085980
...
41.   14 books    4%    https://www.goodreads.com/user/show/269235
42.   22 books    7%    https://www.goodreads.com/user/show/71105042
43.   36 books   12%    https://www.goodreads.com/user/show/17281774

Total time: 54 minutes
```


### Note:

You can `^C`-break the script and continue later without having to re-read all
online sources again, as reading from Goodreads.com is very time consuming.
The script internally uses a **file-cache** which is busted after 21 days
and saves to /tmp/FileCache/.

"In common with you" means that your match has at least one of _your_
books in his shelves. So this program checks all of _your_ books and counts 
how often it saw a Goodreads member commenting on any of them: reviews, ratings,
shelf additions etc.


## Observations and serious limitations

- maximum of 300 members per book; this means there is a huge number of readers 
  not considered in our statistics, but 300 is better than nothing; everything else
  requires full access to the Goodreads database or indexing millions of members 
  and books from the outside which would take forever (throttled access)
- there are members with 94.857 ratings, likely bots
- lists members with private accounts (reviews still readable)
- 50% similarity is unrealistic (why?), 3% minimum got me 10 of 31.398 members (299 books),
  with 5 members actually worth investigating, and only 1 already on my list of 137 followees
- your Goodreads account must be viewable by 
  ["anyone (including search engines)"](https://www.goodreads.com/user/edit?tab=settings) 
  which is the default
- slow but good enough since you run it 4x a year
- "...most number of shared books would be a list of children's books"—`likeminded.pl` has a shelf parameter (some sort of selection)


## Considerable alternative implementations

- compare by author, not book (too narrow)
- include ratings: only top-rated on both sides, or similar rating


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## Licence

Creative Commons BY-SA
