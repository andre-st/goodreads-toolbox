#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

recentrated.pl - Searches a Goodreads.com shelf for new book-ratings

=head1 VERSION

2018-05-15 (Since 2018-01-09)

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


say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [MAILTO] [MAILFROM]" and exit if $#ARGV < 0;


our $_good_user  = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $_good_shelf = $ARGV[1] || '%23ALL%23';
our $_mail_to    = $ARGV[2];
our $_mail_from  = $ARGV[3];
our $_csv_path   = "/var/db/good/${_good_user}-${_good_shelf}.csv";


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
		
		# "Book Title"
		#  https://www.goodreads.com/book/show/609606
		#  https://www.goodreads.com/user/show/1234567  ***--  Joe User
		#  https://www.goodreads.com/user/show/2345     *****  Lisa Jane
		#
		my @revs = query_good_reviews( $b->{id}, $since );
		printf "\n  \"%s\"\n", $b->{title};
		printf "   %s\n", $b->{url};
		printf "   %-45s  %s  %s\n", 
				$_->{user}->{profile_url},
				$_->{rating_str},
				$_->{user}->{name}
			foreach (@revs);
	}
	
	# E-mail signature if run for other users:
	if( $_mail_from && $num_hits > 0 )
	{
		print "\n\n--\n" 
		    . " This is an automatically generated email.\n" 
		    . "  Just reply 'unsubscribe' to unsubscribe.\n" 
		    . "   Add new books to your shelf at any time.\n"
		    . "    Via https://andre-st.github.io/goodreads/\n";
	}
	
	# Cronjob audits:
	$_log->infof( 'Recently rated: %d of %d books in %s\'s shelf "%s"', 
			$num_hits, scalar @books, $_good_user, $_good_shelf );
}

csv( in => \@books, out => $_csv_path, headers => [qw( id num_ratings )] );

