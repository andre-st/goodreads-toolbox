#!/usr/bin/perl -w

# Test cases realized:
#   [x] get friends and followees
#   [x] get friends only
#   [x] get followees only
#   [ ] get only friends who are authors
#   [ ] get only followees who are authors
#   [ ] discard threshold
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


# Access to member lists needs some privileges:
glogin( usermail => get_gooduser_mail(),
        userpass => get_gooduser_pass() );


my $userid = '2'; 
my %friends;
my %followees;
my %all;

greadfolls( from_user_id   => $userid,
            rh_into        => \%friends, 
            incl_followees => 0,
            incl_friends   => 1,
            incl_authors   => 1 );

greadfolls( from_user_id   => $userid,
            rh_into        => \%followees,
            incl_followees => 1,
            incl_friends   => 0,
            incl_authors   => 1 );

greadfolls( from_user_id   => $userid,
            rh_into        => \%all,
            incl_followees => 1,
            incl_friends   => 1,
            incl_authors   => 1 );


ok( exists $friends{1},                             "Member $userid and Otis Chandler are friends" );
ok( exists $followees{21269},                       "Member $userid is following Guy Kawasaki (author)" );
ok( exists $friends{1} && exists $followees{21269}, "Member $userid is friends with Otis Chandler and is following Guy Kawasaki (author)" );


my @kfriends   = keys %friends;
my @kfollowees = keys %followees;
my @kall       = keys %all;


my @dups = duplicates(( @kfriends, @kfollowees ));
ok( !@dups, 'Friends and followees lists expected to be exclusive' );

my @dups2 = duplicates(( @kfriends, @kfollowees, @kall ));
is( scalar( @kall ), scalar( @dups2 ), 'Friends and followees in all-list expected' );


