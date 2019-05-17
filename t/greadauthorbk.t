#!/usr/bin/perl -w

# Test cases realized:
#   [x] read books and check attributes (detects changed markup)
#   [ ] invalid arguments
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


print( 'Reading books of author...' );

my %books;
my $LIMIT = 10;
my $AUTID = '2546';  # Palahniuk, Chuck (Fight Club)

greadauthorbk( author_id   => $AUTID,  
               limit       => $LIMIT,
               rh_into     => \%books, 
               #on_book    => sub{}
               on_progress => gmeter( 'books' ));

print( "\n" );


ok( scalar( keys( %books )) == $LIMIT, "$LIMIT books read from author" );


map {
	ok  ( $_->{title},                                                         'Book has title'               );
	ok  ( $_->{num_ratings} > 0,                                               'Book has number of ratings'   );
	like( $_->{id},         qr/^\d+$/,                                         'Book has Goodreads ID'        );
	like( $_->{url},        qr/^https:\/\/www\.goodreads\.com\/book\/show\//,  'Book has URL'                 );
	like( $_->{img_url},    qr/^https:\/\/[a-z0-9]+\.gr-assets\.com/,          'Book has image URL'           );
	
	ok  ( $_->{rh_author}->{name},                                             'Book author has name'         );
	is  ( $_->{rh_author}->{id},        $AUTID,                                'Book author has Goodreads ID' );
	like( $_->{rh_author}->{img_url},   qr/^https:\/\/images\.gr-assets\.com/, 'Book author has image URL'    );
	like( $_->{rh_author}->{url},       qr/^https:\/\/www\.goodreads\.com/,    'Book author has URL'          );
	like( $_->{rh_author}->{works_url}, qr/^https:\/\/www\.goodreads\.com/,    'Book author has works URL'    );
	is  ( $_->{rh_author}->{is_author}, 1,                                     'Book author is author'        );
	is  ( $_->{rh_author}->{is_private}, 0,                                    'Book author not private'      );
	
	# Not available or scraped yet:
	# isbn
	# isbn13
	# format
	# num_pages
	# year
	# year_edit
	# rh_author->residence
	
} values( %books )

