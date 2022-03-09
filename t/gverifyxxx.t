#!/usr/bin/perl -w

# Test cases realized:
#   [x] sanitization
#   [x] invalid/empty/missing argument -> die
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Test::More qw( no_plan );
use Test::Exception;


use_ok( 'Goodscrapes' );


is( gverifyuser( '123'          ), '123', 'Valid user ID'     );
is( gverifyuser( '123-username' ), '123', 'Sanitized user ID' );

dies_ok( sub{ gverifyuser( 'username' ); }, 'Invalid user ID' );
dies_ok( sub{ gverifyuser( ''         ); }, 'Empty user ID'   );
dies_ok( sub{ gverifyuser( undef      ); }, 'Missing user ID' );


is( gverifyshelf( 'myshelf' ), 'myshelf', 'Valid shelf name' );

dies_ok( sub{ gverifyshelf( '^@#' ); }, 'Invalid shelf name' );
dies_ok( sub{ gverifyshelf( ''    ); }, 'Empty shelf name'   );
dies_ok( sub{ gverifyshelf( undef ); }, 'Missing shelf name' );


