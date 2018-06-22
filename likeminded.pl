#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

likeminded.pl 

=head1 VERSION
	
2018-06-21 (Since 2018-06-21)

=head1 ABOUT

see likeminded.md

=cut

###############################################################################

use strict;
use warnings;
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Goodscrapes;


# Program synopsis
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [SIMILARITY]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $SHELF    = $ARGV[1] || '%23ALL%23';
our $MINSIMIL = $ARGV[2] || 3;  # between 0 and 100 (exact match)
our $TSTART   = time();

set_good_cache( '21 days' );
STDOUT->autoflush( 1 );



printf "Loading books from \"%s\" may take a while...\n", $SHELF;
my @books       = query_good_books( $GOODUSER, $SHELF );
my $books_count = scalar @books;
my $books_done  = 0;
my %seen;       # {userid => count}


printf "Loading reviews for %d books:\n", $books_count;
foreach my $b (@books)
{
	printf "[%3d%%] %-45s\t", ++$books_done/$books_count*100, substr( $b->{title}, 0, 45 );
	
	my $t0   = time();
	my @revs = query_good_reviews( $b->{id} );
	
	printf "%4d memb\t%.2fs\n", scalar @revs, time()-$t0;
		
	$seen{ $_->{user}->{id} }++ foreach (@revs);
}


printf "\nMembers (N=%d) with %d%% similarity or better:\n", scalar keys %seen, $MINSIMIL;
my $line = 1;
foreach my $userid (sort { $seen{$a} <=> $seen{$b} } keys %seen) 
{
	my $simil = $seen{ $userid }/$books_count*100;
	
	next if $userid == $GOODUSER;
	next if $simil  <  $MINSIMIL;
	
	printf "%2d.\t%3d books\t%2d%%\thttps://www.goodreads.com/user/show/%s\n", 
			$line++, $seen{ $userid }, $simil, $userid;
}


printf "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60;
