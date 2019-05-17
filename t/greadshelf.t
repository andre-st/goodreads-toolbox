#!/usr/bin/perl -w

# Test cases realized:
#   [x] Read shelf, find specific book, check all attributes (detects changed markup)
#   [ ] Reading from multiple shelves
#   [ ] invalid arguments
#   [ ] 



use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetcache( 1 );  # days


print( 'Reading book shelf... ');

my %books;

greadshelf( from_user_id    => 2,  # "Odawg" (GR employee; 1 is GR founder Otis Chandler, but too many books = test too long)
            ra_from_shelves => [ 'read' ],
            rh_into         => \%books,
            # on_book       => sub{},
            on_progress     => gmeter( 'books' ) );

print( "\n" );


ok( scalar( keys( %books )) > 50, 'At least 50 books read from shelf' );

ok( exists( $books{5759} ), 'Expected book found via hash-key = Goodreads book ID' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );


my $b = $books{5759};

isa_ok( $b, 'HASH', 'Book datatype' );
is( $b->{id},          '5759',           'Book has Goodreads ID'      );
is( $b->{year},        1996,             'Book has pub-year'          );
is( $b->{year_edit},   2005,             'Book edition has pub-year'  );
is( $b->{isbn},        '0393327345',     'Book has ISBN'              );
is( $b->{isbn13},      '9780393327342',  'Book has ISBN13'            );
ok( $b->{avg_rating}   > 2,              'Book has average rating'    );
is( $b->{num_pages},   218,              'Book has number of pages'   );
ok( $b->{num_ratings}  > 190000,         'Book has number of ratings' );
is( $b->{format},      'Paperback',      'Book has format'            );
is( $b->{title},       'Fight Club',     'Book has title'             );
ok( $b->{stars}        > 2,              'Book has stars rating'      );
is( $b->{img_url},     'https://images.gr-assets.com/books/1357128997s/5759.jpg', 'Book has image URL' );
is( $b->{url},         'https://www.goodreads.com/book/show/5759',                'Book has URL'       );
is  ( $b->{rh_author}->{id},         '2546',                                                 'Book has author ID'          );
is  ( $b->{rh_author}->{name},       'Palahniuk, Chuck',                                     'Book has author name'        );
is  ( $b->{rh_author}->{url},        'https://www.goodreads.com/author/show/2546',           'Book has author URL'         );
like( $b->{rh_author}->{works_url},  qr/^https:\/\/www\.goodreads\.com\/author\/list\/2546/, 'Book has author works URL'   );
is  ( $b->{rh_author}->{is_author},  1,                                                      'Book author has author flag' );
is  ( $b->{rh_author}->{is_private}, 0,                                                      'Book author not private'     );

# Not available or scraped:
#   user_xxx
#   ra_user_shelves
#   num_reviews
#   review_id
#   rh_author->name_lf
#   rh_author->residence

