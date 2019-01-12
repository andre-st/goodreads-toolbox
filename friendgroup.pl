#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendgroup - groups common among the members I follow


=head1 SYNOPSIS

B<friendgroup.pl> [B<-c> F<numdays>] [B<-o> F<filename>] F<goodusernumber>

You find your F<goodusernumber> by looking at your shelf URLs.


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./friendgroup-F<goodusernumber>.html"


=item B<-?, --help>

show full man page

=back


=head1 FILES

F</tmp/FileCache/>

F<./.cookie>


=head1 EXAMPLES

$ ./friendgroup.pl 55554444

$ ./friendgroup.pl --outfile=./sub/myfile.html  55554444


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in friendgroup.md


=head1 VERSION

2018-11-13 (Since 2018-09-26)

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
our $OUTPATH;
our $USERID;

GetOptions( 'help|?'       => sub{ pod2usage( -verbose => 2 ) },
            'outfile|o=s'  => \$OUTPATH,
            'cache|c=i'    => \$CACHEDAYS )
             or pod2usage( 1 );

$USERID  = $ARGV[0] or pod2usage( 1 );
$OUTPATH = "friendgroup-${USERID}.html" if !$OUTPATH;
gsetcookie();  # Followed list, friend list and user groups list are private
gsetcache( $CACHEDAYS );

pod2usage( -exitval   => "NOEXIT", 
           -sections  => [ "REPORTING BUGS" ], 
           -verbose   => 99,
           -noperldoc => 1 );



#-----------------------------------------------------------------------------
my %members;  # {user_id}
my %joins;    # {group_id}{user_id}
my %groups;   # {group_id}



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
# Load group memberships of each member
# 
my $memdone  = 0;
my $memcount = scalar keys %members;

die( $GOOD_ERRMSG_NOMEMBERS ) unless $memcount;

for my $mid (keys %members)
{
	printf( "[%3d%%] %-25s #%-10s\t", ++$memdone/$memcount*100, $members{$mid}->{name}, $mid );
	
	my $t0           = time();
	my $trackjoinsfn = sub{  $joins{ $_[0]->{id} }{ $mid } = 1;  };
	
	greadusergp( from_user_id => $mid,
	             rh_into      => \%groups,
	             on_group     => $trackjoinsfn,
	             on_progress  => gmeter( 'groups' ));
	
	printf( "\t%6.2fs\n", time()-$t0 );
}

say "\nPerfect! Got groups of ${memdone} users.";



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
		<title> Groups common among friends and followees </title>
		</head>
		<body style="font-family: sans-serif;">
		<table border="1" width="100%" cellpadding="6">
		<caption>
		  Groups joined by friends or followees of member $USERID, on $now
		</caption>
		<tr>
		<th>#</th> 
		<th>Group</th>
		<th>Members</th>
		<th>Joined</th>
		<th>Joined by</th>
		</tr>
		};

my $num_finds = 0;
for my $gid (sort { scalar keys %{$joins{$b}} <=> 
                    scalar keys %{$joins{$a}} } keys %joins)
{
	my @joiner_ids  = keys %{$joins{$gid}};
	my $num_joiners = scalar @joiner_ids;
	
	$num_finds++;
	
	print $fh qq{
			<tr>
			<td>$num_finds</td>
			<td>
			  <a  href="$groups{$gid}->{url}" target="_blank">
			  <img src="$groups{$gid}->{img_url}" align="left">
			            $groups{$gid}->{name}</a>
			</td>
			<td>$groups{$gid}->{num_members}</td>
			<td>${num_joiners}x</td>
			<td>
			};
	
	print $fh qq{
			<a  href="$members{$_}->{url}" target="_blank">
			<img src="$members{$_}->{img_url}" 
			   title="$members{$_}->{name}">
			</a>
			} foreach (@joiner_ids);
	
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


printf "%d groups\n", $num_finds;
printf "Total time: %.0f minutes\n", (time()-$TSTART)/60;




