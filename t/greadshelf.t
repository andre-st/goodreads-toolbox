#!/usr/bin/perl -w

# Test cases realized:
#   [x] Read shelf, find specific book, check all attributes (detects changed markup)
#   [ ] Reading from multiple shelves
#   [ ] 
#   [ ] 



use diagnostics; # this gives you more debugging information
use warnings;
use strict;
use Test::More qw( no_plan );  # for ok( bool, testname ), is( x, expected, testname ) and isnt() functions
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


my $USERID = 2;  # Odawg (GR employee; 1 is GR founder Otis Chandler, but too many books = test too long)
my $SHELF  = 'read';
my %books;


# Never use caching during real tests. 
# We need to test against the most up-to-date markup from Goodreads.com
gsetcache( 31 );  # days


print( 'Reading book shelf... ');

greadshelf( from_user_id    => $USERID,
            ra_from_shelves => [ $SHELF ],
            rh_into         => \%books,
            # on_book       => sub{},
            on_progress     => gmeter() );

print( "\n" );


ok( scalar( keys( %books )) > 50, 'At least 50 books read from shelf' );

ok( exists( $books{5759} ), 'Expected book found via hash-key = Goodreads book ID' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );


my $b = $books{5759};

isa_ok( $b, 'HASH', 'Book type' );

is( $b->{id},                '5759',           'Book has Goodreads ID'            );
is( $b->{year},              1996,             'Book has year published'          );
is( $b->{year_edit},         2005,             'Book edition has year published'  );
is( $b->{isbn},              '0393327345',     'Book has ISBN'                    );
is( $b->{isbn13},            '9780393327342',  'Book has ISBN13'                  );
ok( $b->{avg_rating}         > 0,              'Book has average rating'          );
is( $b->{num_pages},         218,              'Book has number of pages'         );
ok( $b->{num_ratings}        > 0,              'Book has number of ratings'       );
is( $b->{format},            'Paperback',      'Book has format'                  );
# user_xxx
# ra_user_shelves
# num_reviews
is( $b->{img_url},           'https://images.gr-assets.com/books/1357128997s/5759.jpg', 'Book has image URL' );
# review_id
is( $b->{title},             'Fight Club',                               'Book has title'        );
is( $b->{url},               'https://www.goodreads.com/book/show/5759', 'Book has URL'          );
ok( $b->{stars}               > 0,                                       'Book has stars rating' );
is( $b->{rh_author}->{id},   '2546',                                     'Book has author ID'    );
is( $b->{rh_author}->{name}, 'Palahniuk, Chuck',                         'Book has author name'  );
# name_lf
# residence
is  ( $b->{rh_author}->{url},       'https://www.goodreads.com/author/show/2546',          'Book has author URL' );
like( $b->{rh_author}->{works_url}, qr/https:\/\/www.goodreads.com\/author\/list\/2546.*/, 'Book has author works URL' );
# is_author
# is_private


