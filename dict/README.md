# Dictionaries

## Purpose

As far as the reviews are concerned, the official Goodreads API is of no use:
You get a maximum of 300 short excerpts. Goodreads does not even use this API on
its own website, it is a side project and is neglected accordingly. 

They use other mechanisms to display reviews on their website, mechanisms that
are used by the Toolbox programs too ("AJAX endpoints" in this case). 
These mechanisms have their own limitations: you can not see all reviews, 
but search for reviews and filter by the number of stars, age etc.

Some Toolbox programs run a dictionary (with ngrams, most common words etc)
against this search in order to collect reviews.


| Dictionary             | Lines | "To the Lighthouse"<br>5514 text reviews | "Mrs Dalloway"<br>7376 text reviews |
|:-----------------------|------:|--------------------------:|---------------------:|
| _none (filters only)_  |     - | 948 or 17%                | _untested_
| ngram-en-lg.lst        |  3349 | 3057 or 55%               | _untested_
| ngram-en-sm.lst        |   390 | _untested_                | _untested_
| words-en-lg.lst        |  1000 | 4962 or 90%               | 6413 or 87%
| words-en-sm.lst        |   114 | _untested_                | _untested_
| ngram,words-en-lg.lst  |  4349 | 5127 or 93%               | 6715 or 91%


(no duplicate reviewers; but could theoretically contain duplicate reviews
posted by different members, which would be counted by Goodreads too)

    
## File naming conventions

- `${TYPE},...-${LANGUAGE2LETTERCODE},...-${SIZE}.lst` with size `lg` meaning large
  dictionaries, `sm` meaning small dictionaries and `lst` meaning "list".
  Lists are ASCII files with one word per line.
  Comma denotes multiple types or languages, e.g., `ngram,words` or `en,de`
  
Smaller dictionaries are usually a subset of the larger ones, so you should 
start with the smaller ones to test. Since all Toolbox programs cache their 
results for some days, switching to the larger dictionaries in addition 
will not waste time with downloading already present results.


## File: ngram-en-lg.lst

most frequent english n-grams first


## File: ngram-en-sm.lst

N=390, most frequent english trigrams from `ngram-en-lg.lst` tested against
Harry Potter reviews: I only saved trigrams which led to 10-30 unique(!) hits,
best first.  Appended most frequent english trigrams which are not already
present in the Harry Potter set.  Works better with a larger set of available
reviews.  Randomization yield no improvements (rather opposite). 
Seems often as good as the whole `ngram-en-lg.lst`.


## File: words-en-lg.lst

most frequent english words first.
Performed better than the Ngrams based dictionaries


## File: words-en-sm.lst


## File: ngram,words-en-lg.lst

little more results than just words-en-lg.lst
but way more search time (1000 vs 4349)

