#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendrated - books and authors common among the members you follow


=head1 SYNOPSIS

B<friendrated.pl> [B<-f> F<number>] [B<-r> F<number>] [B<-z> F<number>]
[B<-c> F<numdays>] [B<-m> F<number>] [B<-y> F<number>] [B<-e> F<number>] 
[B<-o> F<filename>] [B<-u> F<string>] [B<-t>] [B<-h>]
F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-f, --favorers>=F<number>

only add books to the final report which were rated by at least 
n friends or followees, default is 3


=item B<-r, --minrated>=F<number>

only consider books rated at least n stars,
0 includes no rating, maximum is 5; see also B<--maxrated>; default is 4


=item B<-z, --maxrated>=F<number>

only consider books rated lower or equal n stars,
0 includes no rating, maximum is 5; see also B<--minrated>; default is 5


=item B<-h, --hate>

shortcut for B<--minrated>=F<1> and B<--maxrated>=F<2>;
the final report will be about the most hated books among the 
members you follow


=item B<-m, --maxratings>=F<number>

exclude books with more than say 1000 ratings by the Goodreads community,
e.g., well known bestsellers (Harry Potter)


=item B<-y, --minyear>=F<number>

exclude books published before say 1950


=item B<-e, --maxyear>=F<number>

exclude books published after say 1980


=item B<-u, --userid>=F<string>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.


=item B<-t, --toread>

don't check the "read" but "to-read" shelves of the members.
This option also overrides the B<--rated> option with value 0.
The final report will be about the most wished-for books among 
the members you follow.


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./friendrated-F<goodusernumber>-F<shelfname>.html"


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./friendrated.pl login@gmail.com MyPASSword

$ ./friendrated.pl --hate login@gmail.com

$ ./friendrated.pl --minrated=4 --favorers=5  login@gmail.com

$ ./friendrated.pl --minyear=1950 --maxyear=1980 --maxratings=1000 login@gmail.com

$ ./friendrated.pl --outfile=./sub/myfile.html  login@gmail.com

$ ./friendrated.pl -c 31 -r 4 -f 3 -o myfile.html  login@gmail.com


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in friendrated.md


=head1 VERSION

2019-05-26 (Since 2018-05-10)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use locale;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime locale_h );
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

our $TSTART      = time();
our $MINFAVORERS = 3;
our $MINRATED    = 4;
our $MAXRATED    = 5;
our $FRIENDSHELF = "read";
our $ISTOREAD    = 0;
our $CACHEDAYS   = 31;
our $MAXRATS;
our $MINYEAR;    # No default, some books lack year-pub, others < 0 B.C.
our $MAXYEAR;    # "  "
our $OUTPATH;
our $USERID;

GetOptions( 'favorers|f=i'   => \$MINFAVORERS,
            'minrated|r=i'   => \$MINRATED,
            'maxrated|z=i'   => \$MAXRATED,
            'maxratings|m=i' => \$MAXRATS,
            'minyear|y=i'    => \$MINYEAR,
            'maxyear|e=i'    => \$MAXYEAR,
            'userid|u=s'     => \$USERID,
            'hate|h'         => sub{ $MAXRATED    = 2;         $MINRATED = 1; },
            'toread|t'       => sub{ $FRIENDSHELF = "to-read"; $MINRATED = 0; },
            'help|?'         => sub{ pod2usage( -verbose => 2 );              },
            'outfile|o=s'    => \$OUTPATH,
            'cache|c=i'      => \$CACHEDAYS )
             or pod2usage( 1 );

die( "[CRIT ] Invalid argument: --minrated=$MINRATED higher than --maxrated=$MAXRATED" )
	if $MINRATED > $MAXRATED;

die( "[CRIT ] Invalid argument: --minyear=$MINYEAR higher than --maxyear=$MAXYEAR" )
	if defined $MINYEAR 
	&& defined $MAXYEAR 
	&& $MINYEAR > $MAXYEAR;
	
pod2usage( 1 ) if !$ARGV[0];
pod2usage( -exitval   => "NOEXIT", 
           -sections  => [ "REPORTING BUGS" ], 
           -verbose   => 99,
           -noperldoc => 1 );

glogin( usermail => $ARGV[0],  # Login required: Followee/friend list/some shelves are private
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

$OUTPATH = "friendrated-${USERID}-${FRIENDSHELF}.html" if !$OUTPATH;

gsetcache( $CACHEDAYS );



#-----------------------------------------------------------------------------
my %members;
my %books;       # bookid   => %book
my %bkfaved_for; # {bookid}{favorerid}, favorers hash-type because of uniqueness;
my %aufaved_for; # {auname}{favorerid}



#-----------------------------------------------------------------------------
# Collect friends and followees data. Include normal users only (no authors):
#
print( "Getting list of members known to #${USERID}..." );

my $t0 = time();
greadfolls( from_user_id => $USERID,
            rh_into      => \%members, 
            incl_authors => 0,
            on_progress  => gmeter( 'members' ));

printf( " (%.2fs)\n", time()-$t0 );



#-----------------------------------------------------------------------------
# Load each members 'read'-bookshelf into the global books list %books, and
# vote on a book (%bkfaved_for) if the member rated the book better than x:
# 
my $memdone  = 0;
my $memcount = scalar keys %members;

die( $GOOD_ERRMSG_NOMEMBERS ) unless $memcount;

for my $mid (keys %members)
{
	printf( "[%3d%%] %-25s #%-10s\t", ++$memdone/$memcount*100, $members{$mid}->{name}, $mid );
	
	my $t0       = time();
	my $hitcount = 0;
	
	my $trackfavsfn = sub{
		return if defined $MINRATED && $_[0]->{user_rating} < $MINRATED;
		return if defined $MAXRATED && $_[0]->{user_rating} > $MAXRATED;
		return if defined $MAXRATS  && $_[0]->{num_ratings} > $MAXRATS;
		return if defined $MAXYEAR  && $_[0]->{year}        > $MAXYEAR;
		return if defined $MINYEAR  && $_[0]->{year}        < $MINYEAR;
		
		$hitcount++;
		$bkfaved_for{ $_[0]->{id}                   }{ $mid } = 1;
		$aufaved_for{ $_[0]->{rh_author}->{name_lf} }{ $mid } = 1;
	};
	
	greadshelf( from_user_id    => $mid,
	            ra_from_shelves => [ $FRIENDSHELF ],
	            rh_into         => \%books,
	            on_book         => $trackfavsfn,
	            on_progress     => gmeter( $FRIENDSHELF ));
	
	printf( "\t%4d hits\t%6.2fs\n", $hitcount, time()-$t0 );
}

printf( "\nPerfect! Got %s of %d users.\n", 
        ($MAXRATED > 2 ? "favorites" : "least favorites"), 
        $memdone );



#-----------------------------------------------------------------------------
# Write results to HTML file:
# 
print( "Writing results to \"$OUTPATH\"... " );

my $fh   = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now  = strftime( '%a %b %e %H:%M:%S %Y', localtime );
my $capt = "Books from the \"${FRIENDSHELF}\" shelves, ";

$capt .= sprintf( " published %s-%s,", $MINYEAR//"*", $MAXYEAR//"*" ) 
	if defined $MINYEAR || defined $MAXYEAR;

$capt .= " with max $MAXRATS ratings," 
	if defined $MAXRATS;

$capt .= " rated $MINRATED-$MAXRATED stars";
$capt .= " by $MINFAVORERS+ friends or followees";
$capt .= " of member $USERID, on $now";


print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title> Books common among friends and followees </title>
		<link rel="stylesheet" property="stylesheet" type="text/css" 
		    media="all" href="report.css">
		</head>
		<body class="friendrated">
		<nav>
		  Tables in this document:
		  <ul>
		  <li><a href="#commonbooks"  >Common Books</a></li>
		  <li><a href="#commonauthors">Common Authors</a></li>
		  </ul>
		</nav>
		<table border="1" width="100%" cellpadding="6" id="commonbooks">
		<caption>$capt</caption>
		<tr>
		<th>#</th>
		<th>Cover</th>
		<th style="width: 13em">Title</th>
		<th>Num GR Ratings</th>
		<th>Year Published</th>
		<th>Added</th>
		<th>Added by</th>
		</tr>
		};

my $num_bkfinds = 0;
for my $bid (sort { scalar keys %{$bkfaved_for{$b}} <=> 
                    scalar keys %{$bkfaved_for{$a}} } keys %bkfaved_for)
{
	my @favorer_ids  = keys %{$bkfaved_for{$bid}};
	my $num_favorers = scalar @favorer_ids;
	
	next if $num_favorers < $MINFAVORERS;
	
	$num_bkfinds++;
	
	print $fh qq{
			<tr>
			<td          >$num_bkfinds</td>
			<td><img src="$books{$bid}->{img_url}"></td>
			<td><a  href="$books{$bid}->{url}" target="_blank"
			             >$books{$bid}->{title}</a></td>
			<td          >$books{$bid}->{num_ratings}</td>
			<td          >$books{$bid}->{year}</td>
			<td          >${num_favorers}x</td>
			<td>
			};
	
	print $fh qq{
			<a  href="$members{$_}->{url}" target="_blank">
			<img src="$members{$_}->{img_url}" 
			   title="$members{$_}->{name}">
			</a>
			} foreach (@favorer_ids);
	
	print $fh qq{
			</td>
			</tr> 
			};
}


# Common authors table:
print $fh qq{
		</table>
		<table border="1" width="100%" cellpadding="6" id="commonauthors">
		<caption>Common Authors From The Previous Books Set</caption>
		<tr>
		<th>#</th>
		<th>Author</th>
		<th>Added</th>
		<th>Added by</th>
		</tr>
		};

my $num_aufinds = 0;
for my $auname (sort { scalar keys %{$aufaved_for{$b}} <=> 
                       scalar keys %{$aufaved_for{$a}} } keys %aufaved_for)
{
	my @favorer_ids  = keys %{$aufaved_for{$auname}};
	my $num_favorers = scalar @favorer_ids;
	
	next if $num_favorers < $MINFAVORERS;  # Just cut away the huge bulge of 1x
	
	$num_aufinds++;
	
	print $fh qq{
			<tr>
			<td>$num_aufinds</td>
			<td>$auname</td>
			<td>${num_favorers}x</td>
			<td>
			};
	
	print $fh qq{
			<a  href="$members{$_}->{url}" target="_blank">
			<img src="$members{$_}->{img_url}" 
			   title="$members{$_}->{name}">
			</a>
			} foreach (@favorer_ids);
	
	print $fh qq{
			</td>
			</tr> 
			};
}


# End of file
print $fh qq{
		</table>
		</body>
		</html> 
		};

undef $fh;


printf( "%d books/%d authors\n", $num_bkfinds, $num_aufinds );
printf( "Total time: %.0f minutes\n", (time()-$TSTART)/60 );




