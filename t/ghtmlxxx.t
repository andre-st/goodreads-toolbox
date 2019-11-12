#!/usr/bin/perl -w

# Test cases realized:
#   [x] HTML safe strings
#   [ ] 
#   [ ] 
#   [ ] 

use diagnostics;  # More debugging info
use warnings;
use strict;
use Test::More qw( no_plan );
use FindBin;
use lib "$FindBin::Bin/../lib/";

use_ok( 'Goodscrapes' );

my %user;
my %book;

$user{name}      = '<script>alert("User Name XSS");</script>';
$user{num_books} = 100;
$user{url}       = '"><script>alert("User URL XSS");</script>';
$book{title}     = '<script>alert("Book Title XSS");</script>';
$book{stars}     = 4;
$book{url}       = '"><script>alert("Book URL XSS");</script>';
$book{rh_author} = \%user;


# Also example of functions inside string interpolations:
my $test = qq{
	<html>
	<body>
		${\ghtmlsafe( $book{title}                  )}
		${\ghtmlsafe( $book{stars}                  )}
		${\ghtmlsafe( $book{url}                    )}
		${\ghtmlsafe( $book{rh_author}->{name}      )}
		${\ghtmlsafe( $book{rh_author}->{num_books} )}
		${\ghtmlsafe( $book{rh_author}->{url}       )}
	</body>
	</html>
};

my $expected = qq{
	<html>
	<body>
		&lt;script&gt;alert(&quot;Book Title XSS&quot;);&lt;/script&gt;
		4
		&quot;&gt;&lt;script&gt;alert(&quot;Book URL XSS&quot;);&lt;/script&gt;
		&lt;script&gt;alert(&quot;User Name XSS&quot;);&lt;/script&gt;
		100
		&quot;&gt;&lt;script&gt;alert(&quot;User URL XSS&quot;);&lt;/script&gt;
	</body>
	</html>
};


is( $test, $expected );

