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
gsetopt( cache_days => 1 );


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
	ok  ( $_->{title},                                                             'Book has title'               );
	like( $_->{url},        qr/^https:\/\/www\.goodreads\.com\/book\/show\//,      'Book has URL'                 );
	like( $_->{img_url},    qr/^https:\/\/[a-z0-9]+\.gr-assets\.com/,              'Book has image URL'           );
	like( $_->{id},         qr/^\d+$/,                                             'Book has Goodreads ID'        );
	ok  ( $_->{num_ratings} > 0,                                                   'Book has number of ratings'   );
	ok  ( $_->{avg_rating}  > 0,                                                   'Book has average rating'      );
	ok  ( $_->{rh_author}->{name},                                                 'Book author has name'         );
	ok  ( $_->{rh_author}->{name_lf},                                              'Book author has name'         );
	is  ( $_->{rh_author}->{id},            $AUTID,                                'Book author has Goodreads ID' );
	like( $_->{rh_author}->{img_url},       qr/^https:\/\/images\.gr-assets\.com/, 'Book author has image URL'    );
	like( $_->{rh_author}->{url},           qr/^https:\/\/www\.goodreads\.com/,    'Book author has URL'          );
	like( $_->{rh_author}->{works_url},     qr/^https:\/\/www\.goodreads\.com/,    'Book author has works URL'    );
	is  ( $_->{rh_author}->{is_author},     1,                                     'Book author is author'        );
	is  ( $_->{rh_author}->{is_private},    0,                                     'Book author not private'      );
	is  ( $_->{rh_author}->{is_mainstream}, 1,                                     'Is a mainstream author'       );
	
	
	# Not available or scraped yet, otherwise one of the following
	# tests will fail and remind me of implementing a correct test:
	is  ( $_->{isbn},                        undef, 'N/A: Book ISBN'                );
	is  ( $_->{isbn13},                      undef, 'N/A: Book ISBN13'              );
	is  ( $_->{format},                      undef, 'N/A: Book format'              );
	is  ( $_->{user_rating},                 undef, 'N/A: User rating'              );
	is  ( $_->{user_read_count},             undef, 'N/A: User read count'          );
	is  ( $_->{user_num_owned},              undef, 'N/A: Number user-owned books'  );
	is  ( $_->{user_date_read},              undef, 'N/A: User reading-date'        );
	is  ( $_->{user_date_added},             undef, 'N/A: User addition-date'       );
	is  ( $_->{ra_user_shelves},             undef, 'N/A: User shelves'             );
	is  ( $_->{stars},                       undef, 'N/A: Book average rating'      );
	is  ( $_->{num_pages},                   undef, 'N/A: Book number of pages'     );
	is  ( $_->{num_reviews},                 undef, 'N/A: Book number of reviews'   );
	is  ( $_->{review_id},                   undef, 'N/A: User review id'           );
	is  ( $_->{year},                        undef, 'N/A: Book pub-year'            );
	is  ( $_->{year_edit},                   undef, 'N/A: Book edition pub-year'    );
	is  ( $_->{rh_author}->{residence},      undef, 'N/A: Author residence'         );
	is  ( $_->{rh_author}->{age},            undef, 'N/A: Author age'               );
	is  ( $_->{rh_author}->{is_staff},       undef, 'N/A: Is Goodreads author'      );
	is  ( $_->{rh_author}->{is_female},      undef, 'N/A: Author gender'            );
	is  ( $_->{rh_author}->{is_friend},      undef, 'N/A: Author friend status'     );
	is  ( $_->{rh_author}->{num_books},      undef, 'N/A: Number of author books'   );
	
} values( %books )

