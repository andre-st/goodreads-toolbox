#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

friendrated.pl 

=head1 VERSION
	
2018-05-12 (Since 2018-05-10)

=head1 ABOUT

see friendrated.md

=cut

###############################################################################


use strict;
use warnings;
use 5.18.0;


use FindBin;
use lib "$FindBin::Bin/";
use Time::HiRes qw( time tv_interval );
use Goodscrapes;


say STDERR "Usage: $0 GOODUSERNUMBER [OUTXMLPATH] [MINFAVORERS] [MINRATING]" and exit if $#ARGV < 0;

our $_good_user    = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $_out_path     = $ARGV[1] || "$_good_user.xml";
our $_min_favorers = $ARGV[2] || 3;
our $_min_rating   = $ARGV[3] || 4;  # Highly rated books only (4 and 5 stars)
our $_cookie_path  = 'friendrated.cookie';
our $_shelf        = 'read';
our $_tstart       = time();

# Followed and friend list is private, some 'Read' shelves are private
set_good_cookie_file( $_cookie_path );  

# Don't scrape everything again on mistakes or parameter changes or power
# blackout or when I break ^C and continue at a later timepoint.
set_good_cache( '21 days' );

# Don't wait for \n
STDOUT->autoflush( 1 );



# Collect user data:
# 
print STDOUT "Getting list of users known to #${_good_user}... ";

my $t0           = time();
my %people       = query_good_followees( $_good_user );
my @people_ids   = keys %people;
my $people_count = scalar @people_ids;
my $people_done  = 0;

printf STDOUT "%d users (%.2fs)\n", $people_count, time()-$t0;



# Collect book data:
# 
my %books;      # {bookid} => %book
my %faved_for;  # {bookid}{favorerid}
                # favorers hash-type because of uniqueness;

foreach my $pid (@people_ids)
{
	$people_done++;
	my $p = $people{$pid};
	
	next if $p->{is_author};  # Just normal members
	
	printf STDOUT "[%3d%%] %-25s #%-10s\t", $people_done/$people_count*100, $p->{name}, $pid;
	
	my $t0   = time();
	my @bok  = query_good_books( $pid, $_shelf );
	my $nfav = 0;
		
	foreach my $b (@bok)
	{
		next if $b->{user_rating} < $_min_rating;
		$nfav++;
		$faved_for{ $b->{id} }{ $pid } = 1;
		$books{ $b->{id} } = $b;
	}
	
	printf STDOUT "%4d %s\t%4d favs\t%.2fs\n", scalar( @bok ), $_shelf, $nfav, time()-$t0;
}

say STDOUT "\nPerfect! Got favourites of ${people_done} users.";



# Write results to XML file:
# 
print STDOUT "Writing results to \"$_out_path\"... ";
my $num_finds = 0;
open( my $fh, '>', $_out_path );

say $fh '<?xml version="1.0" encoding="UTF-8"?>';
say $fh # Document program arguments in result file:
		'<good generator="friendrated.pl"' .
		' version="1.0"'                   .
		" customer=\"$_good_user\""        .
		" minfavorers=\"$_min_favorers\""  .
		" minrating=\"$_min_rating\" >";

say $fh "\t<users>";
foreach my $pid (@people_ids)
{
	printf $fh 
			"\t\t<user id=\"%s\">\n"  .
			"\t\t\t<name>%s</name>\n" .
			"\t\t\t<url>%s</url>\n"   .
			"\t\t\t<img>%s</img>\n"   .
			"\t\t</user>\n",
			$pid,
			$people{$pid}->{name},
			$people{$pid}->{profile_url},
			$people{$pid}->{img_url};
}
say $fh "\t</users>";
say $fh "\t<books>";
foreach my $bid (keys %faved_for)
{
	my @favorer_ids  = keys $faved_for{$bid};
	my $num_favorers = scalar @favorer_ids;
	
	next if $num_favorers < $_min_favorers;
	$num_finds++;
	
	say $fh "\t\t<book id=\"$bid\">";
	printf $fh 
			"\t\t\t<mentions>%d</mentions>\n" .
			"\t\t\t<title>%s</title>\n"       .
			"\t\t\t<url>%s</url>\n"           .
			"\t\t\t<img>%s</img>\n",
			$num_favorers,
			$books{$bid}->{title},
			$books{$bid}->{url},
			$books{$bid}->{img_url};
	
	say $fh "\t\t\t<favorers>";
	say $fh "\t\t\t\t<user id=\"$_\" />" foreach (@favorer_ids);
	say $fh "\t\t\t</favorers>";
	say $fh "\t\t</book>";
}
say $fh "\t</books>";
say $fh '</good>';

close $fh;
printf STDOUT "%d books\n", $num_finds;


# Good bye.
# 
printf STDOUT "Total time: %.0f minutes\n", (time()-$_tstart)/60;



