#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendrated - books common among the members I follow


=head1 SYNOPSIS

B<friendrated.pl> [B<-f> F<number>] [B<-r> F<number>] [B<-c> F<numdays>] 
[B<-o> F<filename>] F<goodusernumber>

You find your F<goodusernumber> by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-f, --favorers>=F<number>

only add books to the result which were rated by at least n friends 
or followees, default is 3


=item B<-r, --rated>=F<number>

number between 1 and 5: only consider books rated at least n stars,
default is 4


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./likeminded-F<goodusernumber>-F<shelfname>.html"


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>

F<./.cookie>


=head1 EXAMPLES

$ ./friendrated.pl 55554444

$ ./friendrated.pl --rated=4 --favorers=5  55554444

$ ./friendrated.pl --outfile=./sub/myfile.html  55554444

$ ./friendrated.pl -c 31 -r 4 -f 3 -o myfile.html  55554444


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

Copyright (C) Free Software Foundation, Inc.
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in friendrated.md


=head1 VERSION

2018-08-12 (Since 2018-05-10)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime );
use IO::File;
use Getopt::Long;
use Pod::Usage;
# Third party:
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
our $TSTART      = time();
our $MINFAVORERS = 3;
our $MINRATED    = 4;
our $FRIENDSHELF = 'read';
our $CACHEDAYS   = 31;
our $OUTPATH;
our $USERID;

GetOptions( 'favorers|f=i' => \$MINFAVORERS,
            'rated|r=i'    => \$MINRATED,
            'help|?'       => sub{ pod2usage( -verbose => 2 ) },
            'outfile|o=s'  => \$OUTPATH,
            'cache|c=i'    => \$CACHEDAYS )
             or pod2usage( 1 );

$USERID  = $ARGV[0] or pod2usage( 1 );
$OUTPATH = "friendrated-${USERID}.html" if !$OUTPATH;

gsetcookie();  # Followed list, friend list and some shelves are private
gsetcache( $CACHEDAYS );
STDOUT->autoflush( 1 );



#-----------------------------------------------------------------------------
my %members;
my %books;      # bookid => %book
my %faved_for;  # {bookid}{favorerid}, favorers hash-type because of uniqueness;



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
# vote on a book (%faved_for) if the member rated the book better than x:
# 
my $memdone  = 0;
my $memcount = scalar keys %members;

die( $GOOD_ERRMSG_NOMEMBERS ) unless $memcount;

for my $mid (keys %members)
{
	printf( "[%3d%%] %-25s #%-10s\t", ++$memdone/$memcount*100, $members{$mid}->{name}, $mid );
	
	my $t0       = time();
	my $favcount = 0;
	
	my $trackfavsfn = sub{
		return if $_[0]->{user_rating} < $MINRATED;
		$favcount++;
		$faved_for{ $_[0]->{id} }{ $mid } = 1;
	};
	
	greadshelf( from_user_id    => $mid,
	            ra_from_shelves => [ $FRIENDSHELF ],
	            rh_into         => \%books,
	            on_book         => $trackfavsfn,
	            on_progress     => gmeter( $FRIENDSHELF ));
	
	printf( "\t%4d favs\t%6.2fs\n", $favcount, time()-$t0 );
}

say "\nPerfect! Got favourites of ${memdone} users.";



#-----------------------------------------------------------------------------
# Write results to HTML file:
# 
print "Writing results to \"$OUTPATH\"... ";

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
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
		  $MINRATED or better, by
		  $MINFAVORERS+ friends or followees of member
		  $USERID, on $now
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
for my $bid (sort { scalar keys $faved_for{$b} <=> 
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

print $fh qq{
		</table>
		</body>
		</html> 
		};

undef $fh;


printf "%d books\n", $num_finds;
printf "Total time: %.0f minutes\n", (time()-$TSTART)/60;




