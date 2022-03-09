#!/usr/bin/perl -w

# Test cases realized:
#   [x] getting books with execpted attributes (detects changes in markup)
#   [ ] order
#   [ ] num_ratings
#   [ ] exact matches
#   [ ] invalid arguments

use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Test::More      qw( no_plan  );
use List::MoreUtils qw( firstval );


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days    => 1 );
gsetopt( ignore_errors => 1 );
gsetopt( maxretries    => 0 );


diag( 'takes ~8 minutes' );


print( 'Searching books... ' );

my @books;
gsearch( phrase      => 'Linux',
         ra_into     => \@books,
         is_exact    => 0,
         ra_order_by => [ 'stars', 'num_ratings', 'year' ],
         num_ratings => 5,
         on_progress => gmeter());

print( "\n" );

my $numbooks = scalar( @books );
ok( $numbooks > 450, "At least 500 results, got $numbooks" );  # was 500, later 480

my $BOOK_ID = '8474434';

my $b = firstval{ $_->{id} eq $BOOK_ID } @books;

isa_ok( $b, 'HASH', 'Book datatype' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );


is  ( $b->{id},                         $BOOK_ID,                                         'Book has Goodreads ID'      );
is  ( $b->{title},                      'Linux Kernel Development',                       'Book has title'             );
is  ( $b->{url},                        'https://www.goodreads.com/book/show/'.$BOOK_ID,  'Book has URL'               );
like( $b->{img_url},                    qr/^https:.*\.(jpg|png)$/,                        'Book has image URL'         );
ok  ( $b->{stars}                       > 0,                                              'Book has stars rating'      );
ok  ( $b->{avg_rating}                  > 0,                                              'Book has average rating'    );
ok  ( $b->{num_ratings}                 > 0,                                              'Book has number of ratings' );
is  ( $b->{year},                       2003,                                             'Book has year published'    );
is  ( $b->{rh_author}->{id},            '13609144',                                       'Book has author ID'         );
is  ( $b->{rh_author}->{name},          'Robert   Love',                                  'Book has author name'       );
is  ( $b->{rh_author}->{url},           'https://www.goodreads.com/author/show/13609144', 'Book has author URL'        );
like( $b->{rh_author}->{works_url},     qr/^https:\/\/www\.goodreads\.com\/author\/list\/13609144/, 'Book has author works URL' );
is  ( $b->{rh_author}->{is_author},     1,                                                'Book author has author flag' );
is  ( $b->{rh_author}->{is_private},    0,                                                'Book author not private'     );
ok  (!$b->{rh_author}->{is_mainstream},                                                   'Book author not mainstream author' );



# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $b->{rh_author}->{name_lf},          $b->{rh_author}->{name},  'N/A: Author name_lf != name' );
is  ( $b->{rh_author}->{residence},        undef,        'N/A: Author residence'        );
like( $b->{rh_author}->{img_url},          qr/nophoto/,  'N/A: Author real image URL'   );
is  ( $b->{rh_author}->{is_staff},         undef,        'N/A: Is Goodreads author'     );
is  ( $b->{rh_author}->{is_female},        undef,        'N/A: Author gender'           );
is  ( $b->{rh_author}->{is_friend},        undef,        'N/A: Author friend status'    );
is  ( $b->{rh_author}->{num_books},        undef,        'N/A: Number of author books'  );
is  ( $b->{year_edit},                     undef,        'N/A: Book edition pub-year'   );
is  ( $b->{isbn},                          undef,        'N/A: Book ISBN'               );
is  ( $b->{isbn13},                        undef,        'N/A: Book ISBN13'             );
is  ( $b->{num_pages},                     undef,        'N/A: Book number of pages'    );
is  ( $b->{format},                        undef,        'N/A: Book format'             );
is  ( $b->{review_id},                     undef,        'N/A: User book review ID'     );
is  ( $b->{user_rating},                   undef,        'N/A: User book rating'        );
is  ( $b->{user_read_count},               undef,        'N/A: User read count'         );
is  ( $b->{user_date_added},               undef,        'N/A: User addition-date'      );
is  ( $b->{num_reviews},                   undef,        'N/A: Number of book reviews'  );
is  ( $b->{user_num_owned},                undef,        'N/A: Number user-owned books' );
is  ( $b->{user_date_read},                undef,        'N/A: User reading-date'       );
is  ( scalar( @{$b->{ra_user_shelves}} ),  0,            'N/A: User shelves for book'   );




