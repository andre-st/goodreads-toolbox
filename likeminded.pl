#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

likeminded - finding people on Goodreads.com based on the books they've read


=head1 SYNOPSIS

B<likeminded.pl> [B<-n>] [B<-m> F<number>] [B<-t> F<numsecs>] [B<-r> F<number>] 
[B<-c> F<numdays>] [B<-o> F<filename>] [B<-s> F<shelfname> ...] F<goodusernumber>

You find your F<goodusernumber> by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-m, --similar>=F<number>

value between 0 and 100; members with 100% similarity have read *all* the
authors you did, which is unlikely, so better use lower values, default is a
minimum similarity of 5 (5%).
There's a huge bulge of members with low similarity and just a few with higher
similarity. Cut away the huge bulge, and check the rest manually


=item B<-x, --rigor>=F<numlevel>

 level 1 = filters-based search of book-raters (max 5400 ratings) - default
 level 2 = like 1 plus dict-search if >3000 ratings with stall-time of 2min
 level n = like 1 plus dict-search with stall-time of n minutes


=item B<-d, --dict>=F<filename>

default is F<./dict/default.lst>


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-k, --cookie>

use cookie-file F<./.cookie> (only required for private accounts). 
How to get the cookie content: https://www.youtube.com/watch?v=o_CYdZBPDCg


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./likeminded-F<goodusernumber>-F<shelfname>.html"


=item B<-s, --shelf>=F<shelfname>

name of the shelf with a selection of books, default is "#ALL#". 
If the name contains special characters use an URL-encoded name.
You can use this parameter multiple times if there is more than 1 shelf to
include (boolean OR operation), see the examples section of this man page.
Use B<--shelf>=shelf1,shelf2,shelf3 to intersect shelves (Intersection
requires B<--cookie>).


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>

F<./.cookie>


=head1 EXAMPLES

$ ./likeminded.pl 55554444

$ ./likeminded.pl --shelf=science --shelf=music  55554444

$ ./likeminded.pl --shelf=animals,fiction  55554444

$ ./likeminded.pl --outfile=./sub/myfile.html  55554444

$ ./likeminded.pl -c 31 -s read -m 5 -o myfile.html  55554444


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

Copyright (C) Free Software Foundation, Inc.
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in likeminded.md


=head1 VERSION

2018-11-13 (Since 2018-06-22)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings qw(all);
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime floor );
use IO::File;
use Getopt::Long;
use Pod::Usage;
# Third party:
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
STDOUT->autoflush( 1 );

our $TSTART    = time();
our $MINSIMIL  = 5;
our $RIGOR     = 1;
our $DICTPATH  = './dict/default.lst';
our $CACHEDAYS = 31;
our $USECOOKIE = 0;
our @SHELVES;
our $OUTPATH;
our $USERID;

GetOptions( 'similar|m=i' => \$MINSIMIL,
            'rigor|x=i'   => \$RIGOR,
            'dict|d=s'    => \$DICTPATH,
            'help|?'      => sub{ pod2usage( -verbose => 2 ) },
            'outfile|o=s' => \$OUTPATH,
            'cache|c=i'   => \$CACHEDAYS,
            'cookie|k'    => \$USECOOKIE,
            'shelf|s=s'   => \@SHELVES ) 
             or pod2usage( 1 );

$USERID  = $ARGV[0] or pod2usage( 1 );
@SHELVES = qw( %23ALL%23 )                                                   if !@SHELVES;
$OUTPATH = sprintf( "likeminded-%s-%s.html", $USERID, join( '-', @SHELVES )) if !$OUTPATH;

gsetcookie() if $USECOOKIE;
gsetcache( $CACHEDAYS );

pod2usage( -exitval => "NOEXIT", -sections => [ "REPORTING BUGS" ], -verbose => 99 );



# ----------------------------------------------------------------------------
my %authors;          # {$auid   => %author}
my %books;            # {$bookid => %book}, just check 1 book if 2 authors
my %authors_read_by;  # {$userid}->{$auid => 1}



# ----------------------------------------------------------------------------
# Load authors present in the user's shelves:
#
printf( "Loading authors from \"%s\"...", join( '" and "', @SHELVES ));

greadauthors( from_user_id    => $USERID, 
              ra_from_shelves => \@SHELVES,
              rh_into         => \%authors, 
              on_progress     => gmeter( 'authors' ));



# ----------------------------------------------------------------------------
# Query all books of the loaded authors:
# 
my $audone  = 0;
my $aucount = scalar keys %authors;

die( $GOOD_ERRMSG_NOBOOKS ) unless $aucount;

printf( "\nLoading books of %d authors:\n", $aucount );

for my $auid (keys %authors)
{
	my $t0 = time();
	printf( "[%3d%%] %-25s #%-8s\t", ++$audone/$aucount*100, $authors{$auid}->{name}, $auid );
	
	my $imgurlupdatefn = sub{ $authors{$auid} = $_[0]->{rh_author} };  # TODO ugly
	
	greadauthorbk( author_id   => $auid,
	               rh_into     => \%books, 
	               on_book     => $imgurlupdatefn,
	               on_progress => gmeter( 'books' ));
	
	printf( "\t%6.2fs\n", time()-$t0 );
}
say "Done.";



# ----------------------------------------------------------------------------
# Query reviews for all author books:
# Lot of duplicates (not combined as editions), but with unique reviewers tho
# 
my $bocount = scalar keys %books;
my $bodone  = 0;

printf( "Loading reviews for %d author books:\n", $bocount );

for my $b (values %books)
{
	printf( "[%3d%%] %-40s  #%-8s\t", ++$bodone/$bocount*100, substr( $b->{title}, 0, 40 ), $b->{id} );

	my $t0 = time();
	my %revs;
	
	# Rigor level 0 is useless here, and 2+ (dict-search) has a bad 
	# cost/benefit ratio given hundreds of books:
	greadreviews( rh_for_book => $b, 
	              rh_into     => \%revs,
	              rigor       => $RIGOR,  
	              dict_path   => $DICTPATH,
	              on_progress => gmeter( 'memb' ));
	
	$authors_read_by{ $_->{rh_user}->{id} }{ $b->{rh_author}->{id} } = 1 
			foreach( values %revs );
	
	printf( "\t%6.2fs\n", time()-$t0 );
}
say "Done.";



# ----------------------------------------------------------------------------
# Write results to HTML file:
# 
printf( "Writing members (N=%d) with %d%% similarity or better to \"%s\"... ", 
		scalar keys %authors_read_by, $MINSIMIL, $OUTPATH );

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );
my $shv = sprintf( "%s <q>%s</q>", 
                   (scalar @SHELVES > 1 ? 'shelves' : 'shelf'), 
                   join( '</q> and <q>', @SHELVES ) );

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
		  ${USERID}'s ${shv}, on $now
		</caption>
		<tr>
		<th>#</th>  
		<th>Member</th>  
		<th>Common</th>  
		<th>Authors</th>  
		</tr>
		};

my $line;
for my $userid (sort{ scalar keys $authors_read_by{$b} <=> 
                      scalar keys $authors_read_by{$a} } keys %authors_read_by) 
{
	my $common_aucount = scalar keys $authors_read_by{$userid};
	my $simil          = int( $common_aucount / $aucount * 100 + 0.5 );  # round
	
	next if $userid == $USERID;
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
			} foreach (keys $authors_read_by{$userid});

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

printf( "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );



