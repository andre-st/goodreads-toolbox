#!/usr/bin/perl -w

# Test cases realized:
#   [x] latest and check attributes (detects changed markup)
#   [x] text only
#   [x] date range
#   [x] dict
#   [ ] 
#   [ ] invalid arguments

use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Time::Piece;
use Test::More      qw( no_plan          );
use List::MoreUtils qw( any all firstval );


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days    => 1 );
gsetopt( ignore_errors => 1 );
gsetopt( maxretries    => 0 );


diag( 'takes ~1 minute' );


print( 'Loading reviews...' );

my %reviews;
my %reviews_textonly;
my %reviews_by_dict;

my %book;
$book{id}          = '984394';  # "Hacking the Xbox"
$book{num_ratings} = 253;       # This value can be obtained using greadbook() or ignored, it helps optimizing; TODO: constant might break test
$book{num_reviews} =  28;       #     "      "                                                                  TODO: constant might break test
my $since          = Time::Piece->strptime( '2016-01-01', '%Y-%m-%d' );


greadreviews( rh_for_book => \%book,
              rigor       => 0,  # 0 = 300 reviews only (latest)
              rh_into     => \%reviews,
              text_minlen => 0,
              since       => $since,
              on_progress => gmeter());

greadreviews( rh_for_book => \%book,  # Uses some cached values from query above, which is fine for this test
              rigor       => 0,       # 0 = 300 reviews only (latest)
              rh_into     => \%reviews_textonly,
              text_minlen => 1,
              on_progress => gmeter());

greadreviews( rh_for_book => \%book,  # Uses some cached values from query above, which is fine for this test
              rigor       => 3,       # Include dict in every case
              rh_into     => \%reviews_by_dict,
              dict_path   => "$FindBin::Bin/../list-in/test.lst",
              text_minlen => 1,
              on_progress => gmeter());

print( "\n" );


# Check numbers:
my $num_reviews          = scalar( keys( %reviews          ));
my $num_reviews_textonly = scalar( keys( %reviews_textonly ));
my $num_reviews_by_dict  = scalar( keys( %reviews_by_dict  ));

ok( $num_reviews > 0, 'Load some reviews' )
	or BAIL_OUT( "Cannot test review attributes when there are no reviews." );

ok( $num_reviews_textonly > 0, 'Load some text reviews' )
	or BAIL_OUT( "Cannot test text reviews when there are no text reviews." );

ok( $num_reviews_by_dict >= $num_reviews_textonly, 'Load more or equal number of reviews compared to rigor-level 0' )
	or BAIL_OUT( "Book specimen might not sufficient for this test anymore or adjust book's num_reviews constant in this testfile. Expected #reviews from dict ($num_reviews_by_dict) >= #reviews from latest ($num_reviews_textonly)" );


# Check contents:
ok(( !all { $_->{text} } values( %reviews          )), 'Reviews include text and non-text ratings');
ok((  all { $_->{text} } values( %reviews_textonly )), 'All reviews include text');
ok((  all { $_->{text} } values( %reviews_by_dict  )), 'All dict-searched reviews include text');


# Check contents in detail:
map {
	ok  ( $_->{rating} >= 0,           "Review $_->{id} has rating"            );
	ok  ( $_->{rating_str},            "Review $_->{id} has rating code"       );
	#ok ( $_->{text},                  "Review $_->{id} has text"              );  # Often no text but just stars
	#ok ( $_->{date}->year > 2005,     "Review $_->{id} has date > 2006 (got date: '$_->{date}')" );  # GR was founded 2007, but there are reviews from 2006, e.g., #454926175
	ok  ( $_->{date} >= $since,        "Review $_->{id} isn't older than ".$since->strftime( "%Y-%m-%d" ));
	is  ( $_->{book_id},               $book{id},                                          "Review $_->{id} has Goodreads book ID" );
	like( $_->{id},                    qr/^\d+$/,                                          "Review $_->{id} has ID"                );
	like( $_->{url},                   qr/^https:\/\/www\.goodreads\.com\/review\/show\//, "Review $_->{id} has URL"               );
	like( $_->{rh_user}->{url},        qr/^https:\/\/www\.goodreads\.com\/user\/show\//,   "Review $_->{id} has author URL"        );
	like( $_->{rh_user}->{id},         qr/^\d+$/,                                          "Review $_->{id} has author ID"         );
	like( $_->{rh_user}->{img_url},    qr/^https:\/\/[a-z0-9]+\.gr-assets\.com\//,         "Review $_->{id} has author image URL"  );
	ok  ( $_->{rh_user}->{name},       "Review $_->{id} has author name: $_->{rh_user}->{name}" );
	ok  ( $_->{rh_user}->{name_lf},    "Review $_->{id} has author lastname, firstname"  );
	
	
	# Not available or scraped yet, otherwise one of the following
	# tests will fail and remind me of implementing a correct test:
	is  ( $_->{rh_user}->{is_private},     undef, 'N/A: User is private'            );
	is  ( $_->{rh_user}->{is_female},      undef, 'N/A: User gender'                );
	is  ( $_->{rh_user}->{is_author},      undef, 'N/A: User is author'             );
	is  ( $_->{rh_user}->{is_staff},       undef, 'N/A: User is Goodreads employee' );
	is  ( $_->{rh_user}->{is_friend},      undef, 'N/A: User friend status'         );
	is  ( $_->{rh_user}->{is_mainstream},  undef, 'N/A: User mainstream status'     );
	is  ( $_->{rh_user}->{residence},      undef, 'N/A: User residence'             );
	is  ( $_->{rh_user}->{age},            undef, 'N/A: User age'                   );
	is  ( $_->{rh_user}->{num_books},      undef, 'N/A: Number of books'            );  # Works or books read?
	is  ( $_->{rh_user}->{works_url},      undef, 'N/A: Works URL if author'        );
} values( %reviews );


