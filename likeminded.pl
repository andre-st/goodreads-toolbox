#!/usr/bin/env perl

###############################################################################

=pod

=head1 NAME

likeminded.pl 

=head1 VERSION
	
2018-06-23 (Since 2018-06-23)

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
use IO::File;
use XML::Writer;
use File::Basename;
use Goodscrapes;


# Program synopsis
say STDERR "Usage: $0 GOODUSERNUMBER [SHELFNAME] [SIMILARITY]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $SHELF    = $ARGV[1] || '%23ALL%23';
our $MINSIMIL = $ARGV[2] || 5;  # between 0 and 100 (exact match)
our $OUTPATH  = "likeminded-${GOODUSER}.html";
our $TSTART   = time();

set_good_cache( '21 days' );
STDOUT->autoflush( 1 );



my %authors_read_by;  # {userid}{authorid}
my %authors;          # {userid => name}
my @books;



# ----------------------------------------------------------------------------
# Load basic data:
# ----------------------------------------------------------------------------
printf "Loading books from \"%s\" may take a while... ", $SHELF;
my @user_books = query_good_books( $GOODUSER, $SHELF );
printf "%d books\n", scalar @user_books;


# ----------------------------------------------------------------------------
# Reduce user's books to a few authors and query author's books:
# ----------------------------------------------------------------------------
$authors{ $_->{author}->{id} } = $_->{author} foreach (@user_books);

my $authors_count = scalar keys %authors;
my $authors_done  = 0;

printf "Loading books of %d authors:\n", $authors_count;
foreach my $aid (keys %authors)
{
	$authors_done++;
	
	next if $aid eq "1000834";  # "NOT A BOOK" author page: 3.000+ books
	
	printf "[%3d%%]  #%-8s  %-25s\t", $authors_done/$authors_count*100, $aid, $authors{ $aid }->{name};
	
	my $t0 = time();
	my @au_books = query_good_author_books( $aid );
	@books = (@books, @au_books);
	
	$authors{ $aid } = $au_books[0]->{author};  # Update some values, e.g., img_url @TODO ugly
	
	printf "%3d books\t%.2fs\n", scalar @au_books, time()-$t0;
}
say "Done.";


# ----------------------------------------------------------------------------
# Query reviews for all author books:
# Problem: lot of duplicates (not combined as editions), but with own reviewers
# ----------------------------------------------------------------------------
my $books_count = scalar @books;
my $books_done  = 0;

printf "Loading reviews for %d author books:\n", $books_count;
foreach my $b (@books)
{
	printf "[%3d%%]  #%-8s  %-40s\t", 
			++$books_done/$books_count*100, $b->{id}, substr( $b->{title}, 0, 40 );
	
	my $t0   = time();
	my @revs = query_good_reviews( $b->{id} );
	
	printf "%4d memb\t%.2fs\n", scalar @revs, time()-$t0;
	
	$authors_read_by{ $_->{user}->{id} }{ $b->{author}->{id} } = 1 foreach (@revs);
}
say "Done.";


# ----------------------------------------------------------------------------
# Checking members for bots, private accounts etc
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# Generate result view:
# ----------------------------------------------------------------------------
printf "Writing members (N=%d) with %d%% similarity or better to \"%s\"... ", 
	scalar keys %authors_read_by, $MINSIMIL, $OUTPATH;

my $f = IO::File->new( $OUTPATH, 'w' ) or die "FATAL: Cannot write to $OUTPATH ($!)";
my $w = XML::Writer->new( OUTPUT => $f, DATA_MODE => 1, DATA_INDENT => "\t" );

$w->xmlDecl( 'UTF-8' );
$w->doctype( 'html' );
$w->startTag( 'html' );
$w->startTag( 'head' );
$w->dataElement( 'title', 'Goodreads members who read my authors' );
$w->startTag( 'style', 'type' => 'text/css' );
$w->comment( "\nbody   { font-family: sans-serif; }" .
             "\ntd div { float: left; display: inline-block; height: 95px; max-width: 50px; background-color: #eeeddf; font-size: 8pt; text-align: center; margin: 0.25em; }\n" );
$w->endTag( 'style' );
$w->endTag( 'head' );
$w->startTag( 'body' );
$w->startTag( 'table', 'border' => '1', 'width' => '100%' );
$w->startTag( 'tr' );
$w->dataElement( 'th', '#'       );
$w->dataElement( 'th', 'Member'  );
$w->dataElement( 'th', 'Common'  );
$w->dataElement( 'th', 'Authors' );
$w->endTag( 'tr' );

my $line = 1;
foreach my $userid (sort { scalar keys $authors_read_by{$b} <=> scalar keys $authors_read_by{$a} } keys %authors_read_by) 
{
	my $common_authors_count = scalar keys $authors_read_by{ $userid };
	my $simil                = $common_authors_count/$authors_count*100;
	
	next if $userid == $GOODUSER;
	next if $simil  <  $MINSIMIL;

	$w->startTag( 'tr' );
	$w->dataElement( 'td', $line++ );
	$w->startTag( 'td' );
	$w->startTag( 'a', 'href' => "https://www.goodreads.com/user/show/${userid}", 'target' => '_blank' );
	$w->emptyTag( 'img', 'src' => '' );
	$w->dataElement( 'span', $userid );
	$w->endTag( 'a'  );
	$w->endTag( 'td' );
	$w->startTag( 'td' );
	$w->dataElement( 'span', sprintf( '%d (%d%%)', $common_authors_count, $simil ) );
	$w->endTag( 'td' );
	$w->startTag( 'td' );
	
	foreach my $authorid (keys $authors_read_by{ $userid })
	{
		$w->startTag( 'div' );
		$w->emptyTag( 'img', 'src' => $authors{ $authorid }->{img_url} );
		$w->dataElement( 'span',      $authors{ $authorid }->{name}    );
		$w->endTag( 'div' );
	}
			
	$w->endTag( 'td' );
	$w->endTag( 'tr' );
}

$w->endTag( 'table' );
$w->endTag( 'body'  );
$w->endTag( 'html'  );
$w->end();


printf "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60;



