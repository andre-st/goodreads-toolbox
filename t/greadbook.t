#!/usr/bin/perl -w

# Test cases realized:
#   [x] read book and check attributes (detects changed markup)
#   [x] wrong book ID
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Test::More      qw( no_plan      );
use List::MoreUtils qw( any firstval );


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days => 1 );


my %nob = greadbook( 'TEST_INVALID_BOOK_ID' );

ok( !%nob, 'Book not found' );


my $test_book_id = 5759;  # 5759 legacy id, 36236124 new id
my %b            = greadbook( $test_book_id );

ok( %b, 'Book read' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );


is  ( $b{id},          $test_book_id,                              'Book has Goodreads ID'      );
is  ( $b{isbn},        '0393327345',                               'Book has ISBN'              );
is  ( $b{isbn13},      '9780393327342',                            'Book has ISBN13'            );
is  ( $b{num_pages},   218,                                        'Book has number of pages'   );
ok  ( $b{num_ratings}  > 190000  &&  $b{num_ratings} < 1000000,    'Book has number of ratings' );
ok  ( $b{num_reviews}  > 18000   &&  $b{num_reviews} < 50000,      'Book has number of reviews' );
is  ( $b{title},       'Fight Club',                               'Book has title'             );
ok  ( $b{avg_rating}   >= 4      &&  $b{avg_rating} < 5,           'Book has average rating'    );
ok  ( $b{stars}        >= 4      &&  $b{stars}      < 5,           'Book has stars rating'      );
like( $b{img_url},     qr/\.jpg$/,                                 'Book has image URL'         );
is  ( $b{url},         'https://www.goodreads.com/book/show/5759', 'Book has URL'               );
is  ( $b{format},      'Paperback',                                'Book has format'            );


# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
#   is( $b{year},        1996,             'Book has pub-year'          );
#   is( $b{year_edit},   2005,             'Book edition has pub-year'  );
#   user_xxx
#   ra_user_shelves
#   review_id
#   is  ( $b{rh_author}->{id},         '2546',                                                'Book has author ID'    );
#   is  ( $b{rh_author}->{name_lf},    'Palahniuk, Chuck',                                    'Book has author name'  );
#   is  ( $b{rh_author}->{url},        'https://www.goodreads.com/author/show/2546',          'Book has author URL'         );
#   like( $b{rh_author}->{works_url},  qr/https:\/\/www.goodreads.com\/author\/list\/2546.*/, 'Book has author works URL'   );
#   is  ( $b{rh_author}->{residence},
#   is  ( $b{rh_author}->{num_books},
#   is  ( $b{rh_author}->{age},
#   is  ( $b{rh_author}->{is_author},  1,                                                     'Book author has author flag' );
#   is  ( $b{rh_author}->{is_private}, 0,                                                     'Book author not private'     );
#   is  ( $b{rh_author}->{is_staff},
#   is  ( $b{rh_author}->{is_female},
#   is  ( $b{rh_author}->{is_friend},
#   is  ( $b{rh_author}->{is_mainstream},



