#!/usr/bin/perl -w

# Test cases realized:
#   [x] read book and check attributes (detects changed markup)
#   [x] wrong book ID
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


my %nob = greadbook( 'TEST_INVALID_BOOK_ID' );

ok( !%nob, 'Book not found' );


my %b = greadbook( '5759' );

ok( %b, 'Book read' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );


is( $b{id},          '5759',           'Book has Goodreads ID'      );
is( $b{isbn13},      '9780393327342',  'Book has ISBN13'            );
ok( $b{avg_rating}   > 2,              'Book has average rating'    );
is( $b{num_pages},   218,              'Book has number of pages'   );
ok( $b{num_ratings}  > 190000,         'Book has number of ratings' );
is( $b{title},       'Fight Club',     'Book has title'             );
ok( $b{stars}        > 2,              'Book has stars rating'      );
is( $b{img_url},     'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1357128997i/5759._UY630_SR1200,630_.jpg', 'Book has image URL' );
is( $b{url},         'https://www.goodreads.com/book/show/5759', 'Book has URL' );
ok( $b{num_reviews}  > 12000,          'Book has number of reviews' );

# Not available or scraped:
#   is( $b{isbn},        '0393327345',     'Book has ISBN'              );
#   is( $b{year},        1996,             'Book has pub-year'          );
#   is( $b{year_edit},   2005,             'Book edition has pub-year'  );
#   is( $b{format},      'Paperback',      'Book has format'            );
#   user_xxx
#   ra_user_shelves
#   review_id
#   is  ( $b{rh_author}->{id},         '2546',                                                'Book has author ID'    );
#   is  ( $b{rh_author}->{name_lf},    'Palahniuk, Chuck',                                    'Book has author name'  );
#   is  ( $b{rh_author}->{url},        'https://www.goodreads.com/author/show/2546',          'Book has author URL'         );
#   like( $b{rh_author}->{works_url},  qr/https:\/\/www.goodreads.com\/author\/list\/2546.*/, 'Book has author works URL'   );
#   is  ( $b{rh_author}->{is_author},  1,                                                     'Book author has author flag' );
#   is  ( $b{rh_author}->{is_private}, 0,                                                     'Book author not private'     );




