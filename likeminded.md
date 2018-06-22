# likeminded.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Finding people based on the books they've read

From the _Goodreads Feedback_ forum, [Mehran](https://www.goodreads.com/topic/show/19397936-finding-people-based-on-the-books-they-ve-read) 
> Is there a way to search for people who have read books X, Y, and Z? Or maybe
> a way for you to find people who have many books in common with you, without
> going through people manually? If such features don't exist, Goodreads should
> definitely add them. They can provoke many conversations among people who have
> similar tastes in books. 



## This
```
Members (N=20237) with 3% similarity or better:
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
[  1%] Bärentango: Mit Risikomanagement Projekte zu     300 memb    24.00s
[  1%] Metadata                                         110 memb    10.00s
[  2%] Politik der Mikroentscheidungen: Edward Snowd      7 memb     2.00s
[  2%] Toolbox for the Agile Coach - Visualization       57 memb     9.00s
[  3%] IT-Projektmanagement Kompakt                      24 memb     3.00s
[  3%] Introduction to Mathematical Thinking            300 memb     0.00s
...
[ 98%] Gilgamesch, Graphic Novel                          7 memb     3.00s
[ 99%] Simulation neuronaler Netze                        5 memb     0.00s
[100%] C64 Benutzerhandbuch Deutsch                       1 memb     2.00s

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
  requires full access to the Goodreads database or indexing millions of books from
  the outside which would take forever
- there are members with 94.857 ratings, likely bots
- lists members with private accounts (reviews still readable)
- 50% similarity is unrealistic (why?), 3% minimum got me 10 of 31.398 members (299 books),
  with 5 members actually worth investigating
- your Goodreads account must be viewable by 
  ["anyone (including search engines)"](https://www.goodreads.com/user/edit?tab=settings) (default)
- program is slow (throttled, no botnet with numerous IP addresses) but 
  [good enough(tm)](https://en.wikipedia.org/wiki/Principle_of_good_enough) since you run it 4x a year



## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## Licence

Creative Commons BY-SA
