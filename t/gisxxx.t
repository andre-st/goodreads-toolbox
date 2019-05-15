#!/usr/bin/perl -w

# Test cases realized:
#   [x] Good profiles, bad profiles
#   [ ] unexpected values (undef etc)
#   [ ] 
#   [ ] 



use diagnostics;  # this gives you more debugging information
use warnings;
use strict; 
use Test::More qw( no_plan );  # for the ok( bool, testname ), is( x, expected, testname ) and isnt() functions
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


ok( !gisbaduser( '1'       ), 'Otis Chandler (GR founder)' );
ok( !gisbaduser( '2'       ), 'Goodreads employee'         );
ok(  gisbaduser( '1000834' ), '"NOT A BOOK" author'        );
ok(  gisbaduser( '5158478' ), '"Anonymous" author'         );





