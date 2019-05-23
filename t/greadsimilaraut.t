#!/usr/bin/perl -w

# Test cases realized:
#   [x] 
#   [ ] 
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetcache( 1 );  # days


print( 'Reading book shelf... ');

my %authors;

greadsimilaraut( author_id   => '2546',
                 rh_into     => \%authors,
                 on_progress => gmeter( 'similar' ));



		  
