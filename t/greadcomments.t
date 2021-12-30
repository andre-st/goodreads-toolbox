#!/usr/bin/perl -w

# Test cases realized:
# [ ] ...


use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
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


# Info is only available to authenticated users:
glogin( usermail => get_gooduser_mail(),
        userpass => get_gooduser_pass() );


print( 'Reading comments... ');


my @comments;

greadcomments( from_user_id  => 18418712, # 1036726,
               ra_into       => \@comments,
               on_progress   => gmeter( 'comments' ));


print( "\n" );



ok( scalar( @comments ) >= 10, 'At least 10 books read from shelf' );

for my $c ( @comments )
{
	ok( $c->{text}, 'Comment has text' );
	
	if( $c->{rh_to_user} )  # No user info if comment on a group
	{
		ok  ( $c->{rh_to_user},         'Comment has an addressee'      );
		ok  ( $c->{rh_to_user}->{name}, 'Addressee of comment has name' );
	}
	
	if( $c->{rh_book} )  # No book info if comment on a group or a quote or a user status
	{
		ok  ( $c->{rh_book}->{title},                                        'Commented book has title'       );
		like( $c->{rh_book}->{img_url}, qr/^https:.*\.(jpg|png)$/,           'Commented book has image URL'   );
		like( $c->{rh_book}->{url},     qr/^https:\/\/www.goodreads.com\//,  'Commented book has an URL'      );  # Not real URL but search-URL due to missing book ID
		
		ok  ( $c->{rh_review}.                                               'Comment addressed a review'     );
		ok  ( $c->{rh_review}->{id},                                         'Commented review has an ID'     );
		like( $c->{rh_review}->{url},   qr/^https:\/\/www.goodreads.com\//,  'Commented review has an URL'    ); 
		ok  ( $c->{rh_review}->{rh_user},                                    'Commented review has an author' );
		ok  ( $c->{rh_review}->{rh_user}->{name},                            'Author of commented review has a name' );
		
		
		# Not available or scraped yet, otherwise one of the following
		# tests will fail and remind me of implementing a correct test:
		
		is  ( $c->{rh_book}->{id},  undef,  'N/A: Book ID' );
	}

}




