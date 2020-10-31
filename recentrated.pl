#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

recentrated - know when people rate or write reviews about a book


=head1 SYNOPSIS

B<recentrated.pl> 
[B<-t> F<mailaddr>] 
[B<-u> F<number>] 
[B<-s> F<shelfname>] 
[B<-q>] 
[I<goodloginmail>] 
[F<goodloginpass>]


=head1 OPTIONS

=over 4


=item I<goodloginmail>

add an unsubscribe email header and a contact address for
administrative issues to the programm output.
This also appends a helpful email signature.
It limits the number of books in the mail, with the rest to be 
mailed the next time (if I<MAILTO> does not equal I<MAILFROM>).
Less books means shorter program runtimes for each receiver
(GitHub #23).


=item I<goodloginpass>

the password that is required for the Goodreads website login


=item B<-t, --to>=F<emailaddr>

prepend an email header.
This tool does not send mails by its own.
You would have to pipe its output into a C<sendmail> programm.


=item B<-u, --userid>=F<number>

check another member instead of the one identified by the login-mail 
and password arguments. You find the ID by looking at the shelf URLs.


=item B<-s, --shelf>=F<shelfname>

name of the shelf with a selection of books, default is "#ALL#". 
If the name contains special characters use an URL-encoded name.
You can use this parameter multiple times if there is more than 1 shelf to
include (boolean OR operation), see the examples section of this man page.
Use B<--shelf>=shelf1,shelf2,shelf3 to intersect shelves (Intersection
requires password).


=item B<-q, --textonly>

output links to text reviews only, this drops all non-text 
ratings (stars only). This option is useful if you have many 
books which get many ratings every day. But it shifts the use 
case from finding new people to mere reading new ideas about 
a book.


=item B<-?, --help>

show full man page


=back


=head1 EXAMPLES

$ ./recentrated.pl my@mail.com

$ ./recentrated.pl --shelf=read my@mail.com

$ ./recentrated.pl --userid=55554444 --shelf=read --to=my@mail.com

$ ./recentrated.pl -u 55554444 -s read -t friend@mail.com admin@mail.com


=head1 FILES

Log written to F</var/log/good.log>

Database stored in F</var/db/good/>


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads-toolbox/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in ./help/recentrated.md


=head1 VERSION

2019-10-10 (Since 2018-01-09)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use locale;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use POSIX      qw( locale_h );
use List::Util qw( max );
use Time::Piece;
use Getopt::Long;
use Pod::Usage;
# Third party:
use Log::Any  '$_log', default_adapter => [ 'File' => '/var/log/good.log' ];
use Text::CSV  qw( csv );
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
pod2usage( -verbose => 2 ) if $#ARGV < 0;
setlocale( LC_CTYPE, "en_US" );  # GR dates all en_US

our $TEXTONLY = 0;
our @SHELVES;
our $MAILTO;
our $USERID;

GetOptions( 'userid|u=s' => \$USERID,
            'shelf|s=s'  => \@SHELVES,
            'to|t=s'     => \$MAILTO,
            'textonly|q' => \$TEXTONLY,
            'help|?'     => sub{ pod2usage( -verbose => 2 ) });

our $MAILFROM = $ARGV[0];
our $PASSWORD = $ARGV[1];
    $MAILTO   = $MAILFROM if !$MAILTO;

glogin( usermail => $MAILFROM,  # Login required for reading private members
        userpass => $PASSWORD,  # Asks pw if omitted
        r_userid => \$USERID )
	if $MAILFROM && $PASSWORD;


say( "[CRIT ] Missing --userid option or goodloginmail argument." )
	if !$USERID;


# Path to the database files which contain last check states
our $DBPATH = sprintf( "/var/db/good/%s-%s.csv", $USERID, join( '-', @SHELVES ));

# The more URLs, the longer and untempting the mail.
# If number exceeded, we link to the book page with *all* reviews.
our $MAX_REVURLS_PER_BOOK = 3;

# Limit number of books in the mail and the program runtime if not admin
our $maxbooks = $MAILFROM && $MAILTO && $MAILFROM ne $MAILTO ? 50 : 999999;

# GR-URLs in mail padded to average length, with "https://" stripped
sub prettyurl{ return sprintf '%-36s', substr( shift, 8 ); }



# ----------------------------------------------------------------------------
# Looking just at the shelves, we can already see the number of current 
# ratings for each individual book. We compare them with the numbers from the
# last check (stored in a CSV-file $db). For those books whose numbers differ,
# we actually load the most recent ratings. This gets us info about the
# members who rated the books, how they rated it, and whether they added text.
# 
my $db       = ( -e $DBPATH  ?  csv( in => $DBPATH, key => 'id' )  :  {} );
my $num_hits = 0;
my %books;


greadshelf( from_user_id    => $USERID,
            ra_from_shelves => \@SHELVES,
            rh_into         => \%books );


my @added   = grep{ !exists $db->{$_}  } keys %books;
my @removed = grep{ !exists $books{$_} } keys %{$db};

delete $db->{$_} for( @removed );

my @oldest_ids = sort{ $db->{$a}->{checked} <=> 
                       $db->{$b}->{checked} } keys %{$db};  # Oldest first


for my $id (@oldest_ids)
{
	last unless $maxbooks;  # Mail the rest the next time
	
	my $num_new_rat = $books{$id}->{num_ratings} - $db->{$id}->{num_ratings};
	
	next unless $num_new_rat > 0;
	
	my %revs;
	my $lastcheck = Time::Piece->strptime( $db->{$id}->{checked} +(60*60*12), '%s' );
	
	greadreviews( rh_for_book => $books{$id},
	              since       => $lastcheck,
	              rh_into     => \%revs,
	              text_minlen => $TEXTONLY * $GOOD_USEFUL_REVIEW_LEN,
	              rigor       => 0 );
	
	$db->{$id}->{num_ratings} = $books{$id}->{num_ratings};
	$db->{$id}->{checked    } = time;  # GR locale
	$maxbooks--;
	
	next unless %revs;
	
	my $revcount = scalar keys %revs;
	
	$num_hits++;
	
	# E-Mail header and first body line:
	if( $MAILTO && $num_hits == 1 )
	{
		print ( "To: ${MAILTO}\n"                           );
		print ( "From: ${MAILFROM}\n"                       ) if $MAILFROM;
		print ( "List-Unsubscribe: <mailto:${MAILFROM}>\n"  ) if $MAILFROM;
		print ( "Content-Type: text/plain; charset=utf-8\n" );
		print ( "Subject: New ratings on Goodreads.com\n\n" );  # 2x \n hdr end
		printf( "Recently rated books in your \"%s\" shelf:\n", join( '" and "', @SHELVES ));
	}
	
	
	#  ASCII design isn't responsive, and the GMail web client neither uses fixed
	#  width fonts nor treats multiple space characters as defined, even on large
	#  screens. It treats plain text mails as HTML text. I don't do HTML mails,
	#  so mobile GMail web users will have the disadvantage.
	#
	#<-------------------- 78 chars per line i.a.w. RFC 2822 --------------------->
	#
	#  "Book Title1"
	#   www.goodreads.com/book/show/609606     [9 new]
	#  
	#  "Book Title2"
	#   www.goodreads.com/review/show/1234567  [TTT  ]
	#   www.goodreads.com/user/show/2345       [*****]
	#
	printf( "\n  \"%s\"\n", $books{$id}->{title} );
	
	if( $revcount > $MAX_REVURLS_PER_BOOK )
	{
		printf( "   %s  [%d new]\n", prettyurl( $books{$id}->{url} ), $revcount );
	}
	else
	{
		printf( "   %s  %s\n", prettyurl( $_->{text} ? $_->{url} : $_->{rh_user}->{url} ), $_->{rating_str} )
			foreach (values %revs);
	}
}


# Help user to help himself:
print "\n\n\nToo many ratings?\n"
    . ">> Use a separate shelf \"watch\" on Goodreads.com with 50-150 "
    . "special but lesser-known books, and fine-tune this mail by dropping "
    . "some books from that shelf over time. "
    . "Reply \"shelf new-shelf-name\" when ready."
	if $MAILFROM && $num_hits > 25;


# Without a hint, the user doesn't know whether there are simply no 
# stars-only ratings or whether they were intentionally ignored:
print "\n\n\nRatings without text were ignored (Reply 'all' otherwise)." 
	if $TEXTONLY;


# E-mail signature block if run for other users:
print "\n\n-- \n"  # RFC 3676 sig delimiter (has space char)
    . " [***  ] 3/5 stars rating without text           \n"
    . " [ttt  ] 3/5 stars rating with tweet-size text   \n"
    . " [TTT  ] 3/5 stars rating with text              \n"
    . " [9 new] ratings better viewed on the book page  \n"
    . "                                                 \n"
    . " Reply 'textonly'     to skip ratings w/o text   \n"
#   . " Reply 'hateonly'     to see negative rat. only  \n"
#   . " Reply 'weekly'       to avoid daily mails       \n"
    . " Reply 'shelf NAME'   to check alternative shelf \n"
    . " Reply 'unsubscribe'  to unsubscribe             \n"
    . " Via https://andre-st.github.io/goodreads/       \n\n"
	if( $MAILFROM && $num_hits > 0 );



# Add new books:
$db->{$_} = { 'id'          => $_, 
              'num_ratings' => $books{$_}->{num_ratings}, 
              'checked'     => time } for( @added );

# Cronjob audits:
$_log->infof( 'Recently rated: %d of %d books in %s\'s shelf "%s"', 
              $num_hits, scalar keys %books, $USERID, join( '" and "', @SHELVES ));

# Update database:
my @lines = values %{$db};
csv( in      => \@lines, 
     out     => $DBPATH, 
     headers => [qw( id num_ratings checked )] );

# Done.
