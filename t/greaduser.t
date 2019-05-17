#!/usr/bin/perl -w

# Test cases realized:
#   [x] 
#   [ ] private users
#   [ ] users vs authors
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


my %u = greaduser( '2' );

#use Data::Dumper;
#print Dumper(%u);

is  ( $u{id},         '2',             'User has Goodreads ID'    );
is  ( $u{name},       'odawg Diggity', 'User has name'            );
is  ( $u{is_female},  0,               'User isnt female'         );
ok  ( $u{num_books}   > 10,            'User has number of books' );
#ok ( $u{age}         > 40,            'User has age'             );   # login
#is ( $u{is_private}, 0,               'User is not private'      );   # login
is  ( $u{is_staff},   1,               'User is GR employee'      );
is  ( $u{url},       'https://www.goodreads.com/user/show/2',     'User has URL'        );
like( $u{img_url},    qr/https:\/\/[a-z0-9]+\.gr-assets\.com\/.*/, 'User has image URL'  );


# works_url
# is_friend
# age
# residence
# is_author





