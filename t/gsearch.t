#!/usr/bin/perl -w

# Test cases realized:
#   [x] getting books with execpted attributes (detects changes in markup)
#   [ ] order
#   [ ] num_ratings
#   [ ] exact matches


use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use List::MoreUtils qw( firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetcache( 1 );  # days


diag( "takes ~3 minutes" );

print( 'Searching books... ' );

my @books;

gsearch( phrase      => 'Linux',
         ra_into     => \@books,
         is_exact    => 0,
         ra_order_by => [ 'stars', 'num_ratings', 'year' ],
         num_ratings => 5,
         on_progress => gmeter() );

print( "\n" );


ok( scalar( @books ) > 500, 'At least 500 results' );

my $b = firstval{ $_->{id} eq '11724436' } @books;

isa_ok( $b, 'HASH', 'Book datatype' )
	or BAIL_OUT( "Cannot test book attributes when expected book is missing." );

is  ( $b->{id},                     '11724436',                                      'Book has Goodreads ID'      );
is  ( $b->{title},                  'The Linux Command Line',                        'Book has title'             );
is  ( $b->{url},                    'https://www.goodreads.com/book/show/11724436',  'Book has URL'               );
is  ( $b->{img_url},                'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436._SX50_.jpg', 'Book has image URL' );
ok  ( $b->{stars}                   > 0,                                             'Book has stars rating'      );
ok  ( $b->{num_ratings}             > 0,                                             'Book has number of ratings' );
is  ( $b->{year},                   2009,                                            'Book has year published'    );
is  ( $b->{rh_author}->{name},      'William E. Shotts Jr.',                         'Book has author name'       );
is  ( $b->{rh_author}->{url},       'https://www.goodreads.com/author/show/4949703', 'Book has author URL'        );
like( $b->{rh_author}->{works_url}, qr/https:\/\/www\.goodreads\.com\/author\/list\/4949703.*/, 'Book has author works URL' );


