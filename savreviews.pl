#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

savreviews - Download reviews for a book


=head1 SYNOPSIS

B<savreviews.pl> [B<-x> F<numlevel>] [B<-c> F<numdays>] [B<-o> F<filename>] 
F<goodbookid>...


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-x, --rigor>=F<numlevel>

 level 0   = search newest reviews only (max 300 ratings)
 level 1   = search with a combination of filters (max 5400 ratings)
 level 2   = like 1 plus dict-search if more than 3000 ratings with stall-time of 2 minutes
 level n   = like 1 plus dict-search with stall-time of n minutes
 level n>9 = use a larger dictionary (slowest level) - default is 10


=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 7 days. This helps on experimenting with parameters. 
Loading data from Goodreads is a time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./savreviews-F<goodbookid>.html"


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./savreviews.pl 333222

$ ./savreviews.pl --outfile=myfile.txt 333222


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
L<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

Copyright (C) Free Software Foundation, Inc.
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License L<https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in search.md


=head1 VERSION

2018-08-12 (Since 2018-07-29)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use IO::File;
use Getopt::Long;
use Pod::Usage;
# Third party:
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
our $TSTART    = time();
our $CACHEDAYS = 7;
our $RIGOR     = 10;
our $OUTPATH;
our $BOOKID;
our $REVSEPERATOR = "\n\n".( '-' x 79 )."\n\n";

GetOptions( 'rigor|x=i'   => \$RIGOR,
            'help|?'      => sub{ pod2usage( -verbose => 2 ) },
            'cache|c=i'   => \$CACHEDAYS,
            'outfile|o=s' => \$OUTPATH ) 
             or pod2usage( 1 );

$BOOKID  = $ARGV[0] or pod2usage( 1 );
$OUTPATH = "savreviews-${BOOKID}.txt" if !$OUTPATH;

gsetcache( $CACHEDAYS );
STDOUT->autoflush( 1 );



# ----------------------------------------------------------------------------
my %reviews;

print( "Loading reviews " );

my %book = greadbook( $BOOKID );

printf( "for \"%s\"...", $book{title} );

my $fh = IO::File->new( $OUTPATH, '>:utf8' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";

greadreviews( for_book    => \%book,
              rigor       => $RIGOR,
              rh_into     => \%reviews,
              on_filter   => sub{ $_[0]->{text} },  # Reviews only
              on_progress => gmeter( "of $book{num_reviews} reviews" ));

printf( "\nWriting reviews to \"%s\"... ", $OUTPATH );

print $fh $_->{text}.$REVSEPERATOR foreach (values %reviews);
undef $fh;

printf( "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );





