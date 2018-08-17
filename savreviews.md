# savreviews.md

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Download all reviews for a book, e.g., for sentiment analysis

From the _Goodreads Feedback_ forum, 
[Breslin (2018)](https://www.goodreads.com/topic/show/19484417-increase-the-visible-number-of-ratings-of-a-book)
or [Giulia (2018)](https://www.goodreads.com/topic/show/19477061-how-can-i-extract-all-reviews-full-text-for-a-specific-book):

> I simply need to obtain all (or as many) reviews for two books, namely
> Woolf's To the Lighthouse and Mrs Dalloway, so that i can then analyse
> the corpus obtained from them and see if readers define the two novels
> as "difficult".


## Output format
```
$ cat savreviews-8882222.txt

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

-------------------------------------------------------------------------------

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat. 

-------------------------------------------------------------------------------

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi
```

**Note:**

The generated files contain review-texts only. They do not contain any other
information, e.g., user names, datetime of a review, stars-rating etc.



## How to generate this on a GNU/Linux operating system

```
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make savreviews
$ ./savreviews.pl --help
$ ./savreviews.pl GOODREADSBOOKID

Loading reviews for "To the Lighthouse"... 4962 of 5514 reviews
Writing reviews to "savreviews-GOODREADSBOOKID.txt"... 
Total time: 87 minutes

```


## Observations and limitations

- there's no way to load _all_ reviews of a book, but the program 
  [tries different things](dict/README.md) to get as many reviews as 
  possible -- this can take very long
- review text might include HTML code, URLs
- review text can be in any language, e.g., german or russian
- review text might include non-latin characters, e.g., cyrillic
- no duplicate reviewers, but could theoretically contain duplicate 
  reviews posted by different members (needs data cleansing)


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [likeminded.pl](likeminded.md)   - Finding people based on the books they've read
 

