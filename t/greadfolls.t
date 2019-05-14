#!/usr/bin/perl -w

# Test cases realized:
#   [x] 
#   [ ] 
#   [ ] 
#   [ ] 



use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Test::More qw( no_plan ); # for the ok( bool, testname ), is( x, expected, testname ) and isnt() functions
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";


use_ok( 'Goodscrapes' );


diag( "Tests TODO" );
ok( 1 );


