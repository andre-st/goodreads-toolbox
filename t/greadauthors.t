#!/usr/bin/perl -w

# Test cases realized:
#   [x] Read authors and check attributes (detects changed markup) 
#   [ ] Invalid arguments
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


print( 'Reading authors from book shelf... ');

my %authors;

greadauthors( from_user_id    => 2, 
              ra_from_shelves => [ 'read' ],
              rh_into         => \%authors, 
              on_progress     => gmeter( 'authors' ));

print( "\n" );


ok( scalar( keys( %authors )) > 30, 'At least 30 authors read from shelf' );

ok( exists( $authors{2546} ), 'Expected author found via hash-key = Goodreads author ID' )
	or BAIL_OUT( "Cannot test author attributes when expected author is missing." );


my $a = $authors{2546};

isa_ok( $a, 'HASH', 'Author datatype' );
is  ( $a->{id},         '2546',                                                 'Author has ID'          );
is  ( $a->{name_lf},    'Palahniuk, Chuck',                                     'Author has name'        );
is  ( $a->{url},        'https://www.goodreads.com/author/show/2546',           'Author has URL'         );
like( $a->{works_url},  qr/^https:\/\/www\.goodreads\.com\/author\/list\/2546/, 'Author has works URL'   );
is  ( $a->{is_author},  1,                                                      'Author has author flag' );
is  ( $a->{is_private}, 0,                                                      'Author not private'     );


