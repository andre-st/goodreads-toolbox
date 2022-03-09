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


diag( "Tests TODO" );
ok( 1 );


