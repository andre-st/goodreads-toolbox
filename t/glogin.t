#!/usr/bin/perl -w

# Test cases realized:
#   [x] login and get correct user-id
#   [ ] 
#   [ ] 
#   [ ] 


use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use List::MoreUtils qw( any firstval );
use FindBin;
use lib "$FindBin::Bin/../lib/";
use lib "$FindBin::Bin/../t/";

use_ok( 'Goodscrapes' );
require( 'config.pl' );


my $userid_extracted;
my $userid_expected = get_gooduser_id();

glogin( usermail => get_gooduser_mail(),
        userpass => get_gooduser_pass(),
        r_userid => \$userid_extracted );

is( $userid_extracted, $userid_expected, 'Got correct user ID after login' );


