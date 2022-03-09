#!/usr/bin/perl -w

# Test cases realized:
#   [x] read all shelf names of another Goodreads member, exclude some shelves


use diagnostics;  # More debugging info
use warnings;
use strict;
use FindBin;
use local::lib "$FindBin::Bin/../lib/local/";
use        lib "$FindBin::Bin/../lib/";
use        lib "$FindBin::Bin/../t/";
use Test::More      qw( no_plan  );
use List::MoreUtils qw( any none );


use_ok( 'Goodscrapes' );
require( 'config.pl' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days => 1 );


# At the moment, functionality is just available to signed-in users:
glogin( usermail => get_gooduser_mail(),
        userpass => get_gooduser_pass() );


# Because scraping *all* shelf names is more nasty than you would expect,
# it got its own command (more commentary see function in Goodscrapes.pm):
my @shelfnames;

greadshelfnames( from_user_id => '1',     # Otis Chandler
                 ra_into      => \@shelfnames,
                 ra_exclude   => [ 'to-read', 'nonfiction' ]);


# Otis Chandler has so many shelves that they are paginated. 
# This test includes some shelves from page 2 too:
ok( (any { $_ eq 'read'              } @shelfnames),  'User has shelf' );
ok( (any { $_ eq 'currently-reading' } @shelfnames),  'User has shelf' );
ok( (any { $_ eq 'health'            } @shelfnames),  'User has shelf' );
ok( (any { $_ eq 'submarine'         } @shelfnames),  'User has shelf' );
ok( (any { $_ eq 'travel'            } @shelfnames),  'User has shelf' );
ok( (none{ $_ eq 'to-read'           } @shelfnames),  'User shelf was excluded');
ok( (none{ $_ eq 'nonfiction'        } @shelfnames),  'User shelf was excluded' );

