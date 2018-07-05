#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

similarauth.pl 

=head1 VERSION
	
2018-07-05 (Since 2018-07-05)

=head1 ABOUT

see similarauth.md

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
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [OUTFILE]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER = require_good_userid   ( $ARGV[0] );
our $SHELF    = require_good_shelfname( $ARGV[1] );
our $OUTPATH  = $ARGV[2] || "similarauth-${GOODUSER}.html";
our $TSTART   = time();

set_good_cache( '21 days' );
STDOUT->autoflush( 1 );



my %known_authors;  # {$userid} = %author
my %found_authors;  # {$userid} = %author
my %seen;           # {$founduserid}{$knownuserid}


# ----------------------------------------------------------------------------
# Load basic data:
# 
printf "Loading books from \"%s\" may take a while... ", $SHELF;

my @user_books = query_good_books( $GOODUSER, $SHELF );

printf "%d books\n", scalar @user_books;



# ----------------------------------------------------------------------------
# Reduce user's books to a few authors and query similar authors:
# TODO recurs_depth = n
# 
$known_authors{ $_->{author}->{id} } = $_->{author} foreach (@user_books);

my $aucount = scalar keys %known_authors;
my $audone  = 0;

printf "Loading similar authors for %d authors:\n", $aucount;
foreach my $auid (keys %known_authors)
{
	$audone++;
	next if is_bad_author( $auid );

	printf "[%3d%%] %-25s #%-8s\t", $audone/$aucount*100, 
				$known_authors{ $auid }->{name}, $auid;
	
	my $t0  = time();
	my @sim = query_similar_authors( $auid );
	foreach (@sim)
	{
		$found_authors{ $_->{id} }          = $_;
		$seen         { $_->{id} }{ $auid } = 1;
	}
	
	printf "%3d similar\t%6.2fs\n", scalar @sim, time()-$t0;
}
say "Done.";



# ----------------------------------------------------------------------------
# Write results to HTML file
# 
printf "Writing authors (N=%d) to \"%s\"... ", scalar keys %seen, $OUTPATH;

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );

print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title> Similar Goodreads Authors </title>
		</head>
		<body style="font-family: sans-serif;">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Similar Authors, $now
		</caption>
		<tr>
		<th>#</th>  
		<th>Author</th>  
		<th>Seen</th>  
		</tr>
		};

my $line;
foreach my $auid (sort { scalar keys $seen{$b} <=> 
                         scalar keys $seen{$a} } keys %seen) 
{
	next if exists $known_authors{$auid};
	
	my $seen_count = scalar keys $seen{$auid};
	
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td>
			<a  href="$found_authors{$auid}->{url}" target="_blank">
			<img src="$found_authors{$auid}->{img_url}" height="80" />
			          $found_authors{$auid}->{name}
			</a></td>
			<td>${seen_count}x</td>
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

