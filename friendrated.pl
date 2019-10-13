#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendrated - books and authors common among the members you follow


=head1 SYNOPSIS

B<friendrated.pl> 
[B<-f> F<number>] 
[B<-r> F<number>] 
[B<-z> F<number>] 
[B<-h>] 
[B<-m> F<number>] 
[B<-y> F<number>] 
[B<-e> F<number>] 
[B<-u> F<number>] 
[B<-t>] 
[B<-x> F<shelfname> ...] 
[B<-c> F<numdays>] 
[B<-o> F<filename>] 
[B<-i>]
F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

Keep in mind that followed _authors_ are excluded.

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


=item B<-h, --hated>

shortcut for B<--minrated>=F<1> and B<--maxrated>=F<2>;
the final report will be about the most hated books among the 
members you follow; default is most liked


=item B<-m, --maxratings>=F<number>

exclude books with more than say 1000 ratings by the Goodreads community,
e.g., well known bestsellers (Harry Potter); 
by default there is no upper limit


=item B<-y, --minyear>=F<number>

exclude books published before say 1950;
by default there is no limit


=item B<-e, --maxyear>=F<number>

exclude books published after say 1980;
by default there is no limit


=item B<-u, --userid>=F<number>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.
You still need to login with your credentials because authenticated 
members only can access the member-lists of other members.


=item B<-t, --toread>

don't check the "read" but "to-read" shelves of the members.
This option also overrides the B<--minrated> option with value 0.
The final report will be about the most wished-for books among 
the members you follow, not about the most liked or hated books.


=item B<-x, --excludemy>=F<shelfname>

don't add books from the given shelf to the final report, e.g., books
I already read ("read"); 
you can use this option multiple times;
by default no books will be excluded


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outdir>=F<path>

directory path where the final reports will be saved,
default is the working directory


=item B<-i, --ignore-errors>

Don't retry on errors, just keep going. 
Sometimes useful if a single Goodreads resource hangs over long periods 
and you're okay with some values missing in your result.
This option is not recommended when you run the program unattended.


=item B<-?, --help>

show full man page

=back


=head1 FILES

F<./friendrated-$USERID-$SHELF-$FLAGS.html>

F<./friendrated-$USERID-$SHELF-$FLAGS-authors.html>

F<./friendrated-1234567-read-45by3.html>

F<./friendrated-1234567-read-45by3-authors.html>

F<./friendrated-7654321-to-read-05by3.html>

F<./friendrated-7654321-to-read-05by3-authors.html>

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./friendrated.pl login@gmail.com

$ ./friendrated.pl --hated login@gmail.com

$ ./friendrated.pl --minrated=5 --excludemy=read  login@gmail.com

$ ./friendrated.pl --minrated=4 --favorers=5  login@gmail.com

$ ./friendrated.pl --minyear=1950 --maxyear=1980 --maxratings=1000 login@gmail.com

$ ./friendrated.pl --outdir=./sub/directory  login@gmail.com

$ ./friendrated.pl -c 31 -r 4 -f 3 -o myfile.html  login@gmail.com


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads-toolbox/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in ./help/friendrated.md


=head1 VERSION

2019-10-10 (Since 2018-05-10)

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
setlocale( LC_CTYPE, 'en_US' );  # GR dates all en_US
STDOUT->autoflush( 1 );
gsetopt( cache_days => 31 );

our $TSTART      = time();
our $MINFAVORERS = 3;
our $MINRATED    = 4;
our $MAXRATED    = 5;
our $FRIENDSHELF = 'read';
our $OUTDIR      = './';
our $ISTOREAD    = 0;
our @EXCLMYSHELVES;
our $MAXRATS;
our $MINYEAR;     # No default, some books lack year-pub, others < 0 B.C.
our $MAXYEAR;     # "  "
our $USERID;

GetOptions( 'favorers|f=i'    => \$MINFAVORERS,
            'minrated|r=i'    => \$MINRATED,
            'maxrated|z=i'    => \$MAXRATED,
            'maxratings|m=i'  => \$MAXRATS,
            'minyear|y=i'     => \$MINYEAR,
            'maxyear|e=i'     => \$MAXYEAR,
            'excludemy|x=s'   => \@EXCLMYSHELVES,
            'userid|u=s'      => \$USERID,
            'outdir|o=s'      => \$OUTDIR,
            'hated|h'         => sub{ $MAXRATED    = 2;         $MINRATED = 1; },
            'toread|t'        => sub{ $FRIENDSHELF = 'to-read'; $MINRATED = 0; },
            'ignore-errors|i' => sub{ gsetopt( ignore_errors => 1 );           },
            'cache|c=i'       => sub{ gsetopt( cache_days => shift );          },
            'help|?'          => sub{ pod2usage( -verbose => 2 );              })
	or pod2usage( 1 );

die( "[CRIT ] Invalid argument: --minrated=$MINRATED higher than --maxrated=$MAXRATED" )
	if $MINRATED > $MAXRATED;

die( "[CRIT ] Invalid argument: --minyear=$MINYEAR higher than --maxyear=$MAXYEAR" )
	if defined $MINYEAR 
	&& defined $MAXYEAR 
	&& $MINYEAR > $MAXYEAR;

pod2usage( 1 ) if !$ARGV[0];

