#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

likeminded.pl 

=head1 VERSION
	
2018-07-02 (Since 2018-06-22)

=head1 ABOUT

see likeminded.md

=cut

###############################################################################

use strict;
use warnings;
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime );
use IO::File;
use Goodscrapes;


# Program synopsis
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [SIMILARITY0TO100] [OUTFILE]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER = require_good_userid   ( $ARGV[0] );
our $SHELF    = require_good_shelfname( $ARGV[1] );
our $MINSIMIL = $ARGV[2] || 5;  # between 0 and 100 (exact match)
our $OUTPATH  = $ARGV[3] || "likeminded-${GOODUSER}.html";
our $TSTART   = time();

set_good_cache( '21 days' );
STDOUT->autoflush( 1 );



my %authors_read_by;  # {$userid}->{$auid}
my %authors;          # {$userid => %author}
my @books;



# ----------------------------------------------------------------------------
# Load basic data:
# 
printf "Loading books from \"%s\" may take a while... ", $SHELF;

my @user_books = query_good_books( $GOODUSER, $SHELF );

printf "%d books\n", scalar @user_books;



# ----------------------------------------------------------------------------
# Reduce user's books to a few authors and query authors books:
# 
$authors{ $_->{author}->{id} } = $_->{author} foreach (@user_books);

my $aucount = scalar keys %authors;
my $audone  = 0;

printf "Loading books of %d authors:\n", $aucount;
foreach my $auid (keys %authors)
{
	$audone++;
	
	next if is_bad_author( $auid );
	
	printf "[%3d%%] %-25s #%-8s\t", $audone/$aucount*100, $authors{ $auid }->{name}, $auid;
	
	my $t0      = time();
	my @aubooks = query_good_author_books( $auid );
	   @books   = (@books, @aubooks);
	
	$authors{ $auid } = $aubooks[0]->{author};  # Update some values, e.g., img_url @TODO ugly
	
	printf "%3d books\t%6.2fs\n", scalar @aubooks, time()-$t0;
}
say "Done.";



# ----------------------------------------------------------------------------
# Query reviews for all author books:
# Problem: lot of duplicates (not combined as editions), but with own reviewers
# 
my $bocount = scalar @books;
my $bodone  = 0;

printf "Loading reviews for %d author books:\n", $bocount;
foreach my $b (@books)
{
	printf "[%3d%%] %-40s  #%-8s\t", ++$bodone/$bocount*100, substr( $b->{title}, 0, 40 ), $b->{id};
	
	my $t0   = time();
	my @revs = query_good_reviews( $b->{id} );
	
	printf "%4d memb\t%6.2fs\n", scalar @revs, time()-$t0;
	
	$authors_read_by{ $_->{user}->{id} }{ $b->{author}->{id} } = 1 foreach (@revs);
}
say "Done.";



# ----------------------------------------------------------------------------
# Check members for bots, private accounts etc:
# 



# ----------------------------------------------------------------------------
# Write results to HTML file:
# 
printf "Writing members (N=%d) with %d%% similarity or better to \"%s\"... ", 
	scalar keys %authors_read_by, $MINSIMIL, $OUTPATH;

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "FATAL: Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );

print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title> Goodreads members with similar taste </title>
		<style>
		td div 
		{
		  background-color: #eeeddf;
		  float     : left; 
		  display   : inline-block; 
		  height    : 95px; 
		  max-width : 50px; 
		  font-size : 8pt; 
		  text-align: center; 
		  margin    : 0.25em;
		}
		</style>
		</head>
		<body style="font-family: sans-serif;">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Members who read at least 
		  ${MINSIMIL}% of the authors in 
		  ${GOODUSER}'s shelf "$SHELF", on $now
		</caption>
		<tr>
		<th>#</th>  
		<th>Member</th>  
		<th>Common</th>  
		<th>Authors</th>  
		</tr>
		};

my $line;
foreach my $userid (sort { scalar keys $authors_read_by{$b} <=> 
                           scalar keys $authors_read_by{$a} } keys %authors_read_by) 
{
	my $common_aucount = scalar keys $authors_read_by{ $userid };
	my $simil          = int( $common_aucount / $aucount * 100 + 0.5 );  # round
	
	next if $userid == $GOODUSER;
	next if $simil  <  $MINSIMIL;
	
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td><a href="https://www.goodreads.com/user/show/${userid}" target="_blank">$userid</a></td>
			<td>$common_aucount ($simil%)</td>
			<td>
			};
			
	print $fh qq{
			<div><img src="$authors{$_}->{img_url}">$authors{$_}->{name}</div>
			} foreach (keys $authors_read_by{ $userid });

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

printf "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60;



