# Dictionaries

## Purpose

As far as the reviews are concerned, the official Goodreads API typically gets you a maximum of 300 
short _excerpts_ ([here](https://www.goodreads.com/topic/show/19512142-how-to-get-whole-body-of-book-review), 
[here](https://www.goodreads.com/topic/show/12070102-review-is-truncated?comment=130838734#comment_130838734)
or [here](https://www.goodreads.com/topic/show/19455087-unable-to-get-book-reviews-by-book-id?comment=182375978#comment_182375978)). Goodreads does not use this API on its own website, it is a side project. 
They use other mechanisms to display reviews on their website, mechanisms that
are used by the _Toolbox_ programs too ([AJAX](https://en.wikipedia.org/wiki/Ajax_(programming)) endpoints in this case). 
These mechanisms have their own limitations: you can not see all reviews, 
but search a book's reviews by a keyword and/or filter by the number of stars, age etc.
Toolbox programs such as [savreviews.pl](../savreviews.md) or [likeminded.pl](../likeminded.md) 
use filters and also run a dictionary against this search in order to collect reviews.


## Results

| Dictionary              | Lines | Minutes | "To the Lighthouse"<br>5514 text reviews | "Mrs Dalloway"<br>7376 text reviews |
|:------------------------|------:|--------:|-------------:|--------------:|
| _none (filters only)_   |     - |         |  948 or 17%  |   _untested_
| gram-en-l.lst           |  3349 |     111 | 3057 or 55%  |   _untested_
| gram-en-s.lst           |   390 |         |   _untested_ |   _untested_
| word-en-l.lst           |  1000 |      33 | 4962 or 90%  | 6413 or 87%
| word-en-s.lst           |   114 |         |   _untested_ |   _untested_
| gram-en-s,word-en-l.lst |  1390 |         |   _untested_ |   _untested_
| gram-en-l,word-en-l.lst |  4349 |     144 | 5127 or 93%  | 6715 or 91%

No duplicate reviewers, but could theoretically contain duplicate reviews
posted by different members, which would be counted by Goodreads too.

    
## Naming Conventions

File names: `${TYPE4LETTERCODE}-${LANGUAGE2LETTERCODE}-${SIZE}.lst` with 
size `l` meaning large dictionaries, `s` meaning small dictionaries and file
extension `lst` meaning "list". Lists are ASCII files with one word per line.
Comma denotes combined dictionaries, e.g., `gram-en-l,word-en-l.lst`.

Smaller dictionaries are usually a subset of the larger ones, so you should 
start with the smaller ones to test. Since all Toolbox programs cache their 
results for some days, switching to the larger dictionaries in addition 
will not waste time with downloading already present results.


## File: gram-en-l.lst

most frequent english n-grams first


## File: gram-en-s.lst

most frequent english trigrams from `gram-en-l.lst` tested against
Harry Potter reviews: I only saved trigrams which led to 10-30 unique(!) hits,
best first.  Appended most frequent english trigrams which are not already
present in the Harry Potter set.  Works better with a larger set of available
reviews.  Randomization yield no improvements (rather opposite). 
Seems often as good as the whole `gram-en-l.lst`.


## File: word-en-l.lst

most frequent english words first.
Performed better than the Ngrams based dictionaries


## File: word-en-s.lst

[Parts of speech](https://en.wikipedia.org/wiki/Most_common_words_in_English#Parts_of_speech)


## File: gram-en-l,word-en-l.lst

little more results than just word-en-l.lst
but way more search time (1000 vs 4349)

## File: default.lst

A symlink to any of the other dictionary files. Toolbox programs default to this dictionary-symlink, so you can change it for all programs at once.


