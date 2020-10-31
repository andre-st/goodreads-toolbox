#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

friendgroup - groups common among the members I follow


=head1 SYNOPSIS

B<friendgroup.pl> 
[B<-c> F<numdays>] 
[B<-o> F<filename>] 
[B<-u> F<number>]
[B<-i>]
F<goodloginmail> [F<goodloginpass>]


=head1 OPTIONS

Mandatory arguments to long options are mandatory for short options too.

=over 4

=item B<-c, --cache>=F<numdays>

number of days to store and reuse downloaded data in F</tmp/FileCache/>,
default is 31 days. This helps with cheap recovery on a crash, power blackout 
or pause, and when experimenting with parameters. Loading data from Goodreads
is a very time consuming process.


=item B<-u, --userid>=F<number>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.


=item B<-o, --outfile>=F<filename>

name of the HTML file where we write results to, default is
"./friendgroup-F<goodusernumber>.html"


=item B<-i, --ignore-errors>

Don't retry on errors, just keep going. 
Sometimes useful if a single Goodreads resource hangs over long periods 
and you're okay with some values missing in your result.
This option is not recommended when you run the program unattended.


=item B<-?, --help>

show full man page

=back


=head1 FILES

F<./list-out/friendgroup-$USERID.html>

F</tmp/FileCache/>


=head1 EXAMPLES

$ ./friendgroup.pl login@gmail.com MyPASSword

$ ./friendgroup.pl --outfile=./sub/myfile.html  login@gmail.com


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads-toolbox/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in ./help/friendgroup.md


=head1 VERSION

2019-11-16 (Since 2018-09-26)

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
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
setlocale( LC_CTYPE, "en_US" );  # GR dates all en_US
STDOUT->autoflush( 1 );
gsetopt( cache_days => 31 );

our $TSTART = time();
our $OUTPATH;
our $USERID;

GetOptions( 'outfile|o=s'     => \$OUTPATH,
            'userid|u=s'      => \$USERID,
            'ignore-errors|i' => sub{  gsetopt( ignore_errors => 1 );   },
            'cache|c=i'       => sub{  gsetopt( cache_days => $_[1] );  },
            'help|?'          => sub{  pod2usage( -verbose => 2 );      })
	or pod2usage( 1 );

pod2usage( 1 ) if !$ARGV[0];

glogin( usermail => $ARGV[0],  # Login required: Followee/friend/groups list are private
        userpass => $ARGV[1],  # Asks pw if omitted
        r_userid => \$USERID );

$OUTPATH = File::Spec->catfile( $FindBin::Bin, 'list-out', "friendgroup-${USERID}.html" ) 
	if !$OUTPATH;



#-----------------------------------------------------------------------------
# Primary data structures:
#
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

print $fh ghtmlhead( "Groups joined by friends or followees of member $USERID, on $now",
		[ '!Logo', 'Group', 'Members', '>Joined:', '!Joined by' ]);

my $num_finds = 0;
for my $gid (keys %joins)
{
	my @joiner_ids  = keys %{$joins{$gid}};
	my $num_joiners = scalar @joiner_ids;
	
	$num_finds++;
	
	print $fh qq{
			<tr>
			<td><img src="${\ghtmlsafe( $groups{$gid}->{img_url} )}"></td>
			<td><a  href="${\ghtmlsafe( $groups{$gid}->{url}     )}" target="_blank">
			              ${\ghtmlsafe( $groups{$gid}->{name}    )}</a></td>
			<td>$groups{$gid}->{num_members}</td>
			<td>${num_joiners}</td>
			<td>
			};
	
	print $fh qq{
			<a  href="${\ghtmlsafe( $members{$_}->{url}     )}" target="_blank" class="gr-user">
			<img src="${\ghtmlsafe( $members{$_}->{img_url} )}" 
			   title="${\ghtmlsafe( $members{$_}->{name}    )}">
			</a>
			} foreach (@joiner_ids);
	
	print $fh qq{
			</td>
			</tr> 
			};
}

print $fh ghtmlfoot();
undef $fh;

printf "%d groups\n", $num_finds;



#-----------------------------------------------------------------------------
# Done:
#
printf "Total time: %.0f minutes\n", (time()-$TSTART)/60;


