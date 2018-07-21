#!/usr/bin/env perl

#<--------------------------------- 79 chars --------------------------------->|

=pod

=head1 NAME

similarauth - Finding all similar authors


=head1 SYNOPSIS

B<similarauth.pl> [I<OPTION>]... I<GOODUSERNUMBER>

You find your GOODUSERNUMBER by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-c, --cache>=I<NUMDAYS>

number of days until the local file cache in C</tmp/FileCache/> 
is busted, default is 31 days

=item B<-o, --outfile>=I<FILE>

name of the HTML file where we write results to, default is
"similarauth-$USER-$SHELF.html"

=item B<-s, --shelf>=I<NAME>

name of the shelf with a selection of books to be considered,
default is "%23ALL%23"

=item B<-?, --help>

show full man page

=back


=head1 EXAMPLES

$ ./similarauth.pl 55554444

$ ./similarauth.pl --shelf=read --outfile=./sub/myfile.html 55554444

$ ./similarauth.pl -c 31 -s read -t 180 -m 5 -o myfile.html 55554444


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

More info in similarauth.md


=head1 VERSION

2018-07-21 (Since 2018-07-05)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use 5.18.0;

use FindBin;
use lib "$FindBin::Bin/lib/";
use Time::HiRes qw( time tv_interval );
use POSIX       qw( strftime );
use IO::File;
use Getopt::Long;
use Pod::Usage;
use Goodscrapes;


# Program configuration:
our $SHELF     = '%23ALL%23';
our $CACHEDAYS = 31;
our $OUTPATH;
GetOptions( 'help|?'      => sub { pod2usage( -verbose => 2 );            },
            'shelf|s=s'   => sub { $SHELF = require_good_shelfname $_[1]; },
		  'cache|c=i'   => \$CACHEDAYS,
            'outfile|o=s' => \$OUTPATH ) or pod2usage 1;

pod2usage 1 unless scalar @ARGV == 1;  # 1 bc of obsolete "./sa.pl USERNUMBER SHELF"

our $GOODUSER = require_good_userid $ARGV[0];
our $TSTART   = time();
    $OUTPATH  = "likeminded-${GOODUSER}-${SHELF}.html" if !$OUTPATH;

set_good_cache( $CACHEDAYS );
STDOUT->autoflush( 1 );



my %known_authors;  # {$userid} = %author
my %found_authors;  # {$userid} = %author
my %seen;           # {$founduserid}{$knownuserid}


# ----------------------------------------------------------------------------
# Load basic data:
# 
printf "Loading books from \"%s\" may take a while... ", $SHELF;

my @user_books = query_good_books( $GOODUSER, $SHELF );

printf "%d books\n", scalar @user_books;



# ----------------------------------------------------------------------------
# Reduce user's books to a few authors and query similar authors:
# TODO recurs_depth = n
# 
$known_authors{ $_->{author}->{id} } = $_->{author} foreach (@user_books);

my $aucount = scalar keys %known_authors;
my $audone  = 0;

printf "Loading similar authors for %d authors:\n", $aucount;
foreach my $auid (keys %known_authors)
{
	printf "[%3d%%] %-25s #%-8s\t", ++$audone/$aucount*100, 
				$known_authors{ $auid }->{name}, $auid;
	
	say "EXCLUDED" and next if is_bad_profile( $auid );
	
	my $t0  = time();
	my @sim = query_similar_authors( $auid );
	foreach (@sim)
	{
		$found_authors{ $_->{id} }          = $_;
		$seen         { $_->{id} }{ $auid } = 1;
	}
	
	printf "%3d similar\t%6.2fs\n", scalar @sim, time()-$t0;
}
say "Done.";



# ----------------------------------------------------------------------------
# Write results to HTML file
# 
printf "Writing authors (N=%d) to \"%s\"... ", scalar keys %seen, $OUTPATH;

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
foreach my $auid (sort { scalar keys $seen{$b} <=> 
                         scalar keys $seen{$a} } keys %seen) 
{
	next if exists $known_authors{$auid};
	
	my $seen_count = scalar keys $seen{$auid};
	
	$line++;
	print $fh qq{
			<tr>
			<td>$line</td>
			<td>
			<a  href="$found_authors{$auid}->{works_url}" target="_blank">
			<img src="$found_authors{$auid}->{img_url}" height="80" />
			          $found_authors{$auid}->{name}
			</a></td>
			<td>${seen_count}x</td>
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

