#!/usr/bin/perl -w

# Test cases realized:
#   [x] shelf name corrections (displayed name vs real ids)
#   [ ] invalid shelves
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict; 
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use Test::More qw( no_plan );


use_ok( 'Goodscrapes' );

# Internal vs displayed shelf names for default GR shelves:

is  ( gverifyshelf( '#ALL#'   ), '#ALL#', 'Shelf valid'         );
is  ( gverifyshelf( 'AlL'     ), '#ALL#', 'Shelf corrected'     );
is  ( gverifyshelf( '#AlL'    ), '#ALL#', 'Shelf corrected'     );
isnt( gverifyshelf( 'all-x'   ), '#ALL#', 'Shelf not corrected' );
isnt( gverifyshelf( 'x-all'   ), '#ALL#', 'Shelf not corrected' );
isnt( gverifyshelf( 'x-all-x' ), '#ALL#', 'Shelf not corrected' );

is  ( gverifyshelf( 'read'     ), 'read',  'Shelf valid'         );
is  ( gverifyshelf( 'ReAd'     ), 'read',  'Shelf corrected'     );
isnt( gverifyshelf( 'x-read'   ), 'read',  'Shelf not corrected' );
isnt( gverifyshelf( 'read-x'   ), 'read',  'Shelf not corrected' );
isnt( gverifyshelf( 'x-read-x' ), 'read',  'Shelf not corrected' );

is  ( gverifyshelf( 'currently-reading'     ), 'currently-reading', 'Shelf valid'         );
is  ( gverifyshelf( 'CurrEntly_ReAding'     ), 'currently-reading', 'Shelf corrected'     );
isnt( gverifyshelf( 'x-currently-reading'   ), 'currently-reading', 'Shelf not corrected' );
isnt( gverifyshelf( 'currently-reading-x'   ), 'currently-reading', 'Shelf not corrected' );
isnt( gverifyshelf( 'x-currently-reading-x' ), 'currently-reading', 'Shelf not corrected' );

is  ( gverifyshelf( 'to-read'      ), 'to-read', 'Shelf valid'         );
is  ( gverifyshelf( 'tO_ReaD'      ), 'to-read', 'Shelf corrected'     );
is  ( gverifyshelf( 'Want-To_ReAd' ), 'to-read', 'Shelf corrected'     );  # You could have such a shelf but misspelling more likely 
isnt( gverifyshelf( 'x-to-read'    ), 'to-read', 'Shelf not corrected' );
isnt( gverifyshelf( 'to-read-x'    ), 'to-read', 'Shelf not corrected' );
isnt( gverifyshelf( 'x-to-read-x'  ), 'to-read', 'Shelf not corrected' );


# User created shelves:

is( gverifyshelf( 'UsEr_CreaTed-shElf' ), 'user_created-shelf', 'Shelf "UsEr_CreaTed-shElf" corrected to lowercase' );


# Invalid shelves:

# @TODO







