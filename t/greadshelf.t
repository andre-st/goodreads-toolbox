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
gsetopt( cache_days => 1 );


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

is  ( $b->{id},          '5759',           'Book has Goodreads ID'      );
is  ( $b->{year},        1996,             'Book has pub-year'          );
is  ( $b->{year_edit},   2005,             'Book edition has pub-year'  );
is  ( $b->{isbn},        '0393327345',     'Book has ISBN'              );
is  ( $b->{isbn13},      '9780393327342',  'Book has ISBN13'            );
ok  ( $b->{avg_rating}   > 2,              'Book has average rating'    );
is  ( $b->{num_pages},   218,              'Book has number of pages'   );
ok  ( $b->{num_ratings}  > 190000,         'Book has number of ratings' );
is  ( $b->{format},      'Paperback',      'Book has format'            );
is  ( $b->{title},       'Fight Club',     'Book has title'             );
ok  ( $b->{stars}        > 2,              'Book has stars rating'      );
is  ( $b->{url},         'https://www.goodreads.com/book/show/5759',    'Book has URL'            );
like( $b->{img_url},     qr/^https:.*\.jpg$/,                           'Book has image URL'      );
like( $b->{review_id},   qr/^\d+$/,                                     'Book has user review ID' );
ok  ( $b->{user_rating}           > 2,     'User rating'                );
ok  ( $b->{user_read_count}       > 0,     'User read count'            );
ok  ( $b->{user_date_added}->year > 2006,  'User addition-date > 2006'  );  # GR was founded in 2007
is  ( $b->{user_num_owned},       0,       'Number of user-owned books' ); 

is  ( $b->{rh_author}->{id},         '2546',                                                 'Book has author ID'          );
is  ( $b->{rh_author}->{name_lf},    'Palahniuk, Chuck',                                     'Book has author name'        );
is  ( $b->{rh_author}->{url},        'https://www.goodreads.com/author/show/2546',           'Book has author URL'         );
like( $b->{rh_author}->{works_url},  qr/^https:\/\/www\.goodreads\.com\/author\/list\/2546/, 'Book has author works URL'   );
is  ( $b->{rh_author}->{is_author},  1,                                                      'Book author has author flag' );
is  ( $b->{rh_author}->{is_private}, 0,                                                      'Book author not private'     );


# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $b->{rh_author}->{residence},        undef,  'N/A: Author residence'        );
is  ( $b->{rh_author}->{img_url},          undef,  'N/A: Author image URL'        );
is  ( $b->{rh_author}->{is_staff},         undef,  'N/A: Is Goodreads author'     );
is  ( $b->{rh_author}->{is_female},        undef,  'N/A: Author gender'           );
is  ( $b->{rh_author}->{is_friend},        undef,  'N/A: Author friend status'    );
is  ( $b->{rh_author}->{num_books},        undef,  'N/A: Number of author books'  );
is  ( $b->{num_reviews},                   undef,  'N/A: Number of book reviews'  );
#is  ( $b->{user_date_read},                undef,  'N/A: User reading-date'       );  # TODO
is  ( scalar( @{$b->{ra_user_shelves}} ),  0,      'N/A: User shelves for book'   );