glogin( usermail => $ARGV[0],  # Login required: Followee/friend list/some shelves are private
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

our $OUTPATH_BK = File::Spec->catfile( $OUTDIR, "friendrated-$USERID-$FRIENDSHELF-$MINRATED${MAXRATED}by$MINFAVORERS.html"         );
our $OUTPATH_AU = File::Spec->catfile( $OUTDIR, "friendrated-$USERID-$FRIENDSHELF-$MINRATED${MAXRATED}by$MINFAVORERS-authors.html" );



#-----------------------------------------------------------------------------
# Primary data structures:
# 
my %members;
my %mybooks;      # bookid   => %book
my %books;        # bookid   => %book
my %bkfaved_for;  # {bookid}{favorerid}, favorers hash-type because of uniqueness;
my %aufaved_for;  # {auname}{favorerid}



#-----------------------------------------------------------------------------
# Load books read by user for later exclusion:
#
if( @EXCLMYSHELVES )
{
	my $t0 = time();
	printf( "Loading #${USERID}'s books from \"%s\" for exclusion...", join( '" and "', @EXCLMYSHELVES ));
	
	greadshelf( from_user_id    => $USERID,
	            ra_from_shelves => \@EXCLMYSHELVES,
	            rh_into         => \%mybooks,
	            on_progress     => gmeter( 'books' ));
	
	printf( " (%.2fs)\n", time()-$t0 );
}



#-----------------------------------------------------------------------------
# Collect friends and followees data. Include normal users only (no authors):
#
my $t0 = time();
print( "Loading list of members known to #${USERID}..." );

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
		# Filter:
		return if exists( $mybooks{$_[0]->{id}} );
		return if defined $MAXRATS  && $_[0]->{num_ratings} > $MAXRATS;
		return if defined $MAXYEAR  && $_[0]->{year}        > $MAXYEAR;
		return if defined $MINYEAR  && $_[0]->{year}        < $MINYEAR;
		return if                      $_[0]->{user_rating} < $MINRATED;
		return if                      $_[0]->{user_rating} > $MAXRATED;
		
		# Count:
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
        ($MAXRATED > 2 ? 'favorites' : 'least favorites'), 
        $memdone );



#-----------------------------------------------------------------------------
# Write results to HTML files:
# 
my $bkfile      = IO::File->new( $OUTPATH_BK, 'w' ) or die( "[FATAL] Cannot write to $OUTPATH_BK ($!)" );
my $aufile      = IO::File->new( $OUTPATH_AU, 'w' ) or die( "[FATAL] Cannot write to $OUTPATH_AU ($!)" );
my $now         = strftime( '%a %b %e %H:%M:%S %Y', localtime );
my $num_bkfinds = 0;
my $num_aufinds = 0;

my 
$title  = "Books from the \"$FRIENDSHELF\" shelves, ";
$title .= sprintf( " published %s-%s,", $MINYEAR//"*", $MAXYEAR//"*" ) if defined $MINYEAR || defined $MAXYEAR;
$title .= " with max $MAXRATS ratings,"                                if defined $MAXRATS;
$title .= " rated $MINRATED-$MAXRATED stars";
$title .= " by $MINFAVORERS+ friends or followees";
$title .= " of member $USERID, on $now";


print( "Writing results to: \n$OUTPATH_BK\t" );

print $bkfile ghtmlhead( $title, ['>Rank:', ':!Cover:', 'Title', 'Author', 'Num GR Ratings:', 'GR Avg:', 'Year Published:', 'Commonness:', '!Added by']);

for my $bid (keys %bkfaved_for)
{
	my @favorer_ids  = keys %{$bkfaved_for{$bid}};
	my $num_favorers = scalar @favorer_ids;
	next if $num_favorers < $MINFAVORERS;
	my $rank = sprintf( '%0.5f', $num_favorers > 0 ? 1/($books{$bid}->{num_ratings}/$num_favorers) : 0 );
	$num_bkfinds++;
		
	# Don't add chars if TD is to be sorted numerically!
	print $bkfile qq{
			<tr>
			<td          >$rank</td>
			<td><img src="$books{$bid}->{img_url}"></td>
			<td><a  href="$books{$bid}->{url}" target="_blank"
			             >$books{$bid}->{title}</a></td>
			<td          >$books{$bid}->{rh_author}->{name}</td>
			<td          >$books{$bid}->{num_ratings}</td>
			<td          >$books{$bid}->{avg_rating}</td>
			<td          >$books{$bid}->{year}</td>
			<td          >${num_favorers}</td>
			<td>
			};
	
	print $bkfile qq{
			<a  href="$members{$_}->{url}" target="_blank">
			<img src="$members{$_}->{img_url}" 
			   title="$members{$_}->{name}">
			</a>
			} foreach (@favorer_ids);
	
	print $bkfile qq{
			</td>
			</tr> 
			};
}

print $bkfile ghtmlfoot();
undef $bkfile;

printf( "(%d books)", $num_bkfinds );



# ------ Common authors table: ------
print( "\n$OUTPATH_AU\t" );

print $aufile ghtmlhead( 'Authors of the ' . $title, ['>Commonness:', 'Author', '!Added by']);

for my $auname (keys %aufaved_for)
{
	my @favorer_ids  = keys %{$aufaved_for{$auname}};
	my $num_favorers = scalar @favorer_ids;
	next if $num_favorers < $MINFAVORERS;  # Just cut away the huge bulge of 1x
	$num_aufinds++;
	
	print $aufile qq{
			<tr>
			<td>${num_favorers}</td>
			<td>$auname</td>
			<td><div class="horzscroll">
			};
	
	print $aufile qq{
			<a  href="$members{$_}->{url}" target="_blank">
			<img src="$members{$_}->{img_url}" 
			   title="$members{$_}->{name}">
			</a>
			} foreach (@favorer_ids);
	
	print $aufile qq{
			</div>
			</td>
			</tr> 
			};
}

print $aufile ghtmlfoot();
undef $aufile;

printf( "(%d authors)", $num_aufinds );



#-----------------------------------------------------------------------------
# Done:
#
printf( "\n\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );


