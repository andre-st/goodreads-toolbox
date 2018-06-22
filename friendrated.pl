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
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use IO::File;
use XML::Writer;
use File::Basename;
use Goodscrapes;


# Program synopsys:
say STDERR "Usage: $0 GOODUSERNUMBER [OUTXMLPATH] [MINFAVORERS] [MINRATING]" and exit if $#ARGV < 0;


# Program configuration:
our $GOODUSER    = $1 if $ARGV[0] =~ /(\d+)/ or die "FATAL: Invalid Goodreads user ID";
our $OUTPATH     = $ARGV[1] || "${GOODUSER}.xml";
our $MINFAVORERS = $ARGV[2] || 3;
our $MINRATING   = $ARGV[3] || 4;  # Highly rated books only (4 and 5 stars)
our $GOODSHELF   = 'read';
our $TSTART      = time();

# Followed and friend list is private, some 'Read' shelves are private
set_good_cookie_file();  

# Don't scrape everything again on mistakes or parameter changes or power
# blackout or when I break ^C and continue at a later timepoint.
set_good_cache( '21 days' );

# Don't wait for \n
STDOUT->autoflush( 1 );



#=========================== Collect user data ===============================

print STDOUT "Getting list of users known to #${GOODUSER}... ";

my $t0           = time();
my %people       = query_good_followees( $GOODUSER );
my @people_ids   = keys %people;
my $people_count = scalar @people_ids;
my $people_done  = 0;

printf STDOUT "%d users (%.2fs)\n", $people_count, time()-$t0;



#=========================== Collect book data ===============================

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
	my @bok  = query_good_books( $pid, $GOODSHELF );
	my $nfav = 0;
		
	foreach my $b (@bok)
	{
		next if $b->{user_rating} < $MINRATING;
		$nfav++;
		$faved_for{ $b->{id} }{ $pid } = 1;
		$books{ $b->{id} } = $b;
	}
	
	printf STDOUT "%4d %s\t%4d favs\t%.2fs\n", scalar( @bok ), $GOODSHELF, $nfav, time()-$t0;
}

say STDOUT "\nPerfect! Got favourites of ${people_done} users.";



#======================= Write results to XML file ===========================

print STDOUT "Writing results to \"$OUTPATH\"... ";

my $num_finds = 0;

my $f = IO::File->new( $OUTPATH, 'w' ) or die "FATAL: Cannot write to $OUTPATH ($!)";

my $w = XML::Writer->new( OUTPUT => $f, DATA_MODE => 1, DATA_INDENT => "\t" );

$w->xmlDecl( 'UTF-8' );
$w->startTag( 'good', 
		'version'     => '1.0', 
		'generator'   => basename( $0 ),
		'customer'    => $GOODUSER,
		'shelf'       => $GOODSHELF,
		'minfavorers' => $MINFAVORERS,
		'minrating'   => $MINRATING );

$w->startTag( 'users' );
foreach my $pid (@people_ids)
{
	$w->startTag   ( 'user'  , 'id' => $pid             );
	$w->dataElement( 'name'  , $people{$pid}->{name}    );
	$w->dataElement( 'url'   , $people{$pid}->{url}     );
	$w->dataElement( 'img'   , $people{$pid}->{img_url} );
	$w->endTag     ( 'user'                             );
}
$w->endTag  ( 'users' );
$w->startTag( 'books' );
foreach my $bid (keys %faved_for)
{
	my @favorer_ids  = keys $faved_for{$bid};
	my $num_favorers = scalar @favorer_ids;
	
	next if $num_favorers < $MINFAVORERS;
	$num_finds++;
	
	$w->startTag   ( 'book'      , 'id' => $bid            );
	$w->dataElement( 'mentions'  , $num_favorers           );
	$w->dataElement( 'title'     , $books{$bid}->{title}   );
	$w->dataElement( 'url'       , $books{$bid}->{url}     );
	$w->dataElement( 'img'       , $books{$bid}->{img_url} );
	$w->startTag   ( 'favorers'                            );
	
	$w->emptyTag( 'user', 'id' => $_ ) foreach (@favorer_ids);
	
	$w->endTag( 'favorers' );
	$w->endTag( 'book'     );
}
$w->endTag( 'books' );
$w->endTag( 'good'  );
$w->end();
printf STDOUT "%d books\n", $num_finds;

printf STDOUT "Total time: %.0f minutes\n", (time()-$TSTART)/60;



