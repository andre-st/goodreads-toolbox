#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

likeminded - finding people on Goodreads.com based on the books they've read


=head1 SYNOPSIS

B<likeminded.pl> 
[B<-m> F<number>] 
[B<-a> F<number>] 
[B<-x> F<number>] 
[B<-d> F<filename>] 
[B<-u> F<number>] 
[B<-c> F<numdays>] 
[B<-o> F<filename>] 
[B<-s> F<shelfname> ...] 
[B<-i>]
F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-m, --common>=F<number>

value between 0 and 100; members with 100% commonality have read *all* the
authors you did, which is unlikely, so better use lower values. 
Default is 5, that is, members who have read at least 5% of your authors.
There's a huge bulge of members with low commonality and just a few with 
higher commonality. Cut away the huge bulge, and check the rest manually.
In my tests, 5% cut away 99% of members.


=item B<-a, --maxauthorbooks>=F<number>

some authors list over 2000 books, either due to bad cataloging on the 
Goodreads site or too different editions which couldn't be combined.
Chewing them all would significantly increase the program's runtime.
Better we limit the number to the most N popular; default is 600


=item B<-x, --rigor>=F<numlevel>

we need to find members who rate the books of our authors, 
though Goodreads just shows a few ratings. 
We exploit ratings filters and the reviews-search to find more members:

 level 1 = filters-based search of book-raters (max 5400 ratings) - default
 level 2 = like 1 plus dict-search if >3000 ratings with stall-time of 2min
 level n = like 1 plus dict-search with stall-time of n minutes

Rigor level 0 is useless here (latest readers only), 
and 2+ (dict-search) has a bad cost/benefit ratio given hundreds of books.


=item B<-d, --dict>=F<filename>

default is F<./list-in/dict.lst>


=item B<-u, --userid>=F<number>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./likeminded-F<goodusernumber>-F<shelfname>.html"


=item B<-s, --shelf>=F<shelfname>

name of the shelf with a selection of books, default is "#ALL#". 
If the name contains special characters use an URL-encoded name.
You can use this parameter multiple times if there is more than 1 shelf to
include (boolean OR operation), see the examples section of this man page.
Use B<--shelf>=shelf1,shelf2,shelf3 to intersect shelves (Intersection
requires password).


=item B<-i, --ignore-errors>

Don't retry on errors, just keep going. 
Sometimes useful if a single Goodreads resource hangs over long periods 
and you're okay with some values missing in your result.
This option is not recommended when you run the program unattended.


=item B<-?, --help>

show full man page

=back


=head1 FILES

F<./list-in/dict.lst>

F<./list-out/likeminded-$USERID-$SHELF.html>

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./likeminded.pl login@gmail.com MyPASSword

$ ./likeminded.pl --shelf=science --shelf=music  login@gmail.com

$ ./likeminded.pl --shelf=animals,fiction login@gmail.com

$ ./likeminded.pl --outfile=./sub/myfile.html  login@gmail.com

$ ./likeminded.pl -c 31 -s read -m 5 -o myfile.html  login@gmail.com


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads-toolbox/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in ./help/likeminded.md


=head1 VERSION

2019-11-16 (Since 2018-06-22)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings qw(all);
use locale;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes   qw( time tv_interval );
use POSIX         qw( strftime floor locale_h );
use File::Spec; # Platform indep. directory separator
use IO::File;
use Getopt::Long;
use Pod::Usage;
# Third party:
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
setlocale( LC_CTYPE, "en_US" );  # GR dates all en_US
STDOUT->autoflush( 1 );
gsetopt( cache_days => 31 );

our $TSTART     = time();
our $MINCOMMON  = 5;
our $MAXAUBOOKS = 600;
our $RIGOR      = 1;
our $DICTPATH   = File::Spec->catfile( $FindBin::Bin, 'list-in', 'dict.lst' );
our $OUTPATH;
our @SHELVES;
our $USERID;

GetOptions( 'common|m=i'         => \$MINCOMMON,
            'maxauthorbooks|a=i' => \$MAXAUBOOKS,
            'rigor|x=i'          => \$RIGOR,
            'dict|d=s'           => \$DICTPATH,
            'userid|u=s'         => \$USERID,
            'outfile|o=s'        => \$OUTPATH,
            'shelf|s=s'          => \@SHELVES,
            'ignore-errors|i'    => sub{  gsetopt( ignore_errors => 1 );   },
            'cache|c=i'          => sub{  gsetopt( cache_days => $_[1] );  },
            'help|?'             => sub{  pod2usage( -verbose => 2 );      }) 
	or pod2usage( 1 );

pod2usage( 1 ) if !$ARGV[0];

glogin( usermail => $ARGV[0],  # Login not really required at the moment
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

@SHELVES = qw( %23ALL%23 )
	if !@SHELVES;
	
$OUTPATH = File::Spec->catfile( $FindBin::Bin, 'list-out', sprintf( "likeminded-%s-%s.html", $USERID, join( '-', @SHELVES )))
	if !$OUTPATH;



# ----------------------------------------------------------------------------
# Primary data structures:
# 
my %authors;          # {$auid   => %author}
my %authors_read_by;  # {$userid}->{$auid => 1}
my %readers;          # {$userid => %user}
my %books;            # {$bookid => %book}, just check 1 book if 2 authors



# ----------------------------------------------------------------------------
# Query authors from the user's shelves:
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
	printf( "[%3d%%] %-25s #%-8s\t", 
			++$audone/$aucount*100, 
			$authors{$auid}->{name}, 
			$auid );
	
	my $imgurlupdatefn = sub{ $authors{$auid} = $_[0]->{rh_author} };  # TODO ugly
	
	greadauthorbk( author_id   => $auid,
	               limit       => $MAXAUBOOKS,
	               rh_into     => \%books, 
	               on_book     => $imgurlupdatefn,
	               on_progress => gmeter( 'books' ));
	
	printf( "\t%6.2fs\n", time()-$t0 );
}
say "Done.";



# ----------------------------------------------------------------------------
# Query readers of all author books:
# Lot of duplicates (not combined as editions), but with unique reviewers tho
# 
my $bocount = scalar keys %books;
my $bodone  = 0;

printf( "Loading readers of %d author books:\n", $bocount );

for my $b (values %books)
{
	printf( "[%3d%%] %-40s  #%-8s\t", 
			++$bodone/$bocount*100, 
			substr( $b->{title}, 0, 40 ), 
			$b->{id} );

	my $t0 = time();
	my %revs;

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
# Query additional info on all readers with P percent common books.
# We need to know their library sizes to calc a similarity ranking ("match") 
# (Github #18). At the same time, we can get profile pics for the report.
# 
# Note: The match-value isn't coverage and percentage but a relation of the
# number of common authors to the number of all books in the match-mate's
# library - it's not a as good as comparing #authors to #authors (coverage)
# but it comes close. Comparing #authors would require loading all the books
# of the match-mates which takes forever as opposed to a single request
# for the number of books. Think of the match-value as stars or points
# or score, not percent - the higher the better.
#
# 
printf( "Dropping who read less than %d%% of your authors... ", $MINCOMMON );

my $bycount0 = scalar keys %authors_read_by;

for my $userid (keys %authors_read_by)
{
	my $aucommon     = scalar keys %{$authors_read_by{$userid}};
	my $aucommonperc = int($aucommon/$aucount*100+0.5);  # Rounded
	
	delete $authors_read_by{$userid}
		if $aucommonperc < $MINCOMMON || $userid eq $USERID;  # Drops ~99%
}

my $bycount1 = scalar keys %authors_read_by;

printf( "-%d memb (%3.3fs%%)\n", 
		$bycount0-$bycount1, 
		100-($bycount1/$bycount0*100) );



my $ucount = scalar keys %authors_read_by;
my $udone  = 0;

printf( "Loading profiles of the remaining %d members:\n", $ucount );

for my $userid (keys %authors_read_by)
{
	printf( "[%3d%%] goodreads.com/user/show/%-8s", 
			++$udone/$ucount*100, 
			$userid );
	
	my $t0 = time();
	my %u  = greaduser( $userid );
	
	printf( "\t%6.2fs", time()-$t0 );
	
	print ( "\tprivate account\n" ) and next 
		if $u{num_books} == 0 || $u{is_private};
	
	
	$u{ aucommon }    = scalar keys %{$authors_read_by{$userid}};	
	$u{ match    }    = int( $u{aucommon}/$u{num_books}*1000 + 0.5 ); # Watch div by zero!
	$readers{$userid} = \%u;
	
	print( "\t".( "*" x ($u{match}/10) )."\n" );
}

say "Done.";



# ----------------------------------------------------------------------------
# Write results to HTML file:
# 
printf( "Writing report (N=%d) to \"%s\"... ", scalar keys %readers, $OUTPATH );

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );
my $shv = sprintf( "%s <q>%s</q>", 
                   (scalar @SHELVES > 1 ? 'shelves' : 'shelf'), 
                   join( '</q> and <q>', @SHELVES ) );

print $fh ghtmlhead( "Members who read at least ${MINCOMMON}% of the authors in ${USERID}'s ${shv}, on $now",
		[ '<Rank:', 'Match', '!Common Authors' ]);

my $line;
for my $userid (sort{ $readers{$b}->{match} <=> 
                      $readers{$a}->{match} } keys %readers)
{
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td>
			  <a href="https://www.goodreads.com/user/show/${userid}" target="_blank">
			    <img src="${\ghtmlsafe( $readers{$userid}->{img_url} )}"
			             >${\ghtmlsafe( $readers{$userid}->{name}    )}
			    <br>
			    <small>
			      ${\ghtmlsafe( $readers{$userid}->{aucommon}  )}&nbsp;authors&nbsp;over<br>
			      ${\ghtmlsafe( $readers{$userid}->{num_books} )}&nbsp;books
			    </small>
			  </a>
			</td>
			<td>
			};
			
	print $fh qq{
			<div><img src="${\ghtmlsafe( $authors{$_}->{img_url} )}"
			              >${\ghtmlsafe( $authors{$_}->{name}    )}</div>
			} foreach (keys %{$authors_read_by{$userid}});

	print $fh qq{
			</td>
			</tr>
			};
}

print $fh ghtmlfoot();
undef $fh;



# ----------------------------------------------------------------------------
# Done:
# 
printf( "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );


