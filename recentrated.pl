#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

recentrated.pl - Searches a Goodreads.com shelf for new book-ratings

=head1 VERSION

2018-05-17 (Since 2018-01-09)

=head1 ABOUT

see recentrated.md

=cut

###############################################################################


use strict;
use warnings;
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Log::Any '$_log', default_adapter => [ 'File' => '/var/log/good.log' ];
use Text::CSV qw( csv );
use Time::Piece;
use Goodscrapes;


# Program synopsis:
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [MAILTO] [MAILFROM]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER  = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $GOODSHELF = $ARGV[1] || '%23ALL%23';
our $MAILTO    = $ARGV[2];
our $MAILFROM  = $ARGV[3];
our $CSVPATH   = "/var/db/good/${GOODUSER}-${GOODSHELF}.csv";

# The more URLs, the longer and untempting the mail.
# If number exceeded, we link to the book page with *all* reviews.
our $MAX_REVURLS_PER_BOOK = 2;

# GR-URLs in mail padded to average length, with "https://" stripped
sub pretty_url { return sprintf '%-36s', substr( shift, 8 ); }

# effect in dev/debugging only
set_good_cache( '4 hours' );



my $csv      = ( -e $CSVPATH  ?  csv( in => $CSVPATH, key => 'id' )  :  undef );  # ref
my @books    = query_good_books( $GOODUSER, $GOODSHELF );
my $num_hits = 0;

if( $csv )
{
	my $mtime = (stat $CSVPATH)[9];
	my $since = Time::Piece->strptime( $mtime, '%s' );
	
	foreach my $b (@books)
	{
		next if !exists $csv->{$b->{id}};
		
		my $num_new_rat = $b->{num_ratings} - $csv->{$b->{id}}->{num_ratings};
		
		next if $num_new_rat <= 0;
	
		my @revs = query_good_reviews( $b->{id}, $since );
		
		next if !@revs;  # Number of ratings increased but no new reviews, what's that?
		
		$num_hits++;
		
		# E-Mail header and first body line:
		if( $MAILTO && $num_hits == 1 )
		{
			print "To: ${MAILTO}\n";
			print "From: ${MAILFROM}\n"                       if $MAILFROM;
			print "List-Unsubscribe: <mailto:${MAILFROM}>\n"  if $MAILFROM;
			print "Content-Type: text/plain; charset=utf-8\n";
			print "Subject: New ratings on Goodreads.com\n\n";  # 2x \n hdr end
			print "Recently rated books in your \"${GOODSHELF}\" shelf:\n";
		}
		
		
		#  ASCII design isn't responsive, and the GMail web client neither uses fixed
		#  width fonts nor treats multiple space characters as defined, even on large
		#  screens. It treats plain text mails as HTML text. I don't do HTML mails,
		#  so mobile GMail web users will have the disadvantage.
		#
		#<-------------------- 78 chars per line i.a.w. RFC 2822 --------------------->
		#
		#  "Book Title1"
		#   www.goodreads.com/book/show/609606   [9 new]
		#  
		#  "Book Title2"
		#   www.goodreads.com/user/show/1234567  [TTT  ]
		#   www.goodreads.com/user/show/2345     [*****]
		#
		printf "\n  \"%s\"\n", $b->{title};
		
		if( scalar @revs > $MAX_REVURLS_PER_BOOK )
		{
			printf "   %s  [%d new]\n", pretty_url( $b->{url} ), scalar @revs;
		}
		else
		{
			printf "   %s  %s\n", pretty_url( $_->{user}->{url} ), $_->{rating_str}
				foreach (@revs);
		}
	}
	
	# E-mail signature block if run for other users:
	if( $MAILFROM && $num_hits > 0 )
	{
		print "\n\n-- \n"  # RFC 3676 sig delimiter (w/ space char)
		    . " [***  ] 3/5 stars rating without text      \n"
		    . " [TTT  ] 3/5 stars rating with add. text    \n"
		    . " [9 new] ratings better viewed on book page \n"
		    . "                                            \n"
		    . " Just reply 'unsubscribe' to unsubscribe.   \n" 
		    . " Add new books to your shelf at any time.   \n"
		    . " Via https://andre-st.github.io/goodreads/  \n";
	}
	
	# Cronjob audits:
	$_log->infof( 'Recently rated: %d of %d books in %s\'s shelf "%s"', 
			$num_hits, scalar @books, $GOODUSER, $GOODSHELF );
}

csv( in => \@books, out => $CSVPATH, headers => [qw( id num_ratings )] );

