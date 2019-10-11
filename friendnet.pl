#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendnet - Spiders one's social network and saves vertices/edges to CSV-files


=head1 SYNOPSIS

B<friennet.pl> 
[B<-u> F<number>] 
[B<-d> F<number>] 
[B<-c> F<numdays>] 
[B<-o> F<dirpath>] 
[B<-i>]
F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-u, --userid>=F<number>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.
You still need to login with your credentials because authenticated 
members only can access the member-lists of other members.


=item B<-d, --depth>=F<number>

examine network to N levels. 
Runtime and datasize increases exponentially with every level.
Depth 0 is useless, 1 equals exporting your friends/followees list, 
2 allows first useful social network analysis. 
There is the idea that all seven billion earthlings are 6 or fewer
social connections away from each other 
("Six degrees of separation")--don't try to prove it here.
Default is 2.

 depth 0:  YOU                                                  []
 depth 1:  YOU --> friends                                      []
 depth 2:  YOU <-> FRIENDS --> friends                          [100%]
 depth 3:  YOU <-> FRIENDS <-> FRIENDS --> friends              [100%, 100%]
 depth 4:  YOU <-> FRIENDS <-> FRIENDS <-> FRIENDS --> friends  [100%, 100%, 100%]
 depth n:  ...

Note: Friends with more than 1000 friends or followees are dropped, 
because the data of such accounts is likely not meaningful anymore and 
just waste your (computing) time.
 
 
=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outdir>=F<dirpath>

write CSV-files to this directory, default is the current working directory


=item B<-i, --ignore-errors>

Don't retry on errors, just keep going. 
Sometimes useful if a single Goodreads resource hangs over long periods 
and you're okay with some values missing in your result.
This option is not recommended when you run the program unattended.


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>

F<./friendnet-$USERID-edges.csv>

F<./friendnet-$USERID-nodes.csv>


=head1 EXAMPLES

$ ./friendnet.pl login@gmail.com MyPASSword

$ ./friendnet.pl --depth=3 --outdir=/tmp/  login@gmail.com


=head1 REPORTING BUGS

Send an email to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in ./help/friendnet.md


=head1 VERSION

2019-10-10 (Since 2019-06-14)

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
use Text::CSV   qw( csv );
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
setlocale( LC_CTYPE, "en_US" );  # GR dates all en_US
STDOUT->autoflush( 1 );

our $TSTART    = time();
our $CACHEDAYS = 31;
our $ERRIGNORE = 0;
our $DEPTH     = 2;
our $MAXNHOOD  = 1000;  # Ignore users with more than N friends
our $OUTDIR    = './';
our $USERID;

GetOptions( 'userid|u=s'      => \$USERID,
            'help|?'          => sub{ pod2usage( -verbose => 2 ) },
            'ignore-errors|i' => \$ERRIGNORE,
            'depth|d=i'       => \$DEPTH,
            'outdir|o=s'      => \$OUTDIR,
            'cache|c=i'       => \$CACHEDAYS )
	or pod2usage( 1 );

pod2usage( 1 ) if !$ARGV[0];

glogin( usermail => $ARGV[0],  # Login required: Followee/friend list are private
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

our $OUTPATH_EDG = File::Spec->catfile( $OUTDIR, "friendnet-$USERID-edges.csv" );
our $OUTPATH_NOD = File::Spec->catfile( $OUTDIR, "friendnet-$USERID-nodes.csv" );

gsetopt( cache_days   => $CACHEDAYS,
         ignore_error => $ERRIGNORE,
         ignore_crit  => $ERRIGNORE );



#-----------------------------------------------------------------------------
# Primary data structures:
#
my %nodes;
my @edges;



#-----------------------------------------------------------------------------
# Traverse social network:
#
printf( "Traversing #%s's social network (depth=%d)...\n", $USERID, $DEPTH );


# Displays sth. like "Covered: [ 14%, 55%]" for depth = 3
my $progress_indicator_fn = sub
{
	my (%args) = @_;
	my $dr     = $args{depth};
	my $d      = $DEPTH - $dr;
	
	return if $dr == 1;              # We get leaves as whole; percent-progress would be 0 to 100% in 1 step
	print ( "\r["                );  # Move cursor to column 0
	print ( "\t" x $d            );  # Move cursor to column for depth d (tab doesn't del prev. chars)
	printf( "%3d%%", $args{perc} );  # Percent-progress for current network depth
	print ( ",\t  0%" x ($dr-2)  );  # Fill empty columns with "0%"
	print ( ']' );
};

gsocialnet( from_user_id    => $USERID,
            rh_into_nodes   => \%nodes,
            ra_into_edges   => \@edges,
            ignore_nhood_gt => $MAXNHOOD,
            depth           => $DEPTH,
            on_progress     => $progress_indicator_fn );



#-----------------------------------------------------------------------------
# Write CSV-files:
# 
my @nodeslines = values %nodes;

printf( "\nWriting network data to: \n%s  (N=%d)\n%s  (N=%d)", 
		$OUTPATH_NOD, scalar @nodeslines,
		$OUTPATH_EDG, scalar @edges );

csv( in      => \@nodeslines,
     out     => $OUTPATH_NOD,
     headers => [qw( id name img_url )] );

csv( in      => \@edges,
     out     => $OUTPATH_EDG,
     headers => [qw( from to )] );



#-----------------------------------------------------------------------------
# Done:
# 
printf( "\n\nTotal time: %.0f minutes\n", (time()-$TSTART)/60 );



