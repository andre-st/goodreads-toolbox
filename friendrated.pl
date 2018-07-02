#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

friendrated.pl 

=head1 VERSION
	
2018-06-25 (Since 2018-05-10)

=head1 ABOUT

see friendrated.md

=cut

###############################################################################

use strict;
use warnings;
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX qw( strftime );
use IO::File;
use Goodscrapes;


# Program synopsys:
say STDERR "Usage: $0 GOODUSERNUMBER [OUTFILE] [MINFAVORERS] [MINRATING]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER    = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $OUTPATH     = $ARGV[1] || "friendrated-${GOODUSER}.html";
our $MINFAVORERS = $ARGV[2] || 3;
our $MINRATING   = $ARGV[3] || 4;  # Highly rated books only (4 and 5 stars)
our $FRIENDSHELF = 'read';
our $TSTART      = time();

# Followed and friend list is private, some 'Read' shelves are private
set_good_cookie_file();  
set_good_cache( '21 days' );
STDOUT->autoflush( 1 );



#-----------------------------------------------------------------------------
# Collect user data:
#
print "Getting list of users known to #${GOODUSER}... ";

my $t0         = time();
my %people     = query_good_followees( $GOODUSER );
my @people_ids = keys %people;
my $pplcount   = scalar @people_ids;
my $ppldone    = 0;

printf "%d users (%.2fs)\n", $pplcount, time()-$t0;

die "Invalid user number or cookie? Try empty /tmp/FileCache/" if $pplcount == 0;



#-----------------------------------------------------------------------------
# Collect book data:
# 
my %books;      # {bookid} => %book
my %faved_for;  # {bookid}{favorerid}
                # favorers hash-type because of uniqueness;

foreach my $pid (@people_ids)
{
	$ppldone++;
	my $p = $people{$pid};
	
	next if $p->{is_author};  # Just normal members
	
	printf "[%3d%%] %-25s #%-10s\t", $ppldone/$pplcount*100, $p->{name}, $pid;
	
	my $t0   = time();
	my @bok  = query_good_books( $pid, $FRIENDSHELF );
	my $nfav = 0;
		
	foreach my $b (@bok)
	{
		next if $b->{user_rating} < $MINRATING;
		$nfav++;
		$faved_for{ $b->{id} }{ $pid } = 1;
		$books{ $b->{id} } = $b;
	}
	
	printf "%4d %s\t%4d favs\t%6.2fs\n", scalar( @bok ), $FRIENDSHELF, $nfav, time()-$t0;
}

say "\nPerfect! Got favourites of ${ppldone} users.";



#-----------------------------------------------------------------------------
# Write results to HTML file:
# 
print "Writing results to \"$OUTPATH\"... ";

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "FATAL: Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );

print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title> Books common among friends and followees </title>
		</head>
		<body style="font-family: sans-serif;">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Books rated 
		  $MINRATING or better, by
		  $MINFAVORERS+ friends or followees of member
		  $GOODUSER, on $now
		</caption>
		<tr>
		<th>#</th> 
		<th>Cover</th>
		<th>Title</th>
		<th>Rated</th>
		<th>Rated by</th>
		</tr>
		};

my $num_finds = 0;
foreach my $bid (sort { scalar keys $faved_for{$b} <=> 
                        scalar keys $faved_for{$a} } keys %faved_for)
{
	my @favorer_ids  = keys $faved_for{$bid};
	my $num_favorers = scalar @favorer_ids;
	
	next if $num_favorers < $MINFAVORERS;
	$num_finds++;
	
	print $fh qq{
			<tr>
			<td          >$num_finds</td>
			<td><img src="$books{$bid}->{img_url}"></td>
			<td><a  href="$books{$bid}->{url}" target="_blank"
			             >$books{$bid}->{title}</a></td>
			<td          >${num_favorers}x</td>
			<td>
			};
	
	print $fh qq{
			<a  href="$people{$_}->{url}"     target="_blank">
			<img src="$people{$_}->{img_url}" 
			   title="$people{$_}->{name}">
			</a>
			} foreach (@favorer_ids);
	
	print $fh qq{
			</td>
			</tr> 
			};
}

print $fh qq{
		</table>
		</body>
		</html> 
		};

undef $fh;


printf "%d books\n", $num_finds;
printf "Total time: %.0f minutes\n", (time()-$TSTART)/60;




