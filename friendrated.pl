#!/usr/bin/env perl

#<--------------------------------- 79 chars --------------------------------->|

=pod

=head1 NAME

friendrated - books common among the people I follow


=head1 SYNOPSIS

B<friendrated.pl> [I<OPTION>]... I<GOODUSERNUMBER>

You find your GOODUSERNUMBER by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-f, --minfavorers>=I<NUMBER>

only add books to the result which were rated by at least n friends 
or followees, default is 3

=item B<-r, --minrating>=I<NUMBER>

number between 1 and 5: only consider books rated at least n stars,
default is 4

=item B<-c, --cache>=I<NUMDAYS>

number of days until the local file cache in C</tmp/FileCache/> 
is busted, default is 31 days

=item B<-o, --outfile>=I<FILE>

name of the HTML file where we write results to, default is
"friendrated-$USER.html"

=item B<-?, --help>

show full man page 

=back


=head1 EXAMPLES

$ ./friendrated.pl 55554444

$ ./friendrated.pl --minrating=4 --minfavorers=5 55554444

$ ./friendrated.pl --outfile=./sub/myfile.html 55554444

$ ./friendrated.pl -c 31 -r 4 -f 3 -o myfile.html 55554444


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

More info in friendrated.md


=head1 VERSION

2018-07-21 (Since 2018-05-10)

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
our $MINFAVORERS = 3;
our $MINRATING   = 4;
our $FRIENDSHELF = 'read';
our $CACHEDAYS   = 31;
our $OUTPATH;
GetOptions( 'minfavorers|f=i' => \$MINFAVORERS,
            'minrating|r=i'   => \$MINRATING,
            # Options consistently used across GR toolbox:
            'outfile|o=s'     => \$OUTPATH,
            'cache|c=i'       => \$CACHEDAYS,
            'help|?'          => sub { pod2usage( -verbose => 2 ); }
		) or pod2usage 1;

pod2usage 1 unless scalar @ARGV == 1;  # 1 bc of obsolete "./fr.pl USERNUMBER SHELF"

our $GOODUSER = require_good_userid $ARGV[0];
our $TSTART   = time();
    $OUTPATH  = "friendrated-${GOODUSER}.html" if !$OUTPATH;

# Followed and friend list is private, some 'Read' shelves are private
set_good_cookie_file();  
set_good_cache( $CACHEDAYS );
STDOUT->autoflush( 1 );



#-----------------------------------------------------------------------------
# Collect user data:
#
print "Getting list of users known to #${GOODUSER}... ";

my $t0         = time();
my %people     = query_good_followees( $GOODUSER );
my @people_ids = keys %people;
my $pplcount   = scalar @people_ids;
my $ppldone    = 0;

printf "%d users (%.2fs)\n", $pplcount, time()-$t0;

die "Invalid user number or cookie? Try empty /tmp/FileCache/" if $pplcount == 0;



#-----------------------------------------------------------------------------
# Collect book data:
# 
my %books;      # {bookid} => %book
my %faved_for;  # {bookid}{favorerid}
                # favorers hash-type because of uniqueness;

foreach my $pid (@people_ids)
{
	$ppldone++;
	my $p = $people{$pid};
	
	next if $p->{is_author};  # Just normal members
	
	printf "[%3d%%] %-25s #%-10s\t", $ppldone/$pplcount*100, $p->{name}, $pid;
	
	my $t0   = time();
	my @bok  = query_good_books( $pid, $FRIENDSHELF );
	my $nfav = 0;
		
	foreach my $b (@bok)
	{
		next if $b->{user_rating} < $MINRATING;
		$nfav++;
		$faved_for{ $b->{id} }{ $pid } = 1;
		$books{ $b->{id} } = $b;
	}
	
	printf "%4d %s\t%4d favs\t%6.2fs\n", scalar( @bok ), $FRIENDSHELF, $nfav, time()-$t0;
}

say "\nPerfect! Got favourites of ${ppldone} users.";



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
		  $MINRATING or better, by
		  $MINFAVORERS+ friends or followees of member
		  $GOODUSER, on $now
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
foreach my $bid (sort { scalar keys $faved_for{$b} <=> 
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
			<a  href="$people{$_}->{url}" target="_blank">
			<img src="$people{$_}->{img_url}" 
			   title="$people{$_}->{name}">
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




