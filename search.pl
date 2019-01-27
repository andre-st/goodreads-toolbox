#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

search - Search a book and sort result by popularity


=head1 SYNOPSIS

B<search.pl> [B<-r> F<number>] [B<-s> F<number>] [B<-c> F<numdays>] 
[B<-o> F<filename>] F<keyword>...

Use quotes if you want exact matches (see examples section)

=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-z, --order>=F<columns>

sort order, all descending, comma-separated column names,
default is "stars,num_ratings,year"
(you're free to change the order but not the names)


=item B<-r, --ratings>=F<number>

only include books with N or more ratings:
a 4-stars book rated by 30 readers might be "better" than a 5-stars book rated
by 1 reader (perhaps the author). This also declutters our F<outfile>.
Default is 5 or 0 if exact match.


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 7 days. This helps on experimenting with parameters. 
Loading data from Goodreads is a time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./search-F<keyword>.html"


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./search.pl linux

$ ./search.pl --ratings=10 --order=stars,num_ratings linux kernel

$ ./search.pl --order=year,num_ratings linux kernel

$ ./search.pl -r 10 -z year "linux kernel"


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in search.md


=head1 VERSION

2019-01-27 (Since 2018-07-29)

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
use List::MoreUtils qw( uniq );
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
setlocale( LC_CTYPE, "en_US" );  # GR dates all en_US
STDOUT->autoflush( 1 );
 
our $TSTART    = time();
our $CACHEDAYS = 7;
our @ORDER;
our $NUMRATINGS;
our $PHRASE;
our $OUTPATH;
our $ISEXACT;
my  $ordercsv = '';

GetOptions( 'ratings|r=i' => \$NUMRATINGS,
            'order|z=s'   => \$ordercsv,
            'help|?'      => sub{ pod2usage( -verbose => 2 ) },
            'cache|c=i'   => \$CACHEDAYS,
            'outfile|o=s' => \$OUTPATH ) 
             or pod2usage( 1 );

$PHRASE     = join( ' ', @ARGV ) or pod2usage( 1 );
$OUTPATH    = "search-${PHRASE}.html" if !$OUTPATH;
$ISEXACT    = index( $ARGV[0], ' ' ) > -1;  # Quoted "aaa bbb" as single argument, otherwise 2 args
$NUMRATINGS = $ISEXACT ? 0 : 5 if !defined $NUMRATINGS;
$ordercsv   =~ s/\s+//g;  # Mistakenly added spaces
@ORDER      = uniq(( split( ',', lc $ordercsv ), qw( stars num_ratings year )));  # Adds missing

gsetcache( $CACHEDAYS );

pod2usage( -exitval   => "NOEXIT", 
           -sections  => [ "REPORTING BUGS" ], 
           -verbose   => 99,
           -noperldoc => 1 );



# ----------------------------------------------------------------------------
my @books;



# ----------------------------------------------------------------------------
# Load basic data:
#
printf( "Searching books:\n\n about..... %s\n rated by.. %d members or more\n order by.. %s\n progress.. ",
		$ISEXACT ? "$PHRASE (exact)" : $PHRASE, $NUMRATINGS, join( ', ', @ORDER ) );

gsearch( phrase      => $PHRASE,
         ra_into     => \@books,
         is_exact    => $ISEXACT,
         ra_order_by => \@ORDER,
         num_ratings => $NUMRATINGS,
         on_progress => gmeter );



# ----------------------------------------------------------------------------
# Write results to HTML file
# 
printf( "\n\nWriting search result (N=%d) to \"%s\"... ", scalar @books, $OUTPATH );

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );

print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title>Goodreads search result</title>
		<link rel="stylesheet" property="stylesheet" type="text/css" 
		    media="all" href="report.css">
		</head>
		<body class="search">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Query: "$PHRASE", $now
		</caption>
		<tr>
		<th>#</th>
		<th>Title</th>  
		<th>Author</th>
		<th>$ORDER[0]</th>
		<th>$ORDER[1]</th>
		<th>$ORDER[2]</th>
		</tr>
		};

my $line;
for my $b (@books)
{
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td>
				<a  href="$b->{url    }" target="_blank">
				<img src="$b->{img_url}" height="80" />
				          $b->{title  }</a>
			</td>
			<td>
				<a href="$b->{rh_author}->{url }" target="_blank">
				         $b->{rh_author}->{name}</a>
			</td>
			<td>$b->{ $ORDER[0] }</td>
			<td>$b->{ $ORDER[1] }</td>
			<td>$b->{ $ORDER[2] }</td>
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

