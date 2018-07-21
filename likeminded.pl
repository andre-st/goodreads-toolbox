#!/usr/bin/env perl

#<--------------------------------- 79 chars --------------------------------->|

=pod

=head1 NAME

likeminded - finding people on Goodreads.com based on the books they've read


=head1 SYNOPSIS

B<likeminded.pl> [I<OPTION>]... I<GOODUSERNUMBER>

You find your GOODUSERNUMBER by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-m, --similarity>=I<NUMBER>

value between 0 and 100; members with 100% similarity have read *all* the
authors you did, which is unlikely, so better use lower values, default is a
minimum similarity of 5 (5%).
There's a huge bulge of members with low similarity and just a few with higher
similarity. Cut away the huge bulge, and check the rest manually

=item B<-n, --nodict>

don't try loading additional reviews by running an N-grams dictionary against
the freetext-based reviews-search provided by Goodreads. This reduces the
overall search time but also reduces the amount of reviews considered in our
statistics. The dictionary is otherwise only used for books with many ratings.

=item B<-t, --stalltime>=I<NUMSECS>

maximum number of seconds to spent on waiting for a change when dict-searching
additional reviews. If our algorithm performs poorly on a book we don't want to
waste too much time and abort. Use a very high number for a slow comprehensive
scan, but default is 60 seconds. 

=item B<-c, --cache>=I<NUMDAYS>

number of days to store and reuse downloaded data in C</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.

=item B<-o, --outfile>=I<FILE>

name of the HTML file where we write results to, default is
"likeminded-$USER-$SHELF.html"

=item B<-s, --shelf>=I<NAME>

name of the shelf with a selection of books to be considered, default is
"%23ALL%23". If it contains special characters use an URL-encoded name.

=item B<-?, --help>

show full man page

=back


=head1 EXAMPLES

$ ./likeminded.pl 55554444

$ ./likeminded.pl --shelf=read --stalltime=60 --similarity=5 55554444

$ ./likeminded.pl --nodict --outfile=./sub/myfile.html 55554444

$ ./likeminded.pl -c 31 -s read -t 60 -m 5 -o myfile.html 55554444


=head1 AUTHOR

Written by Andre St. <https://github.com/andre-st>


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

Copyright (C) Free Software Foundation, Inc.
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in likeminded.md


=head1 VERSION

2018-07-21 (Since 2018-06-22)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings qw(all);
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime floor );
use IO::File;
use Getopt::Long;
use Pod::Usage;
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
our $MINSIMIL  = 5;
our $STALLTIME = 1*60;
our $USEDICT   = 1;
our $SHELF     = '%23ALL%23';
our $CACHEDAYS = 31;
our $OUTPATH;
GetOptions( 'similarity|m=i' => \$MINSIMIL,
            'stalltime|t=i'  => \$STALLTIME,
            'nodict|n'       => sub { $USEDICT = 0; },
            # Options consistently used across GR toolbox:
            'outfile|o=s'    => \$OUTPATH,
            'cache|c=i'      => \$CACHEDAYS,
            'shelf|s=s'      => sub { $SHELF = require_good_shelfname $_[1]; },
            'help|?'         => sub { pod2usage( -verbose => 2 ); }
		) or pod2usage 1;

pod2usage 1 unless scalar @ARGV == 1;

our $GOODUSER = require_good_userid $ARGV[0];
our $TSTART   = time();
    $OUTPATH  = "likeminded-${GOODUSER}-${SHELF}.html" if !$OUTPATH;

set_good_cache( $CACHEDAYS );
STDOUT->autoflush( 1 );



# ----------------------------------------------------------------------------
my %authors_read_by;  # {$userid}->{$auid => 1}
my %authors;          # {$auid => %author}
my @books;



# ----------------------------------------------------------------------------
# Load basic data:
# 
printf "Loading books from \"%s\" may take a while... ", $SHELF;

my @userbooks = query_good_books( $GOODUSER, $SHELF );
my $ubocount  = scalar @userbooks;

printf "%d books\n", $ubocount;

die "[FATAL] Check your Goodreads privacy settings: 'anyone (including search engines)'" 
	if $ubocount == 0;



# ----------------------------------------------------------------------------
# Reduce user's books to a few authors and query authors books:
# 
$authors{ $_->{author}->{id} } = $_->{author} foreach (@userbooks);

my $aucount = scalar keys %authors;
my $audone  = 0;

printf "Loading books of %d authors:\n", $aucount;
for my $auid (keys %authors)
{
	printf "[%3d%%] %-25s #%-8s\t", ++$audone/$aucount*100, $authors{$auid}->{name}, $auid;

	say "EXCLUDED" and next if is_bad_profile( $auid );
	
	my $t0       = time();
	my $abocount = query_good_author_books( \@books, $auid );
	
	$authors{$auid} = $books[-1]->{author};  # Updates img_url @TODO ugly
	
	printf "%4d books\t%6.2fs\n", $abocount, time()-$t0;
}
say "Done.";



# ----------------------------------------------------------------------------
# Query reviews for all author books:
# Lot of duplicates (not combined as editions), but with unique reviewers tho
# 
my $bocount = scalar @books;
my $bodone  = 0;
my $progfn  = sub { print "\b" x 10 if $_[0]; printf '%5s memb', $_[0]; };

printf "Loading reviews for %d author books:\n", $bocount;
for my $b (@books)
{
	printf "[%3d%%] %-40s  #%-8s\t", ++$bodone/$bocount*100, substr( $b->{title}, 0, 40 ), $b->{id};
	
	my $t0   = time();
	my @revs = query_good_reviews( book        => $b, 
	                               use_dict    => $USEDICT,
	                               stalltime   => $STALLTIME, 
	                               on_progress => $progfn );
	
	printf "\t%6.2fs\n", time()-$t0;
	
	$authors_read_by{ $_->{user}->{id} }{ $b->{author}->{id} } = 1 foreach (@revs);
}
say "Done.";



# ----------------------------------------------------------------------------
# Write results to HTML file:
# 
printf "Writing members (N=%d) with %d%% similarity or better to \"%s\"... ", 
		scalar keys %authors_read_by, $MINSIMIL, $OUTPATH;

my $fh  = IO::File->new( $OUTPATH, 'w' ) or die "[FATAL] Cannot write to $OUTPATH ($!)";
my $now = strftime( '%a %b %e %H:%M:%S %Y', localtime );

print $fh qq{
		<!DOCTYPE html>
		<html>
		<head>
		<title> Goodreads members with similar taste </title>
		<style>
		td div 
		{
		  background-color: #eeeddf;
		  float     : left; 
		  display   : inline-block; 
		  height    : 95px; 
		  max-width : 50px; 
		  font-size : 8pt; 
		  text-align: center; 
		  margin    : 0.25em;
		}
		</style>
		</head>
		<body style="font-family: sans-serif;">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Members who read at least 
		  ${MINSIMIL}% of the authors in 
		  ${GOODUSER}'s shelf "$SHELF", on $now
		</caption>
		<tr>
		<th>#</th>  
		<th>Member</th>  
		<th>Common</th>  
		<th>Authors</th>  
		</tr>
		};

my $line;
for my $userid (sort { scalar keys $authors_read_by{$b} <=> 
                       scalar keys $authors_read_by{$a} } keys %authors_read_by) 
{
	my $common_aucount = scalar keys $authors_read_by{$userid};
	my $simil          = int( $common_aucount / $aucount * 100 + 0.5 );  # round
	
	next if $userid == $GOODUSER;
	next if $simil  <  $MINSIMIL;
	
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td><a href="https://www.goodreads.com/user/show/${userid}" target="_blank">$userid</a></td>
			<td>$common_aucount ($simil%)</td>
			<td>
			};
			
	print $fh qq{
			<div><img src="$authors{$_}->{img_url}">$authors{$_}->{name}</div>
			} foreach (keys $authors_read_by{$userid});

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

printf "\nTotal time: %.0f minutes\n", (time()-$TSTART)/60;



