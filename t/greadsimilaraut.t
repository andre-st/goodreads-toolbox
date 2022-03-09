#!/usr/bin/perl -w

# Test cases realized:
#   [x] 
#   [ ] 
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Test::More      qw( no_plan      );
use List::MoreUtils qw( any firstval );


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days => 1 );


print( 'Reading book shelf... ');

my %authors;
my $SIMILAR_AUTHOR_ID = '1466';  # Sartre

greadsimilaraut( author_id   => '3137322',  # Fyodor Dostoyevsky
                 rh_into     => \%authors,
                 on_progress => gmeter( 'similar' ));



print( "\n" );


ok( scalar( keys( %authors )) >= 10, 'At least 10 similar authors' );

ok( exists( $authors{$SIMILAR_AUTHOR_ID} ), 'Expected author found via hash-key = Goodreads author ID' ) 
	or BAIL_OUT( "Cannot test author attributes when expected author is missing." );


my $a = $authors{$SIMILAR_AUTHOR_ID};

isa_ok( $a, 'HASH', 'Author datatype' );
is  ( $a->{id},             $SIMILAR_AUTHOR_ID,                                     'Author has ID'             );
is  ( $a->{name},           'Jean-Paul Sartre',                                     'Author has name'           );
is  ( $a->{url},            'https://www.goodreads.com/author/show/1466',           'Author has URL'            );
like( $a->{works_url},      qr/^https:\/\/www\.goodreads\.com\/author\/list\/1466/, 'Author has works URL'      );
is  ( $a->{img_url},        'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/authors/1475567078i/1466._UY75_CR1,0,75,75_.jpg', 'Author has image URL' );
is  ( $a->{is_author},      1,                                                      'Author has author flag'    );
is  ( $a->{is_private},     0,                                                      'Author not private'        );
is  ( $a->{is_mainstream},  1,                                                      'N/A: is mainstream author' );

# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $a->{name_lf},        $a->{name}, 'N/A: author name != name_lf' );  # "Dick, Philip K."
is  ( $a->{residence},      undef,      'N/A: author residence'       );
is  ( $a->{age},            undef,      'N/A: author age'             );
is  ( $a->{num_books},      undef,      'N/A: number of author books' );
is  ( $a->{is_friend},      undef,      'N/A: author friend status'   );
is  ( $a->{is_female},      undef,      'N/A: author gender status'   );
is  ( $a->{is_staff},       undef,      'N/A: is Goodreads author'    );




