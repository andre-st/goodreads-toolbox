#!/usr/bin/perl -w

# Test cases realized:
#   [x] latest and check attributes (detects changed markup)
#   [ ] rigor 2, 3, ...
#   [ ] 
#   [ ] Invalid values



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


print( 'Loading reviews...' );

my %reviews;
my %book;
$book{id}          = '5759';  # "Fight Club"
$book{num_ratings} = 190000;
$book{num_reviews} =  12000;

greadreviews( rh_for_book => \%book,
              rigor       => 0,  # 300 reviews only (latest)
              rh_into     => \%reviews,
		    # dict_path   => $DICTPATH,
              text_only   => 0,
              on_progress => gmeter());

print( "\n" );


ok( scalar( keys( %reviews )) > 0, 'Load some reviews' )
	or BAIL_OUT( "Cannot test review attributes when there are no reviews." );


#use Data::Dumper;
#my $r = (values( %reviews ))[0];
#print Dumper($r);
#exit;


map {
	ok  ( $_->{rating} >= 0,        'Review has rating'            );
	ok  ( $_->{rating_str},         'Review has rating code'       );
	#ok ( $_->{text},               'Review has text'              );  # Often no text but just stars
	ok  ( $_->{date}->year > 2006,  'Review has date > 2006'       );  # GR was founded 2007
	is  ( $_->{book_id},            $book{id},                                           'Review has Goodreads book ID' );
	like( $_->{id},                 qr/^\d+$/,                                           'Review has ID'                );
	like( $_->{url},                qr/https:\/\/www\.goodreads\.com\/review\/show\/.*/, 'Review has URL'               );
	like( $_->{rh_user}->{url},     qr/https:\/\/www\.goodreads\.com\/user\/show\/.*/,   'Review has author URL'        );
	like( $_->{rh_user}->{id},      qr/^\d+$/,                                           'Review has author ID'         );
	like( $_->{rh_user}->{img_url}, qr/https:\/\/[a-z0-9]+\.gr-assets\.com\/.*/,         'Review has author image URL'  );
	ok  ( $_->{rh_user}->{name},    'Review has author name'       );

} values( %reviews );




