#!/usr/bin/perl -w

# Test cases realized:
#   [x] getting books with execpted attributes (detects changes in markup)
#   [ ] order
#   [ ] num_ratings
#   [ ] exact matches



use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Test::More qw( no_plan ); # for the ok( bool, testname ), is( x, expected, testname ) and isnt() functions
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


my $NUMRATINGS = 5;
my @ORDER = qw( stars num_ratings year );
my @books;


# Never use caching during real tests. 
# We need to test against the most up-to-date markup from Goodreads.com
gsetcache( 31 );  # days


print( 'Searching books... ' );

gsearch( phrase      => 'Linux',
         ra_into     => \@books,
         is_exact    => 0,
         ra_order_by => \@ORDER,
         num_ratings => $NUMRATINGS,
         on_progress => gmeter() );

print( "\n" );


ok( scalar( @books ) > 500, 'At least 500 results' );

my $b = firstval{ $_->{title} eq 'The Linux Command Line' } @books;

isa_ok( $b, 'HASH', 'Book found via title' );

BOOK_EXISTS: {
	skip if !$b;

	is  ( $b->{url},                    'https://www.goodreads.com/book/show/11724436',  'Book has URL' );
	is  ( $b->{img_url},                'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436._SX50_.jpg', 'Book has image URL' );
	ok  ( $b->{stars}                   > 0,                                             'Book has stars rating' );
	ok  ( $b->{num_ratings}             > 0,                                             'Book has number of ratings' );
	is  ( $b->{year},                   2009,                                            'Book has year published' );
	is  ( $b->{rh_author}->{name},      'William E. Shotts Jr.',                         'Book has author name' );
	is  ( $b->{rh_author}->{url},       'https://www.goodreads.com/author/show/4949703', 'Book has author URL' );
	like( $b->{rh_author}->{works_url}, qr/https:\/\/www.goodreads.com\/author\/list\/4949703.*/, 'Book has author works URL' );
}


