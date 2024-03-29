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
my $SIMILAR_AUTHOR_ID = '9876';  # John Milton

greadsimilaraut( author_id   => '1734373',  # Karl Held
                 rh_into     => \%authors,
                 on_progress => gmeter( 'similar' ));



print( "\n" );


ok( scalar( keys( %authors )) >= 4, 'At least 4 similar authors' );

ok( exists( $authors{$SIMILAR_AUTHOR_ID} ), 'Expected author found via hash-key = Goodreads author ID' ) 
	or BAIL_OUT( "Cannot test author attributes when expected author is missing." );


my $a = $authors{$SIMILAR_AUTHOR_ID};

isa_ok( $a, 'HASH', 'Author datatype' );
is  ( $a->{id},             $SIMILAR_AUTHOR_ID,                                         'Author has ID'             );
is  ( $a->{name},           'John Milton',                                              'Author has name'           );
is  ( $a->{url},            "https://www.goodreads.com/author/show/$SIMILAR_AUTHOR_ID", 'Author has URL'            );
like( $a->{works_url},      qr/^https:\/\/www\.goodreads\.com\/author\/list\/$SIMILAR_AUTHOR_ID/, 'Author has works URL' );
like( $a->{img_url},        qr/\.jpg$/,                                                 'Author has image URL' );
is  ( $a->{is_author},      1,                                                          'Author has author flag'    );
is  ( $a->{is_private},     0,                                                          'Author not private'        );
ok  ( $a->{is_mainstream},                                                              'is mainstream author'      );

# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $a->{name_lf},        $a->{name}, 'N/A: author name != name_lf' );  # "Dick, Philip K."
is  ( $a->{residence},      undef,      'N/A: author residence'       );
is  ( $a->{age},            undef,      'N/A: author age'             );
is  ( $a->{num_books},      undef,      'N/A: number of author books' );
is  ( $a->{is_friend},      undef,      'N/A: author friend status'   );
is  ( $a->{is_female},      undef,      'N/A: author gender status'   );
is  ( $a->{is_staff},       undef,      'N/A: is Goodreads author'    );




