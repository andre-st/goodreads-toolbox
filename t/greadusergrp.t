#!/usr/bin/perl -w

# Test cases realized:
#   [x] Read groups and check attributes (detects changed markup)
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


use_ok( 'Goodscrapes' );


# We should never use caching during real tests:
# We need to test against the most up-to-date markup from Goodreads.com
# Having no cache during development is annoying, tho. 
# So we leave a small window:
gsetopt( cache_days => 1 );


print( "Getting groups... " );

my %groups;
	
greadusergp( from_user_id => '1',  # "Otis Chandler" (GR founder)
             rh_into      => \%groups,
		   # on_group   => sub{},
             on_progress  => gmeter( 'groups' ));

print( "\n" );

ok( scalar( keys( %groups )) > 70, 'At least 70 groups (3 pages)' );  # Chandler had 127

ok( exists( $groups{8095} ), 'Expected group found via hash-key = Goodreads group ID' )
	or BAIL_OUT( "Cannot test group attributes when expected group is missing." );

my $g = $groups{8095};

is( $g->{id},         '8095',                                      'Group has Goodreads ID'      );
is( $g->{name},       'Goodreads Developers',                      'Group has name'              );
ok( $g->{num_members} > 1000,                                      'Group has number of members' );
is( $g->{url},        'https://www.goodreads.com/group/show/8095', 'Group has URL'               );
is( $g->{img_url},    'https://images.gr-assets.com/groups/1220414390p2/8095.jpg', 'Group has image URL' );






