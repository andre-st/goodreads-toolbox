#!/usr/bin/env perl

#<--------------------------------- MAN PAGE --------------------------------->|

=pod

=head1 NAME

recentrated - know when people rate or write reviews about a book


=head1 SYNOPSIS

B<recentrated.pl> I<GOODUSERNUMBER> [I<SHELFNAME>] [I<MAILTO>] [I<MAILFROM>]

You find your GOODUSERNUMBER by looking at your shelf URLs.


=head1 OPTIONS

=over 4

=item I<SHELFNAME>

name of the shelf with a selecton of books to be checked, 
default is "#ALL#".

=item I<MAILTO>

prepend an email header and append a helpful email signature to 
the program output. This tool does not send mails by its own.
You would have to pipe its output into a C<sendmail> programm.

=item I<MAILFROM>

add an unsubscribe email header and a contact address for
administrative issues to the programm output

=back


=head1 EXAMPLES

$ ./recentrated.pl 55554444

$ ./recentrated.pl 55554444 read my@mail.com

$ ./recentrated.pl 55554444 read friend@mail.com admin@mail.com


=head1 FILES

Log written to C</var/log/good.log>

Database stored in C</var/db/good/>


=head1 REPORTING BUGS

Report bugs to <datakadabra@gmail.com> or use Github's issue tracker
<https://github.com/andre-st/goodreads/issues>


=head1 COPYRIGHT

This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <https://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.


=head1 SEE ALSO

More info in recentrated.md


=head1 VERSION

2018-08-12 (Since 2018-01-09)

=cut

#<--------------------------------- 79 chars --------------------------------->|


use strict;
use warnings;
use 5.18.0;

# Perl core:
use FindBin;
use lib "$FindBin::Bin/lib/";
use Log::Any '$_log', default_adapter => [ 'File' => '/var/log/good.log' ];
use Text::CSV qw( csv );
use Time::Piece;
use Pod::Usage;
# Third part:
# Ours:
use Goodscrapes;



# ----------------------------------------------------------------------------
# Program configuration:
# 
pod2usage( -verbose => 2 ) if $#ARGV < 0;
our $USERID   = gverifyuser ( $ARGV[0] );
our $SHELF    = gverifyshelf( $ARGV[1] );
our $MAILTO   = $ARGV[2];
our $MAILFROM = $ARGV[3];
our $CSVPATH  = "/var/db/good/${USERID}-${SHELF}.csv";

# The more URLs, the longer and untempting the mail.
# If number exceeded, we link to the book page with *all* reviews.
our $MAX_REVURLS_PER_BOOK = 2;

# GR-URLs in mail padded to average length, with "https://" stripped
sub prettyurl{ return sprintf '%-36s', substr( shift, 8 ); }

# effect in dev/debugging only
# gsetcache( 4, 'hours' );



# ----------------------------------------------------------------------------
my $csv      = ( -e $CSVPATH  ?  csv( in => $CSVPATH, key => 'id' )  :  undef );  # ref
my $num_hits = 0;
my %books;

greadshelf( from_user_id    => $USERID,
            ra_from_shelves => [ $SHELF ],
            rh_into         => \%books );

if( $csv )
{
	my $mtime            = (stat $CSVPATH)[9];
	my $last_csv_updtime = Time::Piece->strptime( $mtime, '%s' );
	
	for my $b (values %books)
	{
		next unless exists $csv->{$b->{id}};
		
		my $num_new_rat = $b->{num_ratings} - $csv->{$b->{id}}->{num_ratings};
		
		next unless $num_new_rat > 0;
		
		my %revs;
		greadreviews( rh_for_book => $b, 
		              since       => $last_csv_updtime,
		              rh_into     => \%revs,
		              rigor       => 0 );
		
		next unless %revs;
		
		my $revcount = scalar keys %revs;
		
		$num_hits++;
		
		# E-Mail header and first body line:
		if( $MAILTO && $num_hits == 1 )
		{
			print( "To: ${MAILTO}\n"                           );
			print( "From: ${MAILFROM}\n"                       ) if $MAILFROM;
			print( "List-Unsubscribe: <mailto:${MAILFROM}>\n"  ) if $MAILFROM;
			print( "Content-Type: text/plain; charset=utf-8\n" );
			print( "Subject: New ratings on Goodreads.com\n\n" );  # 2x \n hdr end
			print( "Recently rated books in your \"${SHELF}\" shelf:\n" );
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
		printf( "\n  \"%s\"\n", $b->{title} );
		
		if( $revcount > $MAX_REVURLS_PER_BOOK )
		{
			printf( "   %s  [%d new]\n", prettyurl( $b->{url} ), $revcount );
		}
		else
		{
			printf( "   %s  %s\n", prettyurl( $_->{text} ? $_->{url} : $_->{rh_user}->{url} ), $_->{rating_str} )
				foreach (values %revs);
		}
	}
	
	# E-mail signature block if run for other users:
	if( $MAILFROM && $num_hits > 0 )
	{
		print "\n\n-- \n"  # RFC 3676 sig delimiter (has space char)
		    . " [***  ] 3/5 stars rating without text      \n"
		    . " [TTT  ] 3/5 stars rating with some text    \n"
		    . " [9 new] ratings better viewed on book page \n"
		    . "                                            \n"
		    . " Reply 'weekly'      to avoid daily mails   \n"
		    . " Reply 'shelf ...'   to change better shelf \n"
		    . " Reply 'unsubscribe' to unsubscribe         \n"
		    . " Via https://andre-st.github.io/goodreads/  \n";
	}
	
	# Cronjob audits:
	$_log->infof( 'Recently rated: %d of %d books in %s\'s shelf "%s"', 
			$num_hits, scalar keys %books, $USERID, $SHELF );
}

my @lines = values %books;
csv( in => \@lines, out => $CSVPATH, headers => [qw( id num_ratings )] );

