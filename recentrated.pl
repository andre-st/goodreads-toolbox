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
use lib "$FindBin::Bin/";
use Log::Any '$_log', default_adapter => [ 'File' => '/var/log/good.log' ];
use Text::CSV qw( csv );
use Time::Piece;
use Goodscrapes;


# Program synopsis:
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [MAILTO] [MAILFROM]" and exit if $#ARGV < 0;

# Program configuration:
our $_good_user  = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $_good_shelf = $ARGV[1] || '%23ALL%23';
our $_mail_to    = $ARGV[2];
our $_mail_from  = $ARGV[3];
our $_csv_path   = "/var/db/good/${_good_user}-${_good_shelf}.csv";

# the more URLs, the longer and untempting the mail
our $_max_rev_urls_per_book = 2;

# URLs in mail padded to average length, with "https://" stripped
sub pretty_url { return sprintf '%-36s', substr( shift, 8 ); }

# effect in dev/debugging only
set_good_cache( '4 hours' );



my $csv      = ( -e $_csv_path  ?  csv( in => $_csv_path, key => 'id' )  :  undef );  # ref
my @books    = query_good_books( $_good_user, $_good_shelf );
my $num_hits = 0;

if( $csv )
{
	my $mtime = (stat $_csv_path)[9];
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
		if( $_mail_to && $num_hits == 1 )
		{
			print "To: ${_mail_to}\n";
			print "From: ${_mail_from}\n"                       if $_mail_from;
			print "List-Unsubscribe: <mailto:${_mail_from}>\n"  if $_mail_from;
			print "Subject: New ratings on Goodreads.com\n\n";  # 2x \n hdr end
			print "Recently rated books in your \"${_good_shelf}\" shelf:\n";
		}
		
		# "Book Title1"
		#  www.goodreads.com/book/show/609606   [12 new]
		#  
		# "Book Title2"
		#  www.goodreads.com/user/show/1234567  ***--  Joe User
		#  www.goodreads.com/user/show/2345     *****  Lisa Jane
		#
		printf "\n  \"%s\"\n", $b->{title};
		
		if( scalar @revs > $_max_rev_urls_per_book )
		{
			printf "   %s  [%d new]\n", 
					pretty_url( $b->{url} ),
					scalar @revs;
		}
		else
		{
			printf "   %s  %s  %s\n", 
					pretty_url( $_->{user}->{profile_url} ),
					$_->{rating_str},
					$_->{user}->{name}
				foreach (@revs);
		}
	}
	
	# E-mail signature if run for other users:
	if( $_mail_from && $num_hits > 0 )
	{
		print "\n\n--\n" 
		    . " Just reply 'unsubscribe' to unsubscribe.\n" 
		    . "  Suggestions? Just reply to this e-mail.\n"
		    . "   Add new books to your shelf at any time.\n"
		    . "    Via https://andre-st.github.io/goodreads/\n";
	}
	
	# Cronjob audits:
	$_log->infof( 'Recently rated: %d of %d books in %s\'s shelf "%s"', 
			$num_hits, scalar @books, $_good_user, $_good_shelf );
}

csv( in => \@books, out => $_csv_path, headers => [qw( id num_ratings )] );

