#!/usr/bin/perl -w

# Test cases realized:
#   [x] 
#   [ ] 
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


print( 'Reading book shelf... ');

my %authors;

greadsimilaraut( author_id   => '2546',
                 rh_into     => \%authors,
                 on_progress => gmeter( 'similar' ));


print( "\n" );

ok( scalar( keys( %authors )) > 10, 'At least 10 similar authors' );
		  
ok( exists( $authors{4764} ), 'Expected author found via hash-key = Goodreads author ID' )
	or BAIL_OUT( "Cannot test author attributes when expected author is missing." );
		  

my $a = $authors{4764};

isa_ok( $a, 'HASH', 'Author datatype' );
is  ( $a->{id},         '4764',                                                 'Author has ID'          );
is  ( $a->{name},       'Philip K. Dick',                                       'Author has name'        );
is  ( $a->{url},        'https://www.goodreads.com/author/show/4764',           'Author has URL'         );
like( $a->{works_url},  qr/^https:\/\/www\.goodreads\.com\/author\/list\/4764/, 'Author has works URL'   );
is  ( $a->{img_url},    'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/authors/1264613853i/4764._UX75_CR0,7,75,75_.jpg', 'Author has image URL' );
is  ( $a->{is_author},  1,                                                      'Author has author flag' );
is  ( $a->{is_private}, 0,                                                      'Author not private'     );

# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $a->{name_lf},    $a->{name}, 'N/A: author name != name_lf' );  # "Chuck Palahniuk"
is  ( $a->{residence},  undef,      'N/A: author residence'       );
is  ( $a->{age},        undef,      'N/A: author age'             );
is  ( $a->{num_books},  undef,      'N/A: number of author books' );
is  ( $a->{is_friend},  undef,      'N/A: author friend status'   );
is  ( $a->{is_female},  undef,      'N/A: author gender status'   );
is  ( $a->{is_staff},   undef,      'N/A: is Goodreads author'    );



