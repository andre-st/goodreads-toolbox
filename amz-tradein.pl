#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

amz-tradein.pl


=head1 VERSION

2015-08-31 (Since 2014-11-05)

	
=head1 WARNING

Amazon stopped its Trade-In program on 31th August, 2015. 
This script is no longer of any use.


=head1 PURPOSE

=over

=item * fetches Amazon Trade-In prices for all books in a Goodreads-shelf, 
        e.g., 'books-for-sale'

=item * spares you checking each book by hand every time you want to sell 
        books to Amazon

=item * might reveal good buyback prices for books you hadn't yet considered 
        for sales (run this script against a Goodreads "#ALL#" shelf)

=back


=head1 OUTPUT EXAMPLE

  EUR 5,30  Book title found at Amazon with Trade-In price
  EUR -,--  Book title either without Trade-In or not found by ISBN


=head1 USAGE EXAMPLE

=over

=item Check all books of a specific Goodreads user:

$ amz-tradein.pl 18418712

=item Check all books in a specific Goodreads shelf only:

$ amz-tradein.pl 18418712 books-for-sale

=item Sort by highest price and save outout to a textfile:

$ amz-tradein.pl 18418712 books-for-sale | sort --key 2n | tac > books-for-sale-w-prices.out

=back


=head1 OBSERVATIONS

=over

=item * process is slow, 123 books need ~2 minutes

=back

	
=head1 REQUIRES

=over

=item * a Goodreads account (number), your # is contained in each Goodreads-shelf-URL

=item * no API key

=item * $ perl -MCPAN -e 'install WWW::Curl::Easy, Cache::FileCache'

=back

	
=head1 KNOWN LIMITATIONS AND BUGS

=over

=item * german Amazon only (contact me if you need support for other countries)

=back
	
=cut

###############################################################################


use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/";
use Goodscrapes;


say STDERR "Usage: $0 GOOD_USER_NUMBER [GOOD_SHELF]\nSee source code for more info." and exit if $#ARGV < 0;

our $_good_user  = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $_good_shelf = $ARGV[1] || '%23ALL%23';
our $_is_debug   = 0;


sub extract_amz_price
{
	my $article_page_html = shift;
	return( $article_page_html =~ /(EUR [0-9,]+)<\/span> Gutschein erhalten/ )[0]  ||  'EUR -,--';
}


my @books = query_good_books( $_good_user, $_good_shelf );
foreach my $b (@books)
{
	my $price = extract_amz_price( amz_book_html( $b ) );
	say STDOUT $price . "\t" . $b->{title};
}

