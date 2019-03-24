#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

similarauth - Finding all similar authors


=head1 SYNOPSIS

B<similarauth.pl> [B<-u> F<string>] [B<-c> F<numdays>] [B<-o> F<filename>]
[B<-s> F<shelfname> ...] F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-u, --userid>=F<string>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at a shelf URLs.


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./similarauth-F<goodusernumber>-F<shelfname>.html"


=item B<-s, --shelf>=F<shelfname>

name of the shelf with a selection of books to be considered, default is
"#ALL#". If the name contains special characters use an URL-encoded name.
You can use this parameter multiple times if there is more than 1 shelf to
include (boolean OR operation), see the examples section of this man page.
Use B<--shelf>=shelf1,shelf2,shelf3 to intersect shelves (Intersection
requires password).


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./similarauth.pl login@gmail.com MyPASSword

$ ./similarauth.pl --shelf=science --shelf=music  login@gmail.com

$ ./similarauth.pl --shelf=read --outfile=./sub/myfile.html  login@gmail.com

$ ./similarauth.pl -c 31 -s science -s music -o myfile.html  login@gmail.com



=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in similarauth.md


=head1 VERSION

2019-03-24 (Since 2018-07-05)

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
our $OUTPATH;
our $USERID;

GetOptions( 'help|?'      => sub{ pod2usage( -verbose => 2 ) },
            'shelf|s=s'   => \@SHELVES,
            'userid|u=s'  => \$USERID,
            'cache|c=i'   => \$CACHEDAYS,
            'outfile|o=s' => \$OUTPATH ) 
             or pod2usage( 1 );

pod2usage( 1 ) if !$ARGV[0];
pod2usage( -exitval   => "NOEXIT", 
           -sections  => [ "REPORTING BUGS" ], 
           -verbose   => 99,
           -noperldoc => 1 );

glogin( usermail => $ARGV[0],  # Login not really required at the moment
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

@SHELVES = qw( %23ALL%23 ) if !@SHELVES;
$OUTPATH = sprintf( "similarauth-%s-%s.html", $USERID, join( '-', @SHELVES ) ) if !$OUTPATH;

gsetcache( $CACHEDAYS );



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
		<link rel="stylesheet" property="stylesheet" type="text/css" 
		    media="all" href="report.css">
		</head>
		<body class="similarauth">
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

