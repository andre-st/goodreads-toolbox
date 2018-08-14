# Dictionaries

## Why?

TODO


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



