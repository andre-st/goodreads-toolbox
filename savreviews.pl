#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

savreviews - Download reviews for a book


=head1 SYNOPSIS

B<savreviews.pl> [B<-x> F<numlevel>] [B<-c> F<numdays>] [B<-d> F<filename>] 
[B<-o> F<dirname>] F<goodbookid>

You find the F<goodbookid> by looking at the book URL.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-x, --rigor>=F<numlevel>

 level 0 = search newest reviews only (max 300 ratings)
 level 1 = search with a combination of filters (max 5400 ratings)
 level 2 = like 1 plus dict-search if more than 3000 ratings with stall-time of 2 minutes
 level n = like 1 plus dict-search with stall-time of n minutes - default is 10


=item B<-d, --dict>=F<filename>

default is F<./dict/default.lst>


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 7 days. This helps on experimenting with parameters. 
Loading data from Goodreads is a time consuming process.


=item B<-o, --outdir>=F<path>

directory path where the final reports will be saved,
default is the working directory


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>

F<./savreviews-book*-stars{0..5}.txt>


=head1 EXAMPLES

$ ./savreviews.pl 333222


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in savreviews.md


=head1 VERSION

2019-05-29 (Since 2018-08-13)

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
use POSIX       qw( locale_h );
use List::Util  qw( max );
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

our $TSTART     = time();
our $CACHEDAYS  = 7;
our $RIGOR      = 10;
our $DICTPATH   = './dict/default.lst';
our $OUTDIR     = '.';
our $OUTNAMEFMT = 'savreviews-book%s-stars%d.txt';
our $OUTDATEFMT = "%Y/%m/%d";  # man strptime
our $BARWIDTH   = 40;          # Histogram
our $BARCHAR    = '#';         # Histogram
our $BOOKID;
our $REVIEWSEPARATOR = "\n\n".( '-' x 79 )."\n";  # long line

GetOptions( 'rigor|x=i'  => \$RIGOR,
            'dict|d=s'   => \$DICTPATH,
            'help|?'     => sub{ pod2usage( -verbose => 2 ) },
            'outdir|o=s' => \$OUTDIR,
            'cache|c=i'  => \$CACHEDAYS )
             or pod2usage( 1 );

$BOOKID = $ARGV[0] or pod2usage( 1 );
gsetcache( $CACHEDAYS );



# ----------------------------------------------------------------------------
print( 'Loading reviews ' );

my %reviews;

my %book = greadbook( $BOOKID );

printf( 'for "%s"...', $book{title} );

greadreviews( rh_for_book => \%book,
              rigor       => $RIGOR,
              rh_into     => \%reviews,
              dict_path   => $DICTPATH,
              text_only   => 1,
              on_progress => gmeter( "of $book{num_reviews} [searching]" ));



# ----------------------------------------------------------------------------
print( "\n\nNumber of reviews per year:" );

my %ycount;
$ycount{$_} = 0                         for (2007 .. (localtime)[5]);  # Years not in reviews
$ycount{$_->{date}->strftime( '%Y' )}++ for (values %reviews);

my $maxycount = max( values %ycount );

printf( "\n%d %-${BARWIDTH}s %5d", $_, $BARCHAR x ($BARWIDTH/$maxycount*$ycount{$_}), $ycount{$_} )
	for (sort{ $a <=> $b } keys %ycount);



# ----------------------------------------------------------------------------
print( "\n\nWriting reviews to:" );

my @files;

for my $n (0..$MAXPOSSIBLESTARS)
{
	my $fpath = File::Spec->catfile( $OUTDIR, sprintf( $OUTNAMEFMT, $BOOKID, $n ) );
	
	print( "\n$fpath" );
	
	push @files, IO::File->new( $fpath, '>:utf8' ) 
		or die( "[FATAL] Cannot write to $fpath ($!)" );
}


print {$files[$_->{rating}]} 
		$_->{date}->strftime( $OUTDATEFMT ) . " #" .
		$_->{id  } . "\n\n" .
		$_->{text} .
		$REVIEWSEPARATOR 
	for (values %reviews);




printf( "\n\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );


