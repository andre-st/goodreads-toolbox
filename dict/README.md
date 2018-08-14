# Dictionaries

## Why?

As far as the reviews are concerned, the official Goodreads API is of no use:
You get a maximum of 300 short excerpts. Goodreads does not even use this API on
its own website, it is a side project and is neglected accordingly. 

They use other mechanisms to display reviews on their website, mechanisms that
are tapped by my own programs ("AJAX endpoints" in this case). These mechanisms
have their own limitations: you can not see all reviews, but search for reviews
and filter by the number of stars, age etc.

Some Toolbox programs run a dictionary (with ngrams, most common words etc)
against this search and collect reviews.

Woolf's "To the Lighthouse" has 5514 text reviews: 948 found without
dict-search (only filters-based search).
With dict-search: 3057 (ngrams) or 4962 (words).


## ngram-en-xl.lst

N=3349, most frequent english n-grams first


## ngram-en-sm.lst

N=390, most frequent english trigrams tested against Harry Potter
reviews: each led to 10-30 unique(!) hits, best first.
Appended most frequent english trigrams which are not
already present in the Harry Potter set.
Works better with a larger set of available reviews.
Randomization yield no improvements (rather opposite).
Consider searching with trigram combinations ("let ing") 
in order to get more unique results.


## words-en-xl.lst

N=1000, most frequent english words first.
Performed better than the Ngrams based dictionaries


## words-en-sm.lst

N=114



