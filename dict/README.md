# Dictionaries

## Why?

As far as the reviews are concerned, the official Goodreads API is of no use:
You get a maximum of 300 short excerpts. Goodreads does not even use this API on
its own website, it is a side project and is neglected accordingly. 

They use other mechanisms to display reviews on their website, mechanisms that
are used by the Toolbox programs too ("AJAX endpoints" in this case). 
These mechanisms have their own limitations: you can not see all reviews, 
but search for reviews and filter by the number of stars, age etc.

Some Toolbox programs run a dictionary (with ngrams, most common words etc)
against this search in order to collect reviews.

Woolf's "To the Lighthouse" had 5514 text reviews: 

- 948  or 17% found without dict-search (only filters-based search)
- 3057 or 55% found with `ngram-en-lg.lst`
- 4962 or 90% found with `words-en-lg.lst`
- 5127 or 93% found with `ngram+words-en-lg.lst`

Woolf's "Mrs Dalloway" had 7376 text reviews: 

- 6413 or 87% found with `words-en-lg.lst`
- 6715 or 91% found with `ngram+words-en-xl.lst`

File naming conventions:

- `${TYPE}-${LANGUAGE2LETTERCODE}-${SIZE}.lst` with size `lg` meaning large
  dictionaries and `sm` small ones (somehow optimized), `lst` just means list
  in order to indicate an ASCII file with one word per line

  
Smaller dictionaries are usually a subset of the larger ones, so you should 
start with the smaller ones to test. Since all Toolbox programs cache their 
results for some days, switching to the larger dictionaries in addition 
will not waste time with downloading already present results.


## ngram-en-lg.lst

N=3349, most frequent english n-grams first


## ngram-en-sm.lst

N=390, most frequent english trigrams tested against Harry Potter
reviews: each led to 10-30 unique(!) hits, best first.
Appended most frequent english trigrams which are not
already present in the Harry Potter set.
Works better with a larger set of available reviews.
Randomization yield no improvements (rather opposite).
Consider searching with trigram combinations ("let ing") 
in order to get more unique results.;
often as good as the whole `ngram-en-lg.lst`


## words-en-lg.lst

N=1000, most frequent english words first.
Performed better than the Ngrams based dictionaries


## words-en-sm.lst

N=114


## ngram+words-en-lg.lst

N=4349, little more results than just words-en-lg.lst
but way more search time (1000 vs 4349)

