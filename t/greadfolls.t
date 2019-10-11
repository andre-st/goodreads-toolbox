#!/usr/bin/perl -w

# Test cases realized:
#   [x] get friends and followees
#   [x] get friends only
#   [x] get followees only
#   [ ] get only friends who are authors
#   [ ] get only followees who are authors
#   [x] discard threshold
#   [ ] check member attributees



use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use List::MoreUtils qw( duplicates );
use FindBin;
use lib "$FindBin::Bin/../lib/";
use lib "$FindBin::Bin/../t/";

use_ok( 'Goodscrapes' );
require( 'config.pl' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days => 1 );


# Access to member lists needs some privileges:
glogin( usermail => get_gooduser_mail(),
        userpass => get_gooduser_pass() );


my $userid            = '2'; 
my $discard_threshold = 3;
my %friends;
my %followees;
my %all;
my %discarded_friends;
my %discarded_followees;


greadfolls( from_user_id      => $userid,
            rh_into           => \%friends, 
            incl_followees    => 0,
            incl_friends      => 1,
            incl_authors      => 1 );

greadfolls( from_user_id      => $userid,
            rh_into           => \%followees,
            incl_followees    => 1,
            incl_friends      => 0,
            incl_authors      => 1 );

greadfolls( from_user_id      => $userid,
            rh_into           => \%all,
            incl_followees    => 1,
            incl_friends      => 1,
            incl_authors      => 1 );

greadfolls( from_user_id      => $userid,
            rh_into           => \%discarded_friends,
            discard_threshold => $discard_threshold,
            incl_followees    => 0,
            incl_friends      => 1,
            incl_authors      => 1 );

greadfolls( from_user_id      => $userid,
            rh_into           => \%discarded_followees,
            discard_threshold => $discard_threshold,
            incl_followees    => 1,
            incl_friends      => 0,
            incl_authors      => 1 );


ok( exists $friends{1},                             "Member $userid and Otis Chandler are friends" );
ok( exists $followees{21269},                       "Member $userid is following Guy Kawasaki (author)" );
ok( exists $friends{1} && exists $followees{21269}, "Member $userid is friends with Otis Chandler and is following Guy Kawasaki (author)" );
ok( !%discarded_friends,                            "No friends returned if there are more than $discard_threshold" );
ok( !%discarded_followees,                          "No followees returned if there are more than $discard_threshold" );


my @kfriends   = keys %friends;
my @kfollowees = keys %followees;
my @kall       = keys %all;

ok( !duplicates(( @kfriends, @kfollowees )), 'Friends and followees lists expected to be exclusive' );

is( scalar(@kall), scalar(duplicates(( @kfriends, @kfollowees, @kall ))), 'Friends and followees in all-list expected' );






