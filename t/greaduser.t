#!/usr/bin/perl -w

# Test cases realized:
#   [x] read normal user info and check attributes (detects changed markup)
#   [ ] read author user info and check attributes (detects changed markup)
#   [ ] private users
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


# Normal user:

my %u = greaduser( '2' );

is  ( $u{id},         '2',             'User has Goodreads ID'    );
is  ( $u{name},       'odawg Diggity', 'User has name'            );
is  ( $u{is_female},  0,               'User isnt female'         );
ok  ( $u{num_books}   > 10,            'User has number of books' );
#ok ( $u{age}         > 40,            'User has age'             );   # login
#is ( $u{residence},  '',              'User has residence'       );   # login
#is ( $u{is_private}, 0,               'User is not private'      );   # login
is  ( $u{is_author},  0,               'User not an author'       );
is  ( $u{is_staff},   1,               'User is GR employee'      );
is  ( $u{url},        'https://www.goodreads.com/user/show/2',    'User has URL'        );
like( $u{img_url},    qr/^https:\/\/[a-z0-9]+\.gr-assets\.com\//, 'User has image URL'  );
is  ( $u{works_url},  undef,           'User has no works URL (not an author) '         );

# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $u{is_friend},  undef, 'Not avail: user friend status' );



# Author user:

my %au = greaduser( '2546', 1 );

is  ( $au{id},         '2546',                                                 'Author has ID'          );
is  ( $au{name},       'Chuck Palahniuk',                                      'Author has name'        );
is  ( $au{url},        'https://www.goodreads.com/author/show/2546',           'Author has URL'         );
like( $au{works_url},  qr/^https:\/\/www\.goodreads\.com\/author\/list\/2546/, 'Author has works URL'   );
like( $au{img_url},    qr/^https:\/\/images.gr-assets.com/,                    'Author has image URL'   );
is  ( $au{is_author},  1,                                                      'Author has author flag' );
is  ( $au{is_private}, 0,                                                      'Author not private'     );
is  ( $au{is_staff},   1,                                                      'Goodreads author'       );
ok  ( $au{num_books}   > 10,                                                   'Author > 10 books'      );

# Not available or scraped yet, otherwise one of the following
# tests will fail and remind me of implementing a correct test:
is  ( $au{is_friend},  undef, 'N/A: author friend status' );
is  ( $au{is_female},  undef, 'N/A: author gender status' );
is  ( $au{residence},  undef, 'N/A: author residence'     );


#use Data::Dumper;
#print Dumper(%u);



