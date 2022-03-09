#!/usr/bin/perl -w

# Test cases realized:
#   [x] Good profiles, bad profiles
#   [x] unexpected values (undef etc)
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


ok( !gisbaduser( '1'       ), 'Otis Chandler (GR founder)' );
ok( !gisbaduser( '2'       ), 'Goodreads employee'         );
ok(  gisbaduser( '1000834' ), '"NOT A BOOK" author'        );
ok(  gisbaduser( '5158478' ), '"Anonymous" author'         );
ok(  gisbaduser( undef     ), 'Invalid value is bad'       );




