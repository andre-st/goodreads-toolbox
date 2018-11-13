#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

similarauth - Finding all similar authors


=head1 SYNOPSIS

B<similarauth.pl> [B<-c> F<numdays>] [B<-o> F<filename>] 
[B<-s> F<shelfname> ...] F<goodusernumber>

You find your F<goodusernumber> by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

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
"./similarauth-F<goodusernumber>-F<shelfname>.html"


=item B<-s, --shelf>=F<shelfname>

name of the shelf with a selection of books to be considered, default is
"#ALL#". If the name contains special characters use an URL-encoded name.
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

$ ./similarauth.pl 55554444

$ ./similarauth.pl --shelf=science --shelf=music  55554444

$ ./similarauth.pl --shelf=read --outfile=./sub/myfile.html  55554444

$ ./similarauth.pl -c 31 -s science -s music -o myfile.html  55554444



=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

Copyright (C) Free Software Foundation, Inc.
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in similarauth.md


=head1 VERSION

2018-11-13 (Since 2018-07-05)

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
STDOUT->autoflush( 1 );

our $TSTART    = time();
our $CACHEDAYS = 31;
our @SHELVES;
our $USECOOKIE;
our $OUTPATH;
our $USERID;

GetOptions( 'help|?'      => sub{ pod2usage( -verbose => 2 ) },
            'shelf|s=s'   => \@SHELVES,
            'cache|c=i'   => \$CACHEDAYS,
            'cookie|k'    => \$USECOOKIE,
            'outfile|o=s' => \$OUTPATH ) 
             or pod2usage( 1 );

$USERID  = $ARGV[0] or pod2usage( 1 );
@SHELVES = qw( %23ALL%23 ) if !@SHELVES;
$OUTPATH = sprintf( "similarauth-%s-%s.html", $USERID, join( '-', @SHELVES ) ) if !$OUTPATH;
gsetcookie() if $USECOOKIE;
gsetcache( $CACHEDAYS );

pod2usage( -exitval => "NOEXIT", -sections => [ "REPORTING BUGS" ], -verbose => 99 );



# ----------------------------------------------------------------------------
our %auknown;  # {$auid => %author}
our %aufound;  # {$auid => %author}



# ----------------------------------------------------------------------------
# Load basic data:
#
printf( "Loading authors from \"%s\"...", join( '" and "', @SHELVES ) );

greadauthors( from_user_id    => $USERID, 
              ra_from_shelves => \@SHELVES,
              rh_into         => \%auknown, 
              on_progress     => gmeter( 'authors' ));



# ----------------------------------------------------------------------------
# Query similar authors:
# TODO recurs_depth = n
# 
my $aucount = scalar keys %auknown;
my $audone  = 0;

die( $GOOD_ERRMSG_NOBOOKS ) if $aucount == 0;

printf( "\nLoading similar authors for %d authors:\n", $aucount );

for my $auid (keys %auknown)
{
	my $t0 = time();
	printf( "[%3d%%] %-25s #%-8s\t", ++$audone/$aucount*100, $auknown{$auid}->{name}, $auid );
	
	# Also increments each author's '_seen' counter if already in %aufound
	greadsimilaraut( author_id   => $auid,
	                 rh_into     => \%aufound,
	                 on_progress => gmeter( 'similar' ));
	
	printf( "\t%6.2fs\n", time()-$t0 );
}
say( "Done." );



# ----------------------------------------------------------------------------
# Write results to HTML file
# 
printf( "Writing authors (N=%d) to \"%s\"... ", scalar keys %aufound, $OUTPATH );

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
for my $auid (sort{ $aufound{$b}->{_seen} <=> $aufound{$a}->{_seen} } keys %aufound)
{
	next if exists $auknown{$auid};
	
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td>
			<a  href="$aufound{$auid}->{works_url}" target="_blank">
			<img src="$aufound{$auid}->{img_url}" height="80" />
			          $aufound{$auid}->{name}
			</a></td>
			<td>$aufound{$auid}->{_seen}x</td>
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

