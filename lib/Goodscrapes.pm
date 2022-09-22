package Goodscrapes;
use strict;
use warnings;
use 5.18.0;
use utf8;


###############################################################################

=pod

=encoding utf8

=head1 NAME

Goodscrapes - Goodreads.com HTML-API


=head1 VERSION

=over

=item * Updated: 2022-09-22

=item * Since: 2014-11-05

=back

=cut

our $VERSION = '1.88';  # X.XX version format required by Perl


=head1 COMPARED TO THE OFFICIAL API

=over

=item * focuses on analysing, not updating info on GR

=item * less limited, e.g., reading shelves and reviews of other members:
        Goodscrapes can scrape thousands of fulltext reviews.

=item * official is slow too; API users are even second-class citizen

=item * theoretically this library is more likely to break, 
        but Goodreads progresses very very slowly: nothing
        actually broke between 2019-2014 (I started this);
        actually their API seems to change more often than
        their web pages; they can and do disable API functions 
        without being noticed by the majority, but they cannot
        easily disable important webpages that we use too;
        There are unit-tests to detect markup changes on the
        scraped Goodreads.com website.

=item * this library grew with every new usecase and program;
        it retries operations on errors on Goodreads.com,
        which are not seldom (over capacity, exceptions etc);
        it saw a lot of flawed data such as wrong review dates 
        ("Jan 01, 1010"), which broke Time::Piece.

=item * Goodreads "isn't eating its own dog food"
        https://www.goodreads.com/topic/show/18536888-is-the-public-api-maintained-at-all#comment_number_1

=back


=head1 LIMITATIONS

=over

=item * slow: version with concurrent AnyEvent::HTTP requests was marginally 
        faster, so I sticked with simpler code; doesn't actually matter
        due to Amazon's and Goodreads' request throttling. You can only
        speed things up significantly with a pool of work-sharing computers 
        and unique IP addresses...

=item * just text pattern matching, no ECMAScript execution and DOM parsing with a headless renderer
        (so far sufficient and faster). 
        Regex is not meant for HTML parsing and a HTML parser
        would had been easier from time to time, I would use one today.
        However, regular expressions proved good enough for goodreads.com,
        given that user generated content is very restricted
        and cannot easily confuse the regex patterns.
        The Regex code is small too.
        We just look at the server response as text with some features
        which mark the start and end of a value of interest.


=back


=head1 HOW TO USE

=over

=item * for real-world usage examples see Andre's Goodreads Toolbox.
        There are unit tests in the "t" directory, too. 
        Tests are good (up-to-date) tutorials and might help comprehending 
        the yet terse API documentation.

=item * C<_> prefix means I<private> function or constant (use in module only)

=item * C<ra> prefix means array reference, C<rh> prefix means hash reference

=item * C<on> prefix or C<fn> suffix means function variable

=item * constants are uppercase, functions lowercase

=item * Goodscrapes code in your program is usually recognizable by the
        'g' or 'GOOD' prefix in the function or constant name

=item * common internal abbreviations: 
        pfn = progress function, bfn = book handler function, 
        pag = page number, nam = name, au = author, bk = book, uid = user id,
        bid = book id, aid = author id, rat = rating, tit = title, 
        q   = query string, slf = shelf name, shv = shelves names, 
        t0  = start time of an operation, ret = return code, 
        tmp = temporary helper variable, gp = group, gid = group id,
	   us  = user

=back


=head1 AUTHOR

https://github.com/andre-st/


=cut

###############################################################################


use base 'Exporter';
our @EXPORT = qw( 
	$GOOD_ERRMSG_NOBOOKS
	$GOOD_ERRMSG_NOMEMBERS
	$GOOD_USEFUL_REVIEW_LEN
	
	gverifyuser
	gverifyshelf
	gisbaduser
	gmeter
	glogin
	gsetopt
	
	gsearch
	greadbook
	greaduser
	greadusergp
	greadshelf
	greadshelfnames
	greadauthors
	greadauthorbk
	greadsimilaraut
	greadreviews
	greadfolls 
	greadcomments
	gsocialnet
	
	amz_book_html
	ghtmlhead
	ghtmlfoot
	ghtmlsafe
	ghistogram
	);


# Perl core:
use Time::Piece;
use Carp             qw( croak );
use List::Util       qw( sum max min );
# Third party:
use List::MoreUtils  qw( any none );
use Cache::Cache     qw( $EXPIRES_NEVER $EXPIRES_NOW );
use Cache::FileCache;
use IO::Prompter;
use URI::Escape;
use HTML::Entities;
use HTTP::Tiny;


# Non-module message strings to be used in programs:
our $GOOD_ERRMSG_NOBOOKS   = "[FATAL] No books found. Check the privacy settings at Goodreads.com and ensure access by 'anyone (including search engines)'.";
our $GOOD_ERRMSG_NOMEMBERS = '[FATAL] No members found. Check cookie and try empty /tmp/FileCache/';

# Public constants:
our $GOOD_USEFUL_REVIEW_LEN = 500;

# Module error codes:
#   Severity levels:  0 < WARN < ERROR < CRITICAL < FATAL
#   Adding a severity level influences coping strategy
our $_ENO_WARN        = 300;  # ignore and continue
our $_ENO_GR400       = $_ENO_WARN  + 1;
our $_ENO_GR404       = $_ENO_WARN  + 2;
our $_ENO_GRSIGNIN    = $_ENO_WARN  + 3;
our $_ENO_ERROR       = 400;  # retry n times and continue
our $_ENO_GRUNAVAIL   = $_ENO_ERROR + 1;
our $_ENO_GRUNEXPECT  = $_ENO_ERROR + 2;
our $_ENO_CRIT        = 500;  # retry until user CTRL-C
our $_ENO_GRCAPACITY  = $_ENO_CRIT  + 1;
our $_ENO_GRMAINTNC   = $_ENO_CRIT  + 2;
our $_ENO_TRANSPORT   = $_ENO_CRIT  + 3;
our $_ENO_NOHTML      = $_ENO_CRIT  + 4;
our $_ENO_FATAL       = 600;  # abort
our $_ENO_NODICT      = $_ENO_FATAL + 1;
our $_ENO_BADSHELF    = $_ENO_FATAL + 2;
our $_ENO_BADUSER     = $_ENO_FATAL + 3;
our $_ENO_BADARG      = $_ENO_FATAL + 4;
our $_ENO_BADLOGIN    = $_ENO_FATAL + 5;
our $_ENO_CAPTCHA     = $_ENO_FATAL + 6;

our %_OPTIONS =  # See gseterr() for documentation
(
	ignore_errors   => 0,
	maxretries      => 5,
	retrydelay_secs => 60*3  # 15 minutes in total
);


# Misc module message strings:
our $_MSG_ERR_EPILOGUE     = "Press CTRL-C to exit (pid=$$), consider `--ignore-errors` program option";
our $_MSG_RETRYING_FOREVER = "[NOTE ] Retrying in 3 minutes... $_MSG_ERR_EPILOGUE\n";
our $_MSG_RETRYING_NTIMES  = "[NOTE ] Retrying in 3 minutes (%d times before skipping this one)... $_MSG_ERR_EPILOGUE\n";  # retriesleft

our %_ERRMSG = 
(
	# _ENO_GRxxx are messages from the Goodreads.com website:
	$_ENO_WARN       => "\n[WARN ] %s",               # url
	$_ENO_GR400      => "\n[WARN ] Bad request: %s",  # url
	$_ENO_GR404      => "\n[WARN ] Not found: %s",    # url
	$_ENO_GRSIGNIN   => "\n[WARN ] Sign-in for %s => Cookie invalid or not set: see glogin()", # url
	$_ENO_ERROR      => "\n[ERROR] %s",               # url
	$_ENO_GRUNAVAIL  => "\n[ERROR] Goodreads.com \"temporarily unavailable\".",
	$_ENO_GRUNEXPECT => "\n[ERROR] Goodreads.com encountered an \"unexpected error\": %s",  #url
	$_ENO_GRCAPACITY => "\n[CRIT ] Goodreads.com is over capacity.",
	$_ENO_GRMAINTNC  => "\n[CRIT ] Goodreads.com is down for maintenance.",
	$_ENO_TRANSPORT  => "\n[CRIT ] %s - %s %s",       # url, err, err
	$_ENO_NOHTML     => "\n[CRIT ] No HTML body: %s", # url
	$_ENO_FATAL      => "\n[FATAL] %s",               # url
	$_ENO_NODICT     => "\n[FATAL] Cannot open dictionary file: %s",       # path
	$_ENO_BADSHELF   => "\n[FATAL] Invalid Goodreads shelf name \"%s\". Look at your shelf URLs.",  # name
	$_ENO_BADUSER    => "\n[FATAL] Invalid Goodreads user ID \"%s\".",  # id
	$_ENO_BADARG     => "\n[FATAL] Argument \"%s\" expected.",             # name
	$_ENO_BADLOGIN   => "\n[FATAL] Incorrect login.",
	$_ENO_CAPTCHA    => "\n[FATAL] CAPTCHA prompted to the user. Usually short-term problem, as bots are currently taking over and users are complaining about CAPTCHAs at the same time (help forum). Retry in a few days."
);
sub _errmsg { no warnings 'redundant'; my $eno = shift; return sprintf( $_ERRMSG{$eno}, @_ ); }


# Misc module constants:
#our $_USERAGENT     = 'Googlebot/2.1 (+http://www.google.com/bot.html)';
our $_USERAGENT     = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36';
our $_NOBOOKIMGURL  = 'https://s.gr-assets.com/assets/nophoto/book/50x75-a91bf249278a81aabab721ef782c4a74.png';
our $_NOUSERIMGURL  = 'https://s.gr-assets.com/assets/nophoto/user/u_50x66-632230dc9882b4352d753eedf9396530.png';
our $_NOGROUPIMGURL = 'https://s.gr-assets.com/assets/nophoto/group/50x66-14672b6c5b97a4836a13efdb6a1958d2.jpg';
our $_ANYPRIVATEURL = 'https://www.goodreads.com/recommendations/to_me';
our $_SIGNINFORMURL = 'https://www.goodreads.com/ap/signin?'
					. 'language=en_US'
					. '&openid.assoc_handle=amzn_goodreads_web_na'
					. '&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select'
					. '&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select'
					. '&openid.mode=checkid_setup'
					. '&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0'
					. '&openid.pape.max_auth_age=0'
					. '&openid.return_to=https%3A%2F%2Fwww.goodreads.com%2Fap-handler%2Fsign-in';
our $_HOMEURL       = 'https://www.goodreads.com';
our $_SORTNEW       = 'newest';
our $_SORTOLD       = 'oldest';
our $_EARLIEST      = Time::Piece->strptime( '1970-01-01', '%Y-%m-%d' );
our @_BADPROFILES   =     # TODO external config file
(
	'1000834',  #  3.000 books   "NOT A BOOK" author
	'5158478',  # 10.000 books   "Anonymous"  author
	'67012749'  # 46429 ratings  "Subhajit Das" spam?
);
our $_MAINSTREAM_NUM_RATINGS   = 10000;
our $_MAINSTREAM_NUM_FOLLOWERS = 10000;  # Rowlings = 210,542; Nassim Taleb = 7,811, Martin Fowler = 740

our $_cookie    = undef;
our $_last_url  = 'https://www.goodreads.com';
our $_cache_age = $EXPIRES_NOW;  # see gsetopt()
our $_cache     = new Cache::FileCache({ namespace => 'Goodscrapes' });



=head1 DATA STRUCTURES

=head2 Note

=over

=item * never cast 'id' to int or use %d format string, despite digits only, 
        compare as strings

=item * don't expect all attributes set (C<undef>), 
        this depends on the available info on the scraped page

=back



=head2 %book

=over

=item * id              =E<gt> C<string>

=item * title           =E<gt> C<string>

=item * isbn            =E<gt> C<string>

=item * isbn13          =E<gt> C<string>

=item * num_pages       =E<gt> C<int>

=item * num_reviews     =E<gt> C<int>

=item * num_ratings     =E<gt> C<int>    103 for example

=item * avg_rating      =E<gt> C<float>  4.36 for example, 0 if no rating

=item * stars           =E<gt> C<int>    rounded avg_rating, e.g., 4

=item * format          =E<gt> C<string> (binding)

=item * user_rating     =E<gt> C<int>    number of stars 1,2,3,4 or 5  (program user)

=item * user_read_count =E<gt> C<int>    (program user)

=item * user_num_owned  =E<gt> C<int>    (program user)

=item * user_date_read  =E<gt> C<Time::Piece>   (program user)

=item * user_date_added =E<gt> C<Time::Piece>   (program user)

=item * ra_user_shelves =E<gt> C<string[]> reference

=item * url             =E<gt> C<string>

=item * img_url         =E<gt> C<string>

=item * review_id       =E<gt> C<string>

=item * year            =E<gt> C<int>     (original publishing date)

=item * year_edit       =E<gt> C<int>     (edition publishing date)

=item * rh_author       =E<gt> C<L<%user|"%user">> reference

=back



=head2 %user

=over

=item * id              =E<gt> C<string>

=item * name            =E<gt> C<string>  "Firstname Lastname"

=item * name_lf         =E<gt> C<string>  "Lastname, Firstname"

=item * residence       =E<gt> C<string>  (might require login)

=item * age             =E<gt> C<int>     (might require login)

=item * num_books       =E<gt> C<int>     books shelfed, not books written (even if is_author == 1)

=item * is_friend       =E<gt> C<bool>

=item * is_author       =E<gt> C<bool>

=item * is_female       =E<gt> C<bool>

=item * is_private      =E<gt> C<bool>

=item * is_staff        =E<gt> C<bool>   true if user is a Goodreads.com employee

=item * is_mainstream   =E<gt> C<bool>  
                           currently, guessed from number of ratings for any book, is_author == 1

=item * url             =E<gt> C<string> 
                           URL to the user's profile page

=item * works_url       =E<gt> C<string> 
                           URL to the author's distinct works (is_author == 1)

=item * img_url         =E<gt> C<string>

=item * user_min_rating =E<gt> C<int>
                           requires is_author == 1

=item * user_max_rating =E<gt> C<int>
                           requires is_author == 1

=item * user_avg_rating =E<gt> C<float>
                           3.3 for example (user of the program), requires is_author == 1, 
                           value depends on the shelves involved

=item * _seen           =E<gt> C<int>
                           incremented if user already exists in a load-target structure

=back



=head2 %review

=over

=item * id          =E<gt> C<string>

=item * rh_user     =E<gt> C<L<%user|"%user">> reference

=item * book_id     =E<gt> C<string>

=item * rating      =E<gt> C<int> 
                       with 0 meaning no rating, "added" or "marked it as abandoned" 
                       or something similar

=item * rating_str  =E<gt> C<string> 
                       represention of rating, e.g., 3/5 as S<"[***  ]"> or S<"[TTT  ]"> 
                       if there's additional text, or S<"[ttt  ]"> if not longer than 160 chars

=item * text        =E<gt> C<string>

=item * date        =E<gt> C<Time::Piece>

=item * url         =E<gt> C<string>  full text review

=back



=head2 %group

=over

=item * id          =E<gt> C<string>

=item * name        =E<gt> C<string>

=item * url         =E<gt> C<string>

=item * img_url     =E<gt> C<string>

=item * num_members =E<gt> int

=back



=head2 %comment

=over

=item * text       =E<gt> C<string>

=item * rh_to_user =E<gt> C<L<%user|"%user">> reference, addressed user

=item * rh_review  =E<gt> C<L<%review|"%review">> reference, addressed review,
                          undefined if not comment on a review
                          (but group, another user's status, book list, ...)

=item * rh_book    =E<gt> C<L<%book|"%book">> reference, undefined if rh_review is undefined and vice versa

=back


=cut



=head1 PUBLIC ROUTINES



=head2 C<string> gverifyuser( I<$user_id_to_verify> )

=over

=item * returns a sanitized, valid Goodreads user id or kills 
        the current process with an error message

=back

=cut

sub gverifyuser
{
	my $uid = shift // '';
	
	return $1 if $uid =~ /(\d+)/ 
		or croak( _errmsg( $_ENO_BADUSER, $uid ));
}




=head2 C<string> gverifyshelf( I<$name_to_verify> )

=over

=item * returns the given shelf name if valid 

=item * returns a shelf which includes all books if no name given

=item * kills the current process with an error message if name is malformed

=back

=cut

sub gverifyshelf
{
	my $nam = shift // ''; # '%23ALL%23';
	
	croak( _errmsg( $_ENO_BADSHELF, $nam ))
		if length $nam == 0 || $nam =~ /[^%a-zA-Z0-9_\-,]/;
		
	return $nam;
}




=head2 C<bool> gisbaduser( I<$user_or_author_id> )

=over

=item * returns true if the given user or author is blacklisted 
        and would slow down any analysis

=back

=cut

sub gisbaduser
{
	my $uid = shift or return 1;
	return any{ $_ eq $uid } @_BADPROFILES;
}




=head2 C<sub> gmeter( I<$unit_str = ''> )

=over

=item * generates and returns a CLI progress indicator function $f, 
        with I<$f-E<gt>( 20 )> adding 20 to the last values and 
        printing the sum like "40 unit_str".
        Given a second (max value) argument I<$f-E<gt>( 10, 100 )>, 
        it will print a percentage without any unit: "10%".
        Given a modern terminal, the text remains at the same 
        position if the progress function is called multiple times.

=back

=cut

sub gmeter
{
	my $unit = shift // '';
	return sub{
		state $is_first = 1;
		state $v        = 0;
		
		my $f  = defined $_[1]  ?  "%3d%%"                      :  "%5s $unit";
		   $v += defined $_[1]  ?  $_[1] ? $_[0]/$_[1]*100 : 0  :  ($_[0] || 0);  # 2nd ? avoids div by zero
		   $v  = 100 if defined $_[1] && $v > 100;  # Allows to trigger "100%" by passing (1, 1)
		my $s  = sprintf( $f, $v );
		
		my $ansicodeslen = sum( map( length, $s =~ /\x1b\[[0-9;]*m/g )) || 0;
		
		print "\b" x (length( $s )-$ansicodeslen) if !$is_first;     # Backspaces prev meter if any (same-width format str)
		print $s;
		$is_first = 0;
	};
}




=head2 C<void> glogin(I<{ ... }>)

=over

=item * some Goodreads.com pages are only accessible by authenticated members

=item * some Goodreads.com pages are optimized for authenticated members (e.g. get 200 books vs 30 books per request)

=item * C<usermail =E<gt> string>

=item * C<userpass =E<gt> string> 

=item * C<r_userid =E<gt> string ref> set user ID if variable is empty/undef [optional]

=back

=cut

sub glogin
{
	my (%args) = @_;
	my $mail   =_require_arg( 'usermail', $args{ usermail });
	my $pass   = $args{ userpass } // undef;
	my $ruid   = $args{ r_userid } // undef;
	
	# Some people don't want their password on the command line 
	# as it shows up in the command history, process list etc.
	# So we start a small dialog here if password argument is missing:
	# 
	$pass = prompt( -prompt => "Enter GR password for $mail:", 
	                -echo   => '*',
	                -return => "\nSigning in to Goodreads... ",
	                -out    => *STDOUT,
	                -in     => *STDIN ) while !$pass;
	
	# Scrape current security tokens:
	my %form;
	my $htm             = _html( $_SIGNINFORMURL, $_ENO_ERROR, 0 );
	my $signin_post_url = $htm =~ /<form.*?action="([^"]+)/ ? $1 : undef;
	$form{$1}           = $2 while( $htm =~ /<input.*?name="([^"]+).*?value="([^"]+)/gs );
	$form{'email'     } = $mail;
	$form{'password'  } = $pass;
	$form{'rememberMe'} = 'true';
	
	# Send login form:
	$htm = _html_post( $signin_post_url, \%form );
	
	# Check success:
	$htm    = _html( $_ANYPRIVATEURL, $_ENO_ERROR, 0 );
	my $uid = $htm =~ /currentUser.*?profileUrl":"\/user\/show\/(\d+)/ ? $1 : undef;
	
	print( "OK!\n" ) if $uid && !$args{ userpass };  # Only out if prompt before
	
	if( !$uid )
	{
		my $is_captcha = $htm =~ /g-recaptcha-response/;
		croak( _errmsg( $is_captcha ? $_ENO_CAPTCHA : $_ENO_BADLOGIN ));
	}
	
	$$ruid = $uid if defined $ruid && !$$ruid;       # Update userid if needed
}




=head2 C<void> gsetopt(I<{ ... }>)

=over

=item * change one or multiple library-scope parameters

=item * C<ignore_errors =E<gt> bool>
        disables retries for [ERROR] and [CRIT] with the process just keep going with the next step

=item * C<maxretries =E<gt> int> 
        sets number of retries when there is an error, 
        critical issues are retried indefinitely (if ignore_errors is false)

=item * C<retrydelay_secs =E<gt> int>

=item * C<cache_days =E<gt> int>
        sets the number of days that a resource can be loaded from the local storage.
        Scraping Goodreads.com is a very slow process;
        scraped documents can be cached if you don't need them "fresh"
        during development time
        or long running sessions (cheap recovery on crash, power blackout or pauses),
        or when experimenting with parameters

=back

=cut

sub gsetopt
{
	# TODO:  die on unknown parameters (typos etc)
	my (%args)  = @_;
	%_OPTIONS   = ( %_OPTIONS, %args );
	$_cache_age = $args{cache_days}.' days' if $args{cache_days};
}




=head2 C<L<%book|"%book">> greadbook( $book_id )

=cut

sub greadbook
{
	my $bid = _require_arg( 'book_id', shift );
	return _extract_book( _html( _book_url( $bid )));
}




=head2 C<L<%user|"%user">> greaduser( $user_id, $prefer_author = 0 )

=over

=item * there can be a different user and author with the same ID 
        (2456: Joana vs Chuck Palahniuk); 
        if there's no user but an author, Goodreads would redirect 
        to the author page with the same ID and this function
        would return the author

=item * if ambiguous you can set the I<$prefer_author> flag

=back

=cut

sub greaduser
{
	my $uid  = gverifyuser( shift );
	my $isau = shift // 0;
	my $htm  = _html( _user_url( $uid, $isau ));
	return $isau ? _extract_author( $htm ) : _extract_user( $htm );
}




=head2 C<void> greadusergp(I<{ ... }>)

=over

=item * reads all group memberships of the given user into I<rh_into>

=item * C<from_user_id =E<gt> string>

=item * C<rh_into      =E<gt> hash reference (id =E<gt> L<%group|"%group">,...)>

=item * C<on_group     =E<gt> sub( L<%group|"%group"> )> [optional]

=item * C<on_progress  =E<gt> sub> see C<gmeter()> [optional]

=back

=cut

sub greadusergp
{
	my (%args) = @_;
	my $uid    = gverifyuser( $args{ from_user_id });
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $gfn    = $args{ on_group    }  // sub{};
	my $pfn    = $args{ on_progress }  // sub{};
	my $pag    = 1;
	
	while( _extract_user_groups( $rh, $gfn, $pfn, _html( _user_groups_url( $uid, $pag++ )))) {};
}




=head2 C<void> greadshelf(I<{ ... }>)

=over

=item * reads a list of books (and/or authors) present in the given shelves of the given user

=item * C<from_user_id    =E<gt> string>

=item * C<ra_from_shelves =E<gt> string-array reference> with shelf names

=item * C<rh_into         =E<gt> hash reference (id =E<gt> L<%book|"%book">,...)> [optional]

=item * C<rh_authors_into =E<gt> hash reference (id =E<gt> L<%user|"%user">,...)> [optional];
        this parameter is for convenience and also replaces the former C<greadauthors()> function.
        It's not required to access author data as author data is available from the book data too: 
        $book-E<gt>{rh_author}-E<gt>{...}

=item * C<on_book         =E<gt> sub( L<%book|"%book"> )> [optional]

=item * C<on_progress     =E<gt> sub> see C<gmeter()> [optional]

=item * doesn't add users to C<rh_authors_into> when C<gisbaduser()> is true

=item * sets the C<user_XXX> and C<is_mainstream> fields in each author item

=back

=cut

sub greadshelf
{
	my (%args) = @_;
	my $uid    = gverifyuser( $args{ from_user_id });
	my $ra_shv =_require_arg( 'ra_from_shelves', $args{ ra_from_shelves });
	my $rh     = $args{ rh_into         }  // undef;
	my $rh_au  = $args{ rh_authors_into }  // ();
	my $bfn    = $args{ on_book         }  // sub{};
	my $pfn    = $args{ on_progress     }  // sub{};
	my %books; # Using pre-populated $rh would confuse progess counters, so empty hash
	
	gverifyshelf( $_ ) foreach (@$ra_shv);
	
	# Scrape books and authors from paginated shelf pages:
	for my $s (@$ra_shv)
	{
		my $pag = 1;
		while( _extract_books( \%books, $rh_au, $bfn, $pfn, _html( _shelf_url( $uid, $s, $pag++ )))) {}
	}
	
	# Merge:
	%$rh = ( %$rh, %books ) if $rh;
	
	_update_author_stats( $rh );  # Updates $rh_au too (all references)
}




=head2 C<void> greadshelfnames(I<{ ... }>)

=over

=item * reads the names of all shelves of the given user

=item * C<from_user_id    =E<gt> string>

=item * C<ra_into         =E<gt> array reference>

=item * C<ra_exclude      =E<gt> array reference> won't add given names to the result  [optional]  

=item * Precondition: glogin()

=item * Postcondition: result includes 'read', 'to-read', 'currently-reading', but doesn't include '#ALL#'

=back

=cut

sub greadshelfnames
{
	# The 'compare books' page allows us to scrape *all* shelf names using a
	# single request. The user profile page wouldn't show *all* shelves
	# and the shelf-view page is paginated using AJAX with authentication tokens
	# (which also returns Javascript code for eval).
	# So, scraping the 'compare books' page is much easier but requires a login.
	
	my (%args) = @_;
	my $uid    = gverifyuser( $args{ from_user_id });
	my $ra     = _require_arg( 'ra_into', $args{ ra_into });
	my $ra_ex  = $args{ ra_exclude } // [];
	my $htm    = _html( "https://www.goodreads.com/user/compare/${uid}" );
	my $htmsel = $htm =~ /<select name="friend_shelf" (.*?)<\/select>/mgs ? $1 : '';
	
	while( $htmsel =~ /<option value="([^"]+)/gs )
	{
		my $name = $1;
		push( @$ra, $name ) if none{ $_ eq $name } @{$ra_ex};
	}

}




=head2 C<void> _update_author_stats(I<rh_from_books>)

=over

=item * sets the C<user_XXX> and C<is_mainstream> fields in each author item

=back

=cut

sub _update_author_stats
{
	my $rh = shift;
	my %rat_count_for;
	my %rat_sum_for;
	my %rat_min_for;
	my %rat_max_for;
	my %is_mainstream;
	
	# 1. Get an overview over all books:
	for my $bid (keys %{$rh})
	{
		next unless $rh->{$bid}->{user_rating};
		my $aid = $rh->{$bid}->{rh_author}->{id};
		my $rat = $rh->{$bid}->{user_rating};
		$rat_count_for{$aid} ++;
		$rat_sum_for{$aid}   += $rat;
		$is_mainstream{$aid}  = $is_mainstream{$aid} || $rh->{$bid}->{num_ratings} >= $_MAINSTREAM_NUM_RATINGS;
		$rat_min_for{$aid}    = min( $rat, $rat_min_for{$aid} // $rat );
		$rat_max_for{$aid}    = max( $rat, $rat_max_for{$aid} // $rat );
	}
	
	# 2. Update each single book (author) with overall data:
	for my $bid (keys %{$rh})
	{
		my $aid = $rh->{$bid}->{rh_author}->{id};
		$rh->{$bid}->{rh_author}->{user_avg_rating} = $rat_count_for{$aid} ? $rat_sum_for{$aid} / $rat_count_for{$aid} : 0;  # Be aware of div by zero
		$rh->{$bid}->{rh_author}->{user_min_rating} = $rat_min_for{$aid};
		$rh->{$bid}->{rh_author}->{user_max_rating} = $rat_max_for{$aid};
		$rh->{$bid}->{rh_author}->{is_mainstream  } = $is_mainstream{$aid};
	}
}




=head2 C<void> greadauthors(I<{ ... }>)

=over

=item * DEPRECATED: use C<greadshelf()> with C<rh_authors_into> parameter

=item * gets a list of authors whose books are present in the given shelves of the given 

=item * C<from_user_id    =E<gt> string>

=item * C<ra_from_shelves =E<gt> string-array reference> with shelf names

=item * C<rh_into         =E<gt> hash reference (id =E<gt> L<%user|"%user">,...)> [optional]

=item * C<on_progress     =E<gt> sub> see C<gmeter()> [optional]

=item * If you need authors I<and> books data, then use C<greadshelf>
        which also populates the I<author> property of every book

=item * skips authors where C<gisbaduser()> is true

=item * sets the C<user_XXX> and C<is_mainstream> fields in each author item

=back

=cut

sub greadauthors
{
	my (%args) = @_;
	my $rh     = $args{ rh_into     }  // undef;
	my $pfn    = $args{ on_progress }  // sub{};
	my %auts;  # Using pre-populated $rh would confuse progress counters
	
	my $pickauthorsfn = sub
	{
		my $aid = $_[0]->{rh_author}->{id};
		return if gisbaduser( $aid );	
		if( !exists $auts{$aid} )
		{
			$pfn->( 1 );  # Don't *count* duplicates (multiple shelves)
			$auts{$aid} = $_[0]->{rh_author};
		}
	};
	
	greadshelf( from_user_id    => $args{ from_user_id    },
	            ra_from_shelves => $args{ ra_from_shelves },
	            on_book         => $pickauthorsfn );
	
	%$rh = ( %$rh, %auts ) if $rh;  # Merge
}




=head2 C<void> greadauthorbk(I<{ ... }>)

=over

=item * reads the Goodreads.com list of books written by the given author

=item * C<author_id      =E<gt> string>

=item * C<limit          =E<gt> int> number of books to read into C<rh_into>

=item * C<rh_into        =E<gt> hash reference (id =E<gt> L<%book|"%book">,...)>

=item * C<on_book        =E<gt> sub( L<%book|"%book"> )> [optional]

=item * C<on_progress    =E<gt> sub> see C<gmeter()> [optional]

=back

=cut

sub greadauthorbk
{
	my (%args) = @_;	
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $aid    = gverifyuser( $args{ author_id });
	my $limit  = $args{ limit       }  // 999999999;
	my $bfn    = $args{ on_book     }  // sub{};
	my $pfn    = $args{ on_progress }  // sub{};
	my $pag    = 1;
	
	while( _extract_author_books( $rh, \$limit, $bfn, $pfn, _html( _author_books_url( $aid, $pag++ )))) {};
}




=head2 C<void> greadreviews(I<{ ... }>)

=over

=item * loads ratings (no text), reviews (text), "to-read", "added" etc;
        you can filter later or via I<on_filter> parameter

=item * C<rh_for_book =E<gt> hash reference L<%book|"%book">>, see C<greadbook()>

=item * C<rh_into     =E<gt> hash reference (id =E<gt> L<%review|"%review">,...)>

=item * C<since       =E<gt> Time::Piece> [optional]

=item * C<on_filter   =E<gt> sub( L<%review|"%review"> )>, return 0 to drop [optional]

=item * C<on_progress =E<gt> sub> see C<gmeter()> [optional]

=item * C<dict_path   =E<gt> string> path to a dictionary file (1 word per line) [optional]

=item * C<text_minlen =E<gt> int> overwrites C<on_filter> argument [optional, default 0 ]
  
   0  =  no text filtering
   n  =  specified minimum length (see also GOOD_USEFUL_REVIEW_LEN constant)

=item * C<rigor       =E<gt> int> [optional, default 2]

  level 0   = search newest reviews only (max 300 ratings)
  level 1   = search with a combination of filters (max 5400 ratings)
  level 2   = like 1 plus dict-search if more than 3000 ratings with stall-time of 2 minutes
  level n   = like 1 plus dict-search with stall-time of n minutes

=back

=cut

sub greadreviews
{
	my (%args)   = @_;
	my $rh_book  =_require_arg( 'rh_for_book', $args{ rh_for_book });
	my $rigor    = $args{ rigor       }  // 2;
	my $dictpath = $args{ dict_path   }  // undef;
	my $rh       = $args{ rh_into     }  // undef;
	my $txtlen   = $args{ text_minlen }  // 0;
	my $pfn      = $args{ on_progress }  // sub{};
	my $since    = $args{ since       }  // $_EARLIEST;
	   $since    = Time::Piece->strptime( $since->ymd, '%Y-%m-%d' );  # Nullified time in GR too
	my $limit    = $txtlen ? ( $rh_book->{num_reviews}  // 5000000 ) 
	                       : ( $rh_book->{num_ratings}  // 5000000 );
	my $ffn      = $txtlen ? ( sub{ length( $_[0]->{text} ) >= $txtlen })
	                       : ( $args{ on_filter }  // sub{ return 1 } );
	my $bid      = $rh_book->{id};
	my %revs;    # Unique and empty, otherwise we cannot easily compute limits
	
	
	# Allow user to interrupt search with CTRL-C:
	my $gotsigint   = 0;
	#local $SIG{INT} = sub{ $gotsigint = 1; };  	
	
	# Goodreads reviews filters get us dissimilar(!) subsets which are merged
	# here: Don't assume that these filters just load a _subset_ of what you
	# see if _no filters_ are applied. Given enough ratings and reviews, each
	# filter finds reviews not included in any other subset.  Theoretical
	# limit here is 5400 reviews: 6*3 filter combinations * max. 300 displayed 
	# reviews (Goodreads limit).
	# 
	my @rateargs = $rigor == 0 ? ( undef     ) : ( undef, 1..5                 );
	my @sortargs = $rigor == 0 ? ( $_SORTNEW ) : ( undef, $_SORTNEW, $_SORTOLD );
	for my $r (@rateargs)
	{
		for my $s (@sortargs)
		{
			my $pag = 1;
			while( _extract_revs( \%revs, $pfn, $ffn, $since, _html( _revs_url( $bid, $s, $r, undef, undef, $pag++ )))) {};
			
			# "to-read", "added" have to be loaded before the rated/reviews
			# (undef in both argument-lists first) - otherwise we finish
			# too early since $limit equals the number of *ratings* only.
			# Ugly code but correct in theory:
			# 
			my $numrated = scalar( grep{ defined $_->{rating} } values %revs ); 
			goto DONE if $numrated >= $limit || $gotsigint;
		}
	}
	

	# Dict-search works well with many ratings but sometimes poorly with few.
	# Woolf's "To the Lighthouse" has 5514 text reviews: 948 found without 
	# dict-search, with dict-search: 3057 (ngrams) or 4962 (words).
	# If searching and searching and nothing happens after $stalltime seconds
	# then we abort this method.
	# 
	goto DONE if $rigor <  2;
	goto DONE if $rigor == 2 && $limit < 3000;
	
	my $stalltime = $rigor * 60;
	my $t0        = time;  # Stuff above might already take 60s
	
	open( my $fh, '<', $dictpath ) or croak( _errmsg( $_ENO_NODICT, $dictpath ));
	chomp( my @dict = <$fh> );
	close $fh;
	
	for my $word (@dict)
	{
		goto DONE if time-$t0 > $stalltime 
				|| scalar keys %revs >= $limit 
				|| $gotsigint;
		
		my $numbefore = scalar keys %revs;
		
		my $pag = 1;
		while( _extract_revs( \%revs, $pfn, $ffn, $since, _html( _revs_url( $bid, undef, undef, $word, undef, $pag++ )))) {};
		
		$t0 = time if scalar keys %revs > $numbefore;  # Resets stall-timer
	}
	
DONE:
	
	%$rh = ( %$rh, %revs ) if $rh;  # Merge
}




=head2 C<void> greadfolls(I<{ ... }>)

=over

=item * queries Goodreads.com for the friends and followees list of the given user

=item * C<rh_into            =E<gt> hash reference (id =E<gt> L<%user|"%user">,...)>

=item * C<from_user_id       =E<gt> string>

=item * C<on_user            =E<gt> sub( %user )> return false to exclude user from $rh_into [optional]

=item * C<on_progress        =E<gt> sub> see C<gmeter()> [optional]

=item * C<discard_threshold> =E<gt> number> don't add anything to $rh_into if number of folls exceeds limit [optional];
                                    use this to drop degenerated accounts which would just add noise to the data

=item * C<incl_authors       =E<gt> bool> [optional, default 1]

=item * C<incl_friends       =E<gt> bool> [optional, default 1]

=item * C<incl_followees     =E<gt> bool> [optional, default 1]

=item * Precondition: glogin()

=back

=cut

sub greadfolls
{
	my (%args)  = @_;
	my $rh      =_require_arg( 'rh_into', $args{ rh_into });
	my $uid     = gverifyuser( $args{ from_user_id });
	my $isaut   = $args{ incl_authors      } // 1;
	my $isfrn   = $args{ incl_friends      } // 1;
	my $isfol   = $args{ incl_followees    } // 1;
	my $dishold = $args{ discard_threshold } // 9999999;
	my $ufn     = $args{ on_user           } // sub{ 1 };   # TODO
	my $pfn     = $args{ on_progress       } // sub{   };   # TODO
	my $pag;
	
	if( $isfol )
	{
		$pag = 1; 
		while( _extract_followees( $rh, $pfn, $isaut, $dishold, _html( _followees_url( $uid, $pag++ )))) {};
	}
	
	if( $isfrn )
	{
		$pag = 1; 
		while( _extract_friends( $rh, $pfn, $isaut, $dishold, _html( _friends_url( $uid, $pag++ )))) {};
	}
	
}




=head2 C<void> greadcomments(I<{ ... }>)

=over

=item * reads a list of all comments posted from the given user on goodreads.com;
        it does not read a conversation by multiple users on some topic

=item * C<from_user_id =E<gt> string>

=item * C<ra_into      =E<gt> array reference (L<%comment|"%comment">,...)> [optional]

=item * C<limit        =E<gt> int> stop after reading N comments [optional, default 0 ]

=item * C<on_progress  =E<gt> sub> see C<gmeter()> [optional]

=back

=cut

sub greadcomments
{
	my (%args) = @_;
	my $uid    = gverifyuser( $args{ from_user_id });
	my $ra     = $args{ ra_into     }  // undef;
	my $limit  = $args{ limit       }  // 0;
	my $pfn    = $args{ on_progress }  // sub{   };
	
	my $pag = 1;
	while( _extract_comments( $ra, $pfn, _html( _comments_url( $uid, $pag++ )))) {}
}




=head2 C<void> gsocialnet(I<{ ... }>)

=over

=item * C<from_user_id    =E<gt> string>

=item * C<rh_into_nodes   =E<gt> hash reference (id =E<gt> L<%user|"%user">,...)>

=item * C<ra_into_edges   =E<gt> array reference ({from =E<gt> id, to =E<gt> id},...)>

=item * C<ignore_nhood_gt =E<gt> int> ignore users with with a neighbourhood > N [optional, default 1000];
                                      such users just add noise to the data and waste computing time

=item * C<depth           =E<gt> int>  [optional, default 1]

=item * C<incl_authors    =E<gt> bool> [optional, default 0]

=item * C<incl_friends    =E<gt> bool> [optional, default 1]

=item * C<incl_followees  =E<gt> bool> [optional, default 1]

=item * C<on_progress     =E<gt> sub({ done =E<gt> int, count =E<gt> int, perc =E<gt> int, depth =E<gt> int })>  [optional]

=item * C<on_user         =E<gt> sub( %user )> return false to exclude user [optional]

=item * Precondition: glogin()

=back

=cut

sub gsocialnet
{
	my (%args) = @_;
	my $uid    =_require_arg( 'from_user_id',  $args{ from_user_id  });
	my $rh_n   =_require_arg( 'rh_into_nodes', $args{ rh_into_nodes });
	my $ra_e   =_require_arg( 'ra_into_edges', $args{ ra_into_edges });
	
	$args{ depth           } //= 2;
	$args{ on_user         } //= sub{ 1 };
	$args{ on_progress     } //= sub{   };
	$args{ ignore_nhood_gt } //= 1000;
	$args{ incl_friends    } //= 1;
	$args{ incl_followees  } //= 1;
	$args{ incl_authors    } //= 0;
	
	return if $args{ depth } == 0;               # Stop recursion or if nonsense arg
	return if any{ $_->{from} eq $uid } @$ra_e;  # Avoid loops
	
	my %nhood;
	greadfolls( rh_into           => \%nhood,
	            from_user_id      => $args{ from_user_id    },
	            on_user           => $args{ on_user         },
	            discard_threshold => $args{ ignore_nhood_gt },
	            incl_authors      => $args{ incl_authors    },
	            incl_followees    => $args{ incl_followees  },
	            incl_friends      => $args{ incl_friends    });
	
	   %$rh_n       = ( %$rh_n, %nhood );
	my $nhood_count = scalar( keys %nhood );
	my $nhood_done  = 0;
	
	for my $nhood_uid (keys %nhood)
	{
		$args{ on_progress }->( done    =>   $nhood_done,
		                        count   =>   $nhood_count,
		                        perc    => ++$nhood_done / $nhood_count * 100,
		                        depth   =>   $args{depth},
		                        from_id =>   $uid,
		                        to_id   =>   $nhood_uid );
		
		push( @$ra_e, { from => $uid, to => $nhood_uid });
		
		gsocialnet( from_user_id    => $nhood_uid,
		            rh_into_nodes   => $rh_n,
		            ra_into_edges   => $ra_e,
		            depth           => $args{ depth           } - 1,  # !!
		            on_user         => $args{ on_user         },
		            on_progress     => $args{ on_progress     },
		            ignore_nhood_gt => $args{ ignore_nhood_gt },
		            incl_friends    => $args{ incl_friends    },	
		            incl_followees  => $args{ incl_followees  },
		            incl_authors    => $args{ incl_authors    })  # Recursion not very deep
	}
}




=head2 C<void> greadsimilaraut(I<{ ... }>)

=over

=item * reads the Goodreads.com list of authors who are similar to the given author

=item * C<rh_into     =E<gt> hash reference (id =E<gt> L<%user|"%user">,...)>

=item * C<author_id   =E<gt> string>

=item * C<on_progress =E<gt> sub> see C<gmeter()> [optional]

=item * increments C<'_seen'> counter of each author if already in I<%$rh_into>

=back

=cut

sub greadsimilaraut
{
	my (%args) = @_;
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $aid    = gverifyuser( $args{ author_id });
	my $pfn    = $args{ on_progress } // sub{};
	
	# Just 1 page:
	_extract_similar_authors( $rh, $aid, $pfn, _html( _similar_authors_url( $aid )));
}




=head2 C<void> gsearch(I<{ ... }>)

=over

=item * searches the Goodreads.com database for books that match a given phrase

=item * C<ra_into     =E<gt> array reference (L<%book|"%book">,...)> 

=item * C<phrase      =E<gt> string> with space separated keywords

=item * C<is_exact    =E<gt> bool> [optional, default 0]

=item * C<ra_order_by =E<gt> array reference> property names from C<L<%book|"%book">> 
                       [optional, default: 'stars', 'num_ratings', 'year']

=item * C<num_ratings =E<gt> int> only list books with at least N ratings [optional, default 0]

=item * C<on_progress =E<gt> sub> see C<gmeter()>  [optional]

=back

=cut

sub gsearch
{
	my (%args) = @_;
	my $ra     =    _require_arg( 'ra_into', $args{ ra_into });
	my $q      = lc _require_arg( 'phrase',  $args{ phrase  });
	my $pfn    = $args{ on_progress }  // sub{};
	my $n      = $args{ num_ratings }  // 0;
	my $e      = $args{ is_exact    }  // 0;
	my $ra_ord = $args{ ra_order_by }  // [ 'stars', 'num_ratings', 'year' ];
	my $pag    = 1;
	my @tmp;
	
	while( _extract_search_books( \@tmp, $pfn, _html( _search_url( $q, $pag++ )))) {};
	
	# Select and sort:
	@tmp = grep{ $_->{num_ratings}           >= $n } @tmp;
	@tmp = grep{ index( lc $_->{title}, $q ) != -1 } @tmp if $e;
	@$ra = sort  # TODO check index vs number of elements
	{
		$b->{ $ra_ord->[0] } <=> $a->{ $ra_ord->[0] } ||
		$b->{ $ra_ord->[1] } <=> $a->{ $ra_ord->[1] } ||
		$b->{ $ra_ord->[2] } <=> $a->{ $ra_ord->[2] }
	} @tmp;
}




=head2 C<string> amz_book_html( I<L<%book|"%book">> )

=over

=item * HTML body of an Amazon article page

=back

=cut

sub amz_book_html
{
	return _html( _amz_url( shift ) );
}





###############################################################################

=head1 PUBLIC REPORT-GENERATION HELPERS



=head2 C<string> ghtmlhead( I<$title, $ra_cols > )

=over

=item * returns a string with HTML boiler plate code for a table-based report

=item * $title: HTML title, Table caption

=item * $ra_cols: [ "Normal", ">Sort ASC", "<Sort DESC", "!Not sortable/searchable", "Right-Aligned:", ">Sort ASC, right-aligned:", ":Centered:" ]

=back

=cut

sub ghtmlhead
{
	my $title   = shift;  
	my $ra_cols = shift;
	my $jsorder = '';
	my $jscols  = '';
	my $th      = '';
	
	for my $i (0 .. $#{$ra_cols})
	{
		$jscols  .= "{ 'targets': $i, 'orderable': false, 'searchable': false }, " if $ra_cols->[$i] =~ /!/;
		$jscols  .= "{ 'targets': $i, 'className': 'dt-body-right'  }, "           if $ra_cols->[$i] =~ /^[^:].*:/;
		$jscols  .= "{ 'targets': $i, 'className': 'dt-body-center' }, "           if $ra_cols->[$i] =~ /:.*:/;
		$jsorder .= "[ $i, 'desc' ], "                                             if $ra_cols->[$i] =~ />/;
		$jsorder .= "[ $i, 'asc'  ], "                                             if $ra_cols->[$i] =~ /</;
		$th      .= '<th>' . ( $ra_cols->[$i] =~ /^[^a-zA-Z]*(.*?)[^a-zA-Z]*$/ ? $1 : '' ) . '</th>';  # Title w/o codes
	}
	
	return qq{
		<!DOCTYPE html>
		<html lang="en">
		<head>
		<meta charset="utf-8">
		<title>$title</title>
		<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
		<script src="https://cdn.datatables.net/1.10.12/js/jquery.dataTables.min.js"></script>
		<link rel="stylesheet" property="stylesheet" type="text/css" media="all" 
				href="https://cdn.datatables.net/1.10.12/css/jquery.dataTables.min.css" />
		<script>
		/* Any HTML other than a table should be added via JS, so we have nothing but a plain
		   HTML table in the body which can be easily opened in office programs (Excel etc) */
		
		\$( document ).ready( function()
		{ 
			\$( 'table' ).DataTable(
			{
				"lengthMenu": [[ 7, 20, 50, 100, 250, 500, -1    ],   // Values
				               [ 7, 20, 50, 100, 250, 500, "All" ]],  // Labels
				"pageLength": 7,
				"autoWidth" : false,             // Adjust "Added by" col-width on re-ordering
				"pagingType": "full_numbers",
				"order"     : [ $jsorder ],
				"columnDefs": [ $jscols  ]
			});
			
			/* Only available with DataTable: */
			\$( 'body' ).append( '<p><strong>Order by multiple columns at the same time:</strong>'
					+ '<br>Use <kbd>Shift</kbd> and click on a column '
					+ '(added the clicked column as a secondary, tertiary etc ordering column)</p>' );
		});
		</script>
		<style>
			body 
			{
				font-family: sans-serif; 
			}
			table th 
			{
				border: 1px solid #ccc; 
			}
			table.dataTable tbody td 
			{
				vertical-align: top; 
			}
			kbd 
			{		    	
				border-radius: 3px;
				border: 1px solid #b4b4b4;
				box-shadow: 0 1px 1px rgba(0, 0, 0, .2), 0 2px 0 0 rgba(255, 255, 255, .7) inset;
				display: inline-block;
				font-size: .85em;
				font-weight: 700;
				line-height: 1;
				padding: 2px 4px;
				white-space: nowrap; 
			}
			.gr-user, gr-author
			{
				display: inline-block;
				float: left;
				width: 50px;
				margin: 0 2px 7px 2px;
			}
			gr-author
			{
				font-size: 8pt;
				text-align: center;
				background-color: #eeeddf;
				height: 120px;	
			}
			.gr-user img, gr-author img 
			{
				width: 100%;
			}
			gr-author img
			{
				margin: 0 0 5px 0;
			}
			img 
			{
				max-width: 150px;
				display: block;
			}
		</style>
		</head>
		<body>
		<table class="hover row-border order-column" style="width:100%">
		<caption>Table: $title</caption>
		<thead> <tr> $th </tr> </thead>
		<tbody>
		};
}




=head2 C<string> ghtmlfoot()

=over

=item * returns a string with HTML boiler plate code for a table-based report

=back

=cut

sub ghtmlfoot
{
	return qq{
		</tbody>
		</table>
		</body>
		</html>
		};
}




=head2 C<string> ghtmlsafe(I<$string>)

=over

=item * always use this when generating HTML reports in order to prevent 
        cross site scripting attacks (XSS) through malicious text on the 
        Goodreads.com website

=back

=cut

sub ghtmlsafe
{
	# This function is not just an alias but encapsulates the encoder details.
	return encode_entities( shift );
}




=head2 C<void> ghistogram(I<{ ... }>)

=over

=item * prints a year-based histogram for the given hash on the terminal

=item * C<rh_from    =E<gt> hash reference (id =E<gt> %any,...)>

=item * C<date_key   =E<gt> string> name of the Time::Piece component of any hash item [optional, default 'date']

=item * C<start_year =E<gt> int> [optional, default 2007]

=item * C<title      =E<gt> string> [optional, default '...reviews...']

=item * C<bar_width  =E<gt> int> [optional, default 40]

=item * C<bar_char   =E<gt> char> [optional, default '#']

=back

=cut

sub ghistogram
{
	my (%args)   = @_;
	my $rh       =_require_arg( 'rh_from', $args{ rh_from });
	my $datekey  = $args{'date_key'  }  // 'date';
	my $ystart   = $args{'start_year'}  // 2007;
	my $title    = $args{'title'     }  // "\n\nNumber of reviews per year:";
	my $barwidth = $args{'bar_width' }  // 40;
	my $barchar  = $args{'bar_char'  }  // '#';
	my %ycount;
	
	print( $title );
	
	$ycount{$_} = 0                 for ($ystart .. (localtime)[5]);  # Years not in hash
	$ycount{$_->{$datekey}->year}++ for (values %{$rh});
	
	my $maxycount = max( values %ycount );
	
	printf( "\n%d %-${barwidth}s %5d", $_, $barchar x ($barwidth/$maxycount*$ycount{$_}), $ycount{$_} )
		for (sort{ $a <=> $b } keys %ycount);
}




###############################################################################

=head1 PRIVATE URL-GENERATION ROUTINES



=head2 C<string> _amz_url( I<L<%book|"%book">> )

=over

=item * Requires at least {isbn=E<gt>string}

=back

=cut

sub _amz_url
{
	my $book = shift;
	return $book->{isbn} ? "http://www.amazon.de/gp/product/$book->{isbn}" : undef;
}




=head2 C<string> _shelf_url( I<$user_id, $shelf_name, $page_number = 1> )

=over

=item * URL for a page with a list of books (not all books)

=item * "&print=true" allows 200 items per page with a single request, 
        which is a huge speed improvement over loading books from the "normal" 
        view with max 20 books per request.
        Showing 100 books in normal view is oddly realized by 5 AJAX requests
        on the Goodreads.com website.

=item * "&per_page" in print-view can be any number if you work with your 
        own shelf, otherwise max 200 if print view; ignored in non-print view;
        per_page>20 requires access with a cookie, see glogin()

=item * "&view=table" puts I<all> book data in code, although invisible (display=none)

=item * "&sort=rating" is important for `friendrated.pl` with its book limit:
        Some users read 9000+ books and scraping would take forever. 
        We sort lower-rated books to the end and I<could> just scrape the first pages:
        Even those with 9000+ books haven't top-rated more than 2700 books.

=item * "&shelf" supports intersection "shelf1%2Cshelf2" (comma)

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _shelf_url  
{
	my $uid = shift;
	my $slf = shift;	
	my $pag = shift // 1;
	
	$slf =~ s/#/%23/g;  # "#ALL#" shelf
	$slf =~ s/,/%2C/g;  # Shelf intersection
	
	return "https://www.goodreads.com/review/list/${uid}?"
	     . "&print=true"
	     . "&shelf=${slf}"
	     . "&page=${pag}"
	     . "&sort=rating"
	     . "&order=d"
	     . "&view=table"
	     . "&title="
	     . "&per_page=200";
}




=head2 C<string> _followees_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of the people $user is following

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _followees_url
{
	my $uid = shift;
	my $pag = shift // 1;
	return "https://www.goodreads.com/user/${uid}/following?page=${pag}";
}




=head2 C<string> _friends_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of people befriended to C<$user_id>

=item * "&sort=date_added" (as opposed to 'last online') avoids 
        moving targets while reading page by page

=item * "&skip_mutual_friends=false" because we're not doing
        this just for me

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _friends_url
{
	my $uid = shift;
	my $pag = shift // 1;
	return "https://www.goodreads.com/friend/user/${uid}?"
	     . "&page=${pag}"
	     . "&skip_mutual_friends=false"
	     . "&sort=date_added";
}




=head2 C<string> _book_url( I<$book_id> )

=cut

sub _book_url
{
	my $bid = shift;
	return "https://www.goodreads.com/book/show/${bid}";
}




=head2 C<string> _user_url( I<$user_id, $is_author = 0> )

=cut

sub _user_url
{
	my $uid   = shift or return undef;
	my $is_au = shift // 0;
	return 'https://www.goodreads.com/'.( $is_au ? 'author' : 'user' )."/show/${uid}";
}




=head2 C<string> _revs_url( I<$book_id, $str_sort_newest_oldest = undef, 
		$search_text = undef, $rating = undef, $is_text_only = undef, $page_number = 1> )

=over

=item * "&sort=newest" and "&sort=oldest" reduce the number of reviews for 
        some reason (also observable on the Goodreads website), 
        so only use if really needed (&sort=default)

=item * "&search_text=example" invalidates sort order argument

=item * "&rating=5"

=item * "&text_only=true" just returns 1 page, you might get more text-reviews without this flag

=item * the maximum of retrievable pages is 10 (300 reviews), see
        https://www.goodreads.com/topic/show/18937232-why-can-t-we-see-past-page-10-of-book-s-reviews?comment=172163745#comment_172163745

=item * seems less throttled, not true for text-search

=back

=cut

sub _revs_url
{
	my $bid  = shift;
	my $sort = shift;
	my $rat  = shift;
	my $q    = shift;
	   $q    =~ s/\s+/+/g  if $q;
	my $txt  = shift;
	my $pag  = shift // 1;
	my $url  =  "https://www.goodreads.com/book/reviews/${bid}?"
			.( $sort && !$q ? "sort=${sort}&"     : '' )
			.( $q           ? "search_text=${q}&" : '' )
			.( $rat         ? "rating=${rat}&"    : '' )
			.( $txt         ? "text_only=true&"   : '' )
			. "page=${pag}";
	
	return $url;
}




=head2 C<string> _rev_url( I<$review_id> )

=cut

sub _rev_url
{
	my $rid = shift;
	return "https://www.goodreads.com/review/show/${rid}";
}




=head2 C<string> _author_books_url( I<$user_id, $page_number = 1> )

=cut

sub _author_books_url
{
	my $uid = shift or return undef;
	my $pag = shift // 1;
	return "https://www.goodreads.com/author/list/${uid}?per_page=100&sort=popularity&page=${pag}";
}




=head2 C<string> _author_followings_url( I<$author_id, $page_number = 1> )

=cut

sub _author_followings_url
{
	my $uid = shift;
	my $pag = shift // 1;
	return "https://www.goodreads.com/author_followings?id=${uid}&page=${pag}";
}




=head2 C<string> _similar_authors_url( I<$author_id> )

=over

=item * page number > N just returns same page, so no easy stop criteria;
        not sure, if there's more than page, though

=back

=cut

sub _similar_authors_url
{
	my $uid = shift;
	return "https://www.goodreads.com/author/similar/${uid}";
}




=head2 C<string> _search_url( I<phrase_str, $page_number = 1> )

=over

=item * "&q=" URL-encoded, e.g., linux+%40+"hase (linux @ "hase)

=back

=cut

sub _search_url
{
	my $q   = uri_escape( shift );
	my $pag = shift // 1;
	return "https://www.goodreads.com/search?page=${pag}&tab=books&q=${q}";
}




=head2 C<string> _user_groups_url( I<$user_id>, I<$page_number = 1> )

=cut

sub _user_groups_url
{
	my $uid = shift;
	my $pag = shift // 1;
	return "https://www.goodreads.com/group/list/${uid}?sort=title&page=${pag}";
}




=head2 C<string> _group_url( I<$group_id> )

=cut

sub _group_url
{
	my $gid = shift;
	return "https://www.goodreads.com/group/show/${gid}";
}




=head2 C<string> _comments_url( I<$user_id, $page_number = 1> )

=cut

sub _comments_url
{
	my $uid = shift;
	my $pag = shift // 1;
	return "https://www.goodreads.com/comment/list/${uid}?page=${pag}";
}




###############################################################################

=head1 PRIVATE HTML-EXTRACTION ROUTINES



=head2 C<L<%book|"%book">> _extract_book( I<$book_page_html_str> )

=cut

sub _extract_book
{
	my $htm = shift or return;
	my %bk;
	
	$bk{ id          } = $htm =~ /id="book_id" value="([^"]+)"/                         ? $1 : undef;
	
	return if !$bk{id};
	
	$bk{ isbn13      } = $htm =~ /<meta content='([^']+)' property='books:isbn'/        ? $1 : ''; # ISBN13
	$bk{ isbn        } = undef;  # TODO
	$bk{ img_url     } = $htm =~ /<meta content='([^']+)' property='og:image'/          ? $1 : '';
	$bk{ title       } = $htm =~ /<meta content='([^']+)' property='og:title'/          ? _dec_entities( $1 ) : '';
	$bk{ num_pages   } = $htm =~ /<meta content='([^']+)' property='books:page_count'/  ? $1 : $_NOBOOKIMGURL;
	$bk{ num_reviews } = $htm =~ /(\d+)[,.]?(\d*)[,.]?(\d*) review/    ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
	$bk{ num_ratings } = $htm =~ /(\d+)[,.]?(\d*)[,.]?(\d*) rating/    ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
	$bk{ avg_rating  } = $htm =~ /itemprop="ratingValue">\s*([0-9.]+)/ ? $1       : 0;  # # 3.77
	$bk{ stars       } = int( $bk{ avg_rating } + 0.5 );
	$bk{ url         } = _book_url( $bk{id} );
	$bk{ rh_author   } = undef;  # TODO
	$bk{ year        } = undef;  # TODO
	$bk{ year_edit   } = undef;  # TODO
	$bk{ format      } = undef;  # TODO
	
	return %bk;
}



=head2 C<L<%user|"%user">> _extract_user( I<$user_page_html_str> )

=cut

sub _extract_user
{
	my $htm = shift or return;
	my %us;
	$us{ id } = $htm =~ /<meta property="og:url" content="https:\/\/www\.goodreads\.com\/user\/show\/(\d+)/ ? $1 : undef;
	
	return _extract_author( $htm ) if !$us{id};  # Might be redirected to author page
	
	my $fname = $htm =~ /<meta property="profile:first_name" content="([^"]+)/ ? _dec_entities( $1     )." " : "";
	my $lname = $htm =~ /<meta property="profile:last_name" content="([^"]+)/  ? _dec_entities( $1     )." " : "";
	my $uname = $htm =~ /<meta property="profile:username" content="([^"]+)/   ? _dec_entities( "($1)" )     : "";
	$us{ name          } = _trim( $fname.$lname.$uname );
	$us{ name_lf       } = $us{name};  # TODO
	$us{ num_books     } = $htm =~ /<meta content='[^']+ has (\d+)[,.]?(\d*)[,.]?(\d*) books/ ? $1.$2.$3 : 0;
	$us{ age           } = $htm =~ /<div class="infoBoxRowItem">[^<]*Age (\d+)/               ? $1 : 0;
	$us{ is_female     } = $htm =~ /<div class="infoBoxRowItem">[^<]*Female/                  ? 1  : 0;
	$us{ is_private    } = $htm =~ /<div id="privateProfile"/                                 ? 1  : 0;
	$us{ is_staff      } = $htm =~ /(Goodreads employee|Goodreads Founder)/                   ? 1  : 0;
	$us{ img_url       } = $htm =~ /<meta property="og:image" content="([^"]+)/               ? $1 : $_NOUSERIMGURL;
	$us{ works_url     } = undef;
	$us{ is_friend     } = undef;
	$us{ is_author     } = 0;
	$us{ is_mainstream } = undef;
	$us{ url           } = _user_url( $us{id}, $us{is_author} );
	$us{ _seen         } = 1;
	
	# Details string doesn't include Firstname/Middlename/Lastname, no Zip-Code
	# Also depedent on viewer's login status
	my $r = $htm =~ /Details<\/div>\s*<div class="infoBoxRowItem">([^<]+)/ ? _dec_entities( $1 ) : "";
	   $r =~ s/Age \d+,?//;        # remove optional Age part
	   $r =~ s/(Male|Female),?//;  # remove optional gender; TODO custom genders (neglectable atm)
	   $r =~ s/^\s+|\s+$//g;       # trim both ends
	   $r =~ s/\s*,\s*/, /g;       # "City , State" -> "City, State" (some consistency)
	$us{ residence } = ($r =~ m/any details yet/) ? '' : $r;  # remaining string is the residence (City, State)
		
	return %us;
}



=head2 C<L<%user|"%user">> _extract_author( I<$user_page_html_str> )

=cut

sub _extract_author
{
	my $htm = shift or return;
	my %us;
	my $num_ratings = $htm =~ /(\d+)[,.]?(\d*)[,.]?(\d*) rating/ ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
	
	$us{ id            } = $htm =~ /<meta content='https:\/\/www\.goodreads\.com\/author\/show\/(\d+)/ ? $1 : undef;
	$us{ name          } = $htm =~ /<meta content='([^']+)' property='og:title'>/ ? _dec_entities( $1 ) : "";
	$us{ name_lf       } = $us{name};   # TODO
	$us{ img_url       } = $htm =~ /<meta content='([^']+)' property='og:image'>/ ? $1 : $_NOUSERIMGURL;
	$us{ is_staff      } = $htm =~ /<h3 class="right goodreadsAuthor">/           ? 1  : 0;
	$us{ is_private    } = 0;
	$us{ is_female     } = undef;  # TODO
	$us{ is_mainstream } = $num_ratings >= $_MAINSTREAM_NUM_RATINGS;
	$us{ is_friend     } = undef;
	$us{ is_author     } = 1;
	$us{ works_url     } = _author_books_url( $us{id} );
	$us{ residence     } = undef;
	$us{ num_books     } = $htm =~ /=reviews">(\d+)[,.]?(\d*)[,.]?(\d*) ratings</ ? $1.$2.$3 : 0; # Closest we can get
	$us{ url           } = _user_url( $us{id}, $us{is_author} );
	$us{ _seen         } = 1;
	
	return %us;
}



=head2 C<bool> _extract_books( I<$rh_books, $rh_authors, $on_book_fn, $on_progress_fn, $shelf_tableview_html_str> )

=over

=item * I<$rh_books>: C<(id =E<gt> L<%book|"\%book">,...)>

=item * I<$rh_authors>: C<(id =E<gt> L<%user|"\%user">,...)>

=item * returns 0 if no books, 1 if books, 2 if error

=back

=cut

sub _extract_books
{
	my $rh    = shift;
	my $rh_au = shift;  # Reuse author refs from here (if exists)
	my $bfn   = shift;
	my $pfn   = shift;
	my $htm   = shift or return 2;
	my $ret   = 0;
	
	# TODO verify if shelf is the given one or redirected by GR to #ALL# bc misspelled	
	
	while( $htm =~ /<tr id="review_\d+" class="bookalike review">(.*?)<\/tr>/gs ) # each book row
	{	
		my $row = $1;
		my %bk;
		
		my $tit = $row =~ />title<\/label><div class="value">\s*<a[^>]+>\s*(.*?)\s*<\/a>/s  ? $1 : '';
		   $tit =~ s/\<[^\>]+\>//g;          # remove HTML tags "Title <span>(Volume 2)</span>"
		   $tit =~ s/( {1,}|[\r\n])/ /g;     # reduce spaces
		   $tit = _dec_entities( $tit );     # &quot -> "
		
		# There are many "NOT A BOOK" books with different IDs which lack information such as author ID etc
		next if $tit eq 'NOT A BOOK';
		
		my $dadd  = $row =~ />date added<\/label><div class="value">\s*<span title="([^"]*)/ ? $1 : undef;
		my $dread = $row =~ /<span class="date_read_value">([^<]*)/                          ? $1 : undef;
		my $tadd  = $dadd  ? Time::Piece->strptime( $dadd,  "%B %d, %Y" ) : $_EARLIEST;    # "June 19, 2015"
		my $tread = $dread ? eval{   Time::Piece->strptime( $dread, "%b %d, %Y" );   } ||  # "Sep 06, 2018"
		                     eval{   Time::Piece->strptime( $dread, "%b %Y"     );   } ||  # "Sep 2018"
		                     eval{   Time::Piece->strptime( $dread, "%Y"        );   } ||  # "2018"
		                     $_EARLIEST
		                   : $_EARLIEST;
		
		$bk{ id              } = $row =~ /data-resource-id="([0-9]+)"/                                                ? $1 : undef;
		$bk{ year            } = $row =~         />date pub<\/label><div class="value">.*?(-?\d+)\s*</s               ? $1 : 0;  # "2017" and "Feb 01, 2017" and "-50" (BC) and "177"
		$bk{ year_edit       } = $row =~ />date pub edition<\/label><div class="value">.*?(-?\d+)\s*</s               ? $1 : 0;  # "2017" and "Feb 01, 2017" and "-50" (BC) and "177"
		$bk{ isbn            } = $row =~             />isbn<\/label><div class="value">\s*([0-9X\-]*)/                ? $1 : '';
		$bk{ isbn13          } = $row =~           />isbn13<\/label><div class="value">\s*([0-9X\-]*)/                ? $1 : '';
		$bk{ avg_rating      } = $row =~       />avg rating<\/label><div class="value">\s*([0-9\.]*)/                 ? $1 : 0;
		$bk{ num_pages       } = $row =~        />num pages<\/label><div class="value">\s*<nobr>\s*(\d*)/             ? $1 : 0;
		$bk{ num_ratings     } = $row =~      />num ratings<\/label><div class="value">\s*(\d+)[,.]?(\d*)[,.]?(\d*)/  ? $1.$2.$3 : 0;
		$bk{ format          } = $row =~           />format<\/label><div class="value">\s*((.*?)(\s*<))/s             ? _dec_entities( $2 ) : ""; # also trims ">  avc def  <"
		$bk{ user_read_count } = $row =~     /># times read<\/label><div class="value">\s*(\d+)/                      ? $1 : 0;
		$bk{ user_num_owned  } = $row =~            />owned<\/label><div class="value">\s*(\d+)/                      ? $1 : 0;
		$bk{ user_date_added } = $tadd;
		$bk{ user_date_read  } = $tread;
		$bk{ user_rating     } =      $row =~ /data-rating="(\d+)"/                                                   ? $1 : undef;  #  User 2 has staticStar, my own shelf data-rating
		$bk{ user_rating     } = () = $row =~ /staticStar p10/g                                                       if(! $bk{user_rating});  # Counts occurances
		$bk{ ra_user_shelves } = [];     # TODO
		$bk{ num_reviews     } = undef;  # Not available here!
		$bk{ img_url         } = $row =~ /<img [^>]* src="([^"]+)"/                                                   ? $1 : $_NOBOOKIMGURL;
		$bk{ review_id       } = $row =~ /review\/show\/(\d+)"/                                                    ? $1 : undef;
		$bk{ title           } = _trim( $tit );
		$bk{ url             } = _book_url( $bk{id} );
		$bk{ stars           } = int( $bk{ avg_rating } + 0.5 );
		
		# Reuse author (by ref) or create new one:
		my $aid = $row =~ /author\/show\/([0-9]+)/ ? $1 : undef;
		if( $rh_au && exists $rh_au->{$aid} )
		{
			$bk{ rh_author } = $rh_au->{$aid};
		}
		else
		{
			my %au;
			$au{ id         } = $aid;
			$au{ name_lf    } = $row =~ /author\/show\/[^>]+>([^<]+)/  ? _dec_entities( $1 ) : '';
			$au{ name       } = $au{name_lf};  # Shelves already list names with "lastname, firstname"
			$au{ residence  } = undef;
			$au{ url        } = _user_url( $au{id}, 1 );
			$au{ works_url  } = _author_books_url( $au{id} );
			$au{ is_author  } = 1;
			$au{ is_private } = 0;
			$au{ _seen      } = 1;
			$bk{ rh_author  } = \%au;
			
			$rh_au->{ $aid } = \%au if $rh_au;  # Add to the given authors pool
		}
		
		$bk{ rh_author }->{ is_mainstream } = $bk{ rh_author }->{ is_mainstream }
		                                   || $bk{ num_ratings } >= $_MAINSTREAM_NUM_RATINGS;
		
		
		$ret++ unless exists $rh->{$bk{id}};  # Don't count duplicates (multiple shelves)
		$rh->{ $bk{id} } = \%bk if $rh;
		$bfn->( \%bk );
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_author_books( I<$rh_books, $r_limit, $on_book_fn, $on_progress_fn, $html_str> )

=over

=item * I<$rh_books>: C<(id =E<gt> L<%book|"\%book">,...)>

=item * I<$r_limit>: is counted to zero

=item * returns 0 if no books, 1 if books, 2 if error

=back

=cut

sub _extract_author_books
{
	# Book without title on https://www.goodreads.com/author/list/1094257
	
	my $rh      = shift;
	my $r_limit = shift;
	my $bfn     = shift;
	my $pfn     = shift;
	my $htm     = shift or return 2;
	my $auimg   = $htm =~ /(https:\/\/images.gr-assets.com\/authors\/.*?\.jpg)/gs  ? $1 : $_NOUSERIMGURL;
	my $aid     = $htm =~ /author\/show\/([0-9]+)/                                 ? $1 : undef;
	my $aunm    = $htm =~ /<h1>Books by ([^<]+)/                                   ? _dec_entities( $1 ) : '';
	my $ret     = 0;
	
	return $ret if $$r_limit == 0;
	
	my %au;
	$au{ id         } = $aid;
	$au{ name       } = _trim( $aunm );
	$au{ name_lf    } = $au{name};  # TODO
	$au{ residence  } = undef;
	$au{ img_url    } = $auimg;
	$au{ url        } = _user_url( $aid, 1 );
	$au{ works_url  } = _author_books_url( $aid );
	$au{ is_author  } = 1;
	$au{ is_private } = 0;
	$au{ _seen      } = 1;
	
	while( $htm =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row = $1;
		my %bk;
		
		$bk{ rh_author   } = \%au;
		$bk{ id          } = $row =~ /book\/show\/([0-9]+)/                 ? $1       : undef;
		$bk{ num_ratings } = $row =~ /(\d+)[,.]?(\d*)[,.]?(\d*) rating/     ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
		$bk{ avg_rating  } = $row =~ /(\d+)[,.]?(\d*)[,.]?(\d*) avg rating/ ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
		$bk{ img_url     } = $row =~ /src="([^"]+)/                         ? $1       : $_NOBOOKIMGURL;
		$bk{ title       } = $row =~ /<span itemprop='name'[^>]*>([^<]+)/   ? _dec_entities( $1 ) : '';
		$bk{ url         } = _book_url( $bk{id} );
		$bk{ isbn        } = undef;  # TODO?
		$bk{ isbn13      } = undef;  # TODO?
		$bk{ format      } = undef;  # TODO?
		$bk{ num_pages   } = undef;  # TODO?
		$bk{ year        } = undef;  # TODO?
		$bk{ year_edit   } = undef;  # TODO?
		$bk{ rh_author   }->{ is_mainstream } = $bk{ rh_author }->{ is_mainstream } 
		                                     || $bk{num_ratings} >= $_MAINSTREAM_NUM_RATINGS;
		
		$ret++; # Count duplicates too: 10 books of author A, 9 of B; called for single author
		$rh->{ $bk{id} } = \%bk;
		$bfn->( \%bk );
		$$r_limit--;
		last if !$$r_limit;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_followees( I<$rh_users, $on_progress_fn, $incl_authors, $discard_threshold, $following_page_html_str> )

=over

=item * I<$rh_users>: C<(user_id =E<gt> L<%user|"\%user">,...)>

=item * returns 0 if no followees, 1 if followees, 2 if error

=back

=cut

sub _extract_followees
{
	my $rh      = shift;
	my $pfn     = shift;
	my $iau     = shift;
	my $dishold = shift;
	my $htm     = shift or return 2;
	my $ret     = 0;
	my $pgcount = $htm =~ />(\d+)<\/a> <a class="next_page"/ ? $1 : 1;
	my $total   = $pgcount * 30;  # Items per page
	
	return 0 if $total > $dishold;
	
	while( $htm =~ /<div class='followingItem elementList'>(.*?)<\/a>/gs )
	{
		my $row = $1;
		my $uid = $row =~   /\/user\/show\/([0-9]+)/   ? $1 : undef;
		my $aid = $row =~ /\/author\/show\/([0-9]+)/   ? $1 : undef;	
		my %us;
		
		$us{ id            } = $uid ? $uid : $aid;
		$us{ name          } = $row =~ /img alt="([^"]+)/  ? _dec_entities( $1 ) : '';
		$us{ name_lf       } = $us{name};  # TODO
		$us{ img_url       } = $row =~ /src="([^"]+)/      ? $1                        : $_NOUSERIMGURL;
		$us{ works_url     } = $aid                        ? _author_books_url( $aid ) : '';
		$us{ url           } = _user_url( $us{id}, $aid );
		$us{ is_author     } = defined $aid;
		$us{ is_friend     } = 0;
		$us{ is_mainstream } = undef;
		$us{ _seen         } = 1;
		$us{ residence     } = undef;  # TODO?
		$us{ num_books     } = undef;  # TODO?
		
		next if !$iau && $us{is_author};
		$ret++;
		$rh->{ $us{id} } = \%us;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_friends( I<$rh_users, $on_progress_fn, $incl_authors, $discard_threshold, $friends_page_html_str> )

=over

=item * I<$rh_users>: C<(user_id =E<gt> L<%user|"\%user">,...)> 

=item * returns 0 if no friends, 1 if friends, 2 if error

=back

=cut

sub _extract_friends
{
	my $rh      = shift;
	my $pfn     = shift;
	my $iau     = shift;
	my $dishold = shift;
	my $htm     = shift or return 2;
	my $ret     = 0;
	my $total   = $htm =~ /Showing \d+-\d+ of (\d+)/ ? $1 : -1;
	
	return 0 if $total > $dishold;
	
	while( $htm =~ /<tr>\s*<td width="1%">(.*?)<\/td>/gs )
	{
		my $row = $1;
		my $uid = $row =~   /\/user\/show\/([0-9]+)/   ? $1 : undef;
		my $aid = $row =~ /\/author\/show\/([0-9]+)/   ? $1 : undef;
		my %us;
		
		$us{ id            } = $uid ? $uid : $aid;
		$us{ name          } = $row =~ /img alt="([^"]+)/  ? _dec_entities( $1 ) : '';
		$us{ name_lf       } = $us{name};  # TODO
		$us{ img_url       } = $row =~     /src="([^"]+)/  ? $1                        : $_NOUSERIMGURL;
		$us{ works_url     } = $aid                        ? _author_books_url( $aid ) : '';
		$us{ url           } = _user_url( $us{id}, $aid );
		$us{ is_author     } = defined $aid;
		$us{ is_friend     } = 1;
		$us{ is_mainstream } = undef;
		$us{ _seen         } = 1;
		$us{ residence     } = undef;  # TODO?
		$us{ num_books     } = undef;  # TODO?
		
		next if !$iau && $us{ is_author };
		$ret++;
		$rh->{ $us{id} } = \%us;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_comments( I<$ra, $on_progress, $comment_history_html_str> )

=cut

sub _extract_comments
{
	
	my $ra  = shift;
	my $pfn = shift;
	my $htm = shift or return 2;
	my $ret = 0;
	
	# UserA's comments:
	#   UserA's review of BookX   (comments thread about own review, might address UserC)
	#   UserB's review of BookX   (comments thread about other's review, might address UserD)
	#   UserA's status            (comments thread about own status), might address UserE)
	#   UserB's status            (comments thread about other's status, might address userF)
	#   UserB's answer to "QuestionX?"
	#   UserB is a friend of UserC
	#   AuthorX's quote: "QuoteX"
	#   GroupX group.             (comment on a topic in this group)
	#   ...?
	
	while( $htm =~ /<div class='brownBox'>(.*?)(<div class='brownBox'>|<\/form>)/gs )
	{
		my $row = $1;
		my %cm;
		my %bk;
		my %rv;
		my %to_us;
		
		my $img_url  = $row =~ /<img src="([^"]*)/       ? $1 : undef;
		   $rv{ id } = $row =~ /review\/show\/([0-9]+)/  ? $1 : undef;
		
		if( $rv{ id } )  # Comment on a review
		{
			$to_us{ name   } = $row =~ />([^<]*)<\/a>'s review/  ? $1 : undef;
			
			$rv{ url       } = _rev_url( $rv{ id });
			$rv{ rh_user   } = \%to_us;
			
			$bk{ title     } = $row =~ /review of <a [^>]*>([^<]*)/  ? $1 : undef;
			$bk{ review_id } = $rv{ id };
			$bk{ url       } = _search_url( $bk{title} );
			$bk{ img_url   } = $img_url // $_NOBOOKIMGURL;
			
			$cm{ rh_review } = \%rv;
			$cm{ rh_book   } = \%bk;
			$cm{ text      } = $row =~ /<img [^>]*><\/a>(.*?)<div/s  ? $1 : '';
		}
		else  # Comment on a status or sth else
		{
			$to_us{ name } =  $row =~ />(.*?)(&#39;|\xe2\x80\x99|')s (status|answer)</  ? $1 :
			                 ($row =~ />(.*?) is a friend of/                           ? $1 : undef);
			
			$cm{ text    } = $row =~ /commentsListBodyText'>(.*?)<div class='clear'/s  ? $1 : '';
		}
		
		$cm{ text       } =~ s/^\s+|\s+$//g;  # trim
		$cm{ rh_to_user } = \%to_us  if( $to_us{ name });
		$ret++;
		push( @$ra, \%cm );
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<string> _conv_uni_codepoints( I<$string> )

=over

=item Convert Unicode codepoints such as \u003c

=back

=cut

sub _conv_uni_codepoints
{
	# TODO: "Illegal hexadecimal digit 'n' ignored"	
	my $str = shift;
	$str    =~ s/\\u(....)/ pack 'U*', hex($1) /eg; 
	return $str;
}




=head2 C<string> _dec_entities( I<$string> )

=cut

sub _dec_entities
{
	return _trim( decode_entities( shift ));
}




=head2 C<$value> _require_arg( I<$name, $value> )

=cut

sub _require_arg
{
	my $nam = shift;
	my $val = shift;
	croak( _errmsg( $_ENO_BADARG, $nam )) if !defined $val;
	return $val;
}




=head2 C<string> _trim( I<$string> )

=cut

sub _trim
{
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s;
}




=head2 C<bool> _extract_revs( I<$rh_revs, $on_progress_fn, $filter_fn, $since_time_piece, $reviews_xhr_html_str> )

=over

=item * I<$rh_revs>: C<(review_id =E<gt> L<%review|"\%review">,...)>

=item * returns 0 if no reviews, 1 if reviews, 2 if error

=back

=cut

sub _extract_revs
{
	my $rh           = shift;
	my $pfn          = shift;
	my $ffn          = shift;
	my $since_tpiece = shift;
	my $htm          = shift or return 2;
	my $bid          = $htm =~ /\/book\/reviews\/([0-9]+)/  ? $1 : undef;
	my $ret          = 0;
	
	# < is \u003c, > is \u003e,  " is \" literally
	while( $htm =~ /div id=\\"review_\d+(.*?)div class=\\"clear/gs )
	{
		my $row = $1;
		
		# Avoid username "0" eval to false somewhere -> "0" instead of 0
		#
		# [x] Parse-error "Jan 01, 1010" https://www.goodreads.com/review/show/1369192313
		# [x] img alt=\"David T\"   
		# [x] img alt=\"0\"
		# [ ] img alt="\u0026quot;Greg Adkins\u0026quot;\"  TODO
		
		my $dat        = $row =~ /([A-Z][a-z]+ \d+, (19[7-9][0-9]|2\d{3}))/  ? $1 : undef;
		my $dat_tpiece = $dat ? Time::Piece->strptime( $dat, '%b %d, %Y' ) : $_EARLIEST; 
		
		next if $dat_tpiece < $since_tpiece;
		
		my %us;
		my %rv;
		
		# There's a short and a long text variant both saved in $row
		my $txts = $row =~ /id=\\"freeTextContainer[^"]+"\\u003e(.*?)\\u003c\/span/                     ? _dec_entities( $1 ) : '';
		my $txt  = $row =~ /id=\\"freeText[0-9]+\\" style=\\"display:none\\"\\u003e(.*?)\\u003c\/span/  ? _dec_entities( $1 ) : '';
		   $txt  = $txts if length( $txts ) > length( $txt );
		
		$txt =~ s/\\"/"/g;
		$txt = _conv_uni_codepoints( $txt );
		$txt =~ s/<br \/>/\n/g;
		
		$us{ id            } = $row =~ /\/user\/show\/([0-9]+)/ ? $1 : undef;
		$us{ name          } = $row =~ /img alt=\\"(.*?)\\"/    ? ($1 eq '0' ? '"0"' : _dec_entities( $1 )) : '';
		$us{ name_lf       } = $us{name};  # TODO
		$us{ img_url       } = $_NOUSERIMGURL;  # TODO
		$us{ url           } = _user_url( $us{id} );
		$us{ is_mainstream } = undef;  # = $reviewed_book->{rh_author}->{is_mainstream}
		$us{ _seen         } = 1;
		
		$rv{ id            } = $row =~ /\/review\/show\/([0-9]+)/ ? $1 : undef;
		$rv{ text          } = $txt;
		$rv{ rating        } = () = $row =~ /staticStar p10/g;  # Count occurances
		$rv{ rating_str    } = $rv{rating} ? ('[' . ($rv{text} ? (length($rv{text})>=$GOOD_USEFUL_REVIEW_LEN?'T':'t') : '*') x $rv{rating} . ' ' x (5-$rv{rating}) . ']') : '[added]';
		$rv{ url           } = _rev_url( $rv{id} );
		$rv{ date          } = $dat_tpiece;
		$rv{ book_id       } = $bid;
		$rv{ rh_user       } = \%us;
		
		if( $ffn->( \%rv ) )  # Filter
		{
			$ret++ unless exists $rh->{$rv{id}};  # Don't count duplicates (multiple searches for same book)
			$rh->{ $rv{id} } = \%rv;
		}
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_similar_authors( I<$rh_into, $author_id_to_skip, 
			$on_progress_fn, $similar_page_html_str> )

=over

=item * returns 0 if no authors, 1 if authors, 2 if error

=back

=cut

sub _extract_similar_authors
{
	my $rh          = shift;
	my $uid_to_skip = shift;
	my $pfn         = shift;
	my $htm         = shift or return 2;
	my $ret         = 0;
	
	# All nice JSON since 2019-03-25, but as long as it's simple
	# we still regex and avoid dependencies to a JSON module
	# 
	while( $htm =~ /<div data-react-class="ReactComponents.SimilarAuthorsList" data-react-props="([^"]*)/gs )
	{	
		my $json = _conv_uni_codepoints( _dec_entities( $1 ));
		while( $json =~ /\{"author":\{"id":([^,]+),"name":"([^"]+)",[^\{]*"profileImage":"([^"]+)",.*?"ratingsCount":([0-9]+)/gs )
		{
			my %au;
			$au{ id      } = $1;
			$au{ name    } = _trim( $2 );
			$au{ img_url } = $3;
			my $num_rats   = $4 // 0;  # best book rating in the source but not visible on the website
			
			next if $au{id} eq $uid_to_skip;
			
			$ret++;  # Incl. duplicates: 10 similar to author A, 9 to B; A and B can incl same similar authors
					
			if( exists $rh->{$au{id}} )
			{
				$rh->{$au{id}}->{_seen}++;  # similarauth.pl
				next;
			}
			
			$au{ name_lf       } = $au{name};  # TODO
			$au{ url           } = _user_url( $au{id}, 1 );
			$au{ works_url     } = _author_books_url( $au{id} );
			$au{ is_author     } = 1;
			$au{ is_private    } = 0;
			$au{ is_mainstream } = $num_rats >= $_MAINSTREAM_NUM_RATINGS;
			$au{ _seen         } = 1;
			$au{ residence     } = undef;  # TODO?
			$au{ num_books     } = undef;  # TODO
			
			$rh->{ $au{id} } = \%au;
		}
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_search_books( I<$ra_books, $on_progress_fn, $search_result_html_str>  )

=over

=item * result pages sometimes have different number of items: 
        P1: 20, P2: 16, P3: 19

=item * website says "about 75 results" but shows 70 (I checked that manually).
        So we fake "100%" to the progress indicator function at the end,
        otherwise it stops with "93%".

=item * I<ra_books>: C<(L<%book|"\%book">,...)> 

=item * returns 0 if no books, 1 if books, 2 if error

=back

=cut

sub _extract_search_books
{
	my $ra  = shift;
	my $pfn = shift;
	my $htm = shift or return 2;
	my $ret = 0;
	my $max = $htm =~ /Page \d+ of about (\d+) results/  ? $1 : 0;
	
	# We check against the stated number of results, alternative exit 
	# conditions: Page 100 (Page 100+x == Page 100), or "NO RESULTS."
	if( scalar @$ra >= $max )
	{
		$pfn->( 1, 1 );
		return 0;
	}
	
	while( $htm =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row = $1;
		my %au;
		my %bk;
		
		$au{ id              } = $row =~ /\/author\/show\/([0-9]+)/  ? $1 : undef;
		$au{ name            } = $row =~ /<a class="authorName" [^>]+><span itemprop="name">([^<]+)/  ? _dec_entities( $1 ) : '';
		$au{ name_lf         } = $au{name};  # TODO
		$au{ url             } = _user_url        ( $au{id}, 1 );
		$au{ works_url       } = _author_books_url( $au{id}    );
		$au{ img_url         } = $_NOUSERIMGURL;
		$au{ is_author       } = 1;
		$au{ is_private      } = 0;
		$au{ _seen           } = 1;
		
		$bk{ id              } = $row =~ /book\/show\/([0-9]+)/               ? $1       : undef;
		$bk{ num_ratings     } = $row =~ /(\d+)[,.]?(\d*)[,.]?(\d*) rating/   ? $1.$2.$3 : 0;  # 1,600,200 -> 1600200
		$bk{ avg_rating      } = $row =~ /([0-9.,]+) avg rating/              ? $1       : 0;  # 3.8
		$bk{ year            } = $row =~ /published\s+(-?\d+)/                ? $1       : 0;  # "2018", "-50" (BC)
		$bk{ img_url         } = $row =~ /src="([^"]+)/                       ? $1       : $_NOBOOKIMGURL;
		$bk{ title           } = $row =~ /<span itemprop='name'[^>]*>([^<]+)/ ? _dec_entities( $1 ) : '';
		$bk{ url             } = _book_url( $bk{id} );
		$bk{ stars           } = int( $bk{ avg_rating } + 0.5 );
		$bk{ rh_author       } = \%au;
		$bk{ ra_user_shelves } = [];
		
		$au{ is_mainstream   } = $bk{num_ratings} >= $_MAINSTREAM_NUM_RATINGS;
		
		push( @$ra, \%bk );
		$ret++;  # There are no duplicates, no extra checks
	}
	
	$pfn->( $ret, $max );
	return $ret;
}




=head2 C<bool> _extract_user_groups( I<$rh_into, $on_group_fn, on_progress_fn, $groups_html_str> )

=over

=item * returns 0 if no groups, 1 if groups, 2 if error

=back

=cut

sub _extract_user_groups
{
	my $rh  = shift;
	my $gfn = shift;
	my $pfn = shift;
	my $htm = shift or return 2;
	my $ret = 0;
	
	while( $htm =~ /<div class="elementList">(.*?)<div class="clear">/gs )
	{
		my $row = $1;
		my %gp;
		
		$gp{ id          } = $row =~ /\/group\/show\/(\d+)/               ? $1 : undef;
		$gp{ name        } = $row =~ /<a class="groupName" [^>]+>([^<]+)/ ? _dec_entities( $1 ) : "";
		$gp{ num_members } = $row =~ /(\d+) member/                       ? $1 : 0;  # "8397"
		$gp{ img_url     } = $row =~ /<img src="([^"]+)/                  ? $1 : $_NOGROUPIMGURL;
		$gp{ url         } = _group_url( $gp{id} );
		
		$rh->{$gp{id}} = \%gp;
		$ret++;
		$gfn->( \%gp );
	}
	
	$pfn->( $ret );
	return $ret;
}




###############################################################################

=head1 PRIVATE I/O PLUMBING SUBROUTINES




=head2 C<int> _check_page( I<$any_html_str> )

=over

=item * returns I<$_ENO_XXX> constants

=item * warn if sign-in page (https://www.goodreads.com/user/sign_in) or in-page message

=item * warn if "page unavailable, Goodreads request took too long"

=item * warn if "page not found" 

=item * error if page unavailable: "An unexpected error occurred. 
	We will investigate this problem as soon as possible"

=item * error if over capacity (TODO UNTESTED):
        "<?>Goodreads is over capacity.</?> 
        <?>You can never have too many books, but Goodreads can sometimes
        have too many visitors. Don't worry! We are working to increase 
        our capacity.</?>
        <?>Please reload the page to try again.</?>
        <a ...>get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DejvR6dUwAActHc.jpg
        https://pbs.twimg.com/media/CwMBEJAUIAA2bln.jpg
        https://pbs.twimg.com/media/CFOw6YGWgAA1H9G.png  (with title)

=item * error if maintenance mode (TODO UNTESTED):
        "<?>Goodreads is down for maintenance.</?>
        <?>We expect to be back within minutes. Please try again soon!<?>
        <a ...>Get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DgKMR6qXUAAIBMm.jpg
        https://i.redditmedia.com/-Fv-2QQx2DeXRzFBRKmTof7pwP0ZddmEzpRnQU1p9YI.png

=item * error if website temporarily unavailable (TODO UNTESTED):
        "Our website is currently unavailable while we make some improvements
        to our service. We'll be open for business again soon,
        please come back shortly to try again. <?>
        Thank you for your patience." (No Alice error)
        https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/hostedimages/1404319071i/10224522.png

=back

=cut

sub _check_page
{
	my $htm = shift or return $_ENO_NOHTML;
	
	# Try to be precise, don't stop just because someone wrote a pattern 
	# in his review or a book title. Characters such as < and > are 
	# encoded in user texts:
	
	return $_ENO_GRSIGNIN
		if $htm =~ /<head>\s*<title>\s*Sign in\s*<\/title>/s 
		|| $htm =~ /<head>\s*<title>\s*Sign Up\s*<\/title>/s;
		
	return $_ENO_GR400
		if $htm =~ /<head>\s*<title>\s*400 Bad Request\s*<\/title>/s;
	
	return $_ENO_GR404
		if $htm =~ /<head>\s*<title>\s*Page not found\s*<\/title>/s;
	
	return $_ENO_GRUNAVAIL
		if $htm =~ /Our website is currently unavailable while we make some improvements/s; # TODO improve
			
	return $_ENO_GRUNEXPECT
		if $htm =~ /<head>\s*<title>\s*Goodreads - unexpected error\s*<\/title>/s;
	
	return $_ENO_GRCAPACITY
		if $htm =~ /<head>\s*<title>\s*Goodreads is over capacity\s*<\/title>/s;
	
	return $_ENO_GRMAINTNC
		if $htm =~ /<head>\s*<title>\s*Goodreads is down for maintenance\s*<\/title>/s;
	
	return 0;
}




=head2 C<void> _updcookie(I< $string_with_changed_fields >)

=over

=item updates "_session_id2" for X-CSRF-Token, "csid", "u" (user?). "p" (password?)

=back

=cut

sub _updcookie
{
	my $changes = shift or return;
	$changes    = join( '; ', @{$changes} ) if eval{ \@$changes };  # Array instead of string given
	my %new     = _cookie2hash( $changes );
	my %c       = _cookie2hash( $_cookie );
	$c{$_}      = $new{$_} for keys %new;   # Merge new and old
	$_cookie    = join( '; ', map{ "$_=$c{$_}" } keys %c );
}

sub _cookie2hash  # @TODO: ugly, we should hold a dict and construct the string only in _html
{
	my @fields = split( /;/, shift // '' );
	my %r      = ();
	for my $f (@fields)
	{
		$f =~ /^\s*([^=]+)=(.+)$/;
		$r{$1}=$2 if $1 && $2;
	}
	return %r;
}




=head2 C<string> _html( I<$url, $warn_level = $_ENO_WARN, $can_cache = 1> )

=over

=item * HTML body of a web document

=item * caches documents (if I<$can_cache> is true)

=item * retries on errors

=back

=cut

sub _html
{
	my $url       = shift or return '';
	my $warnlevel = shift // $_ENO_WARN;
	my $cancache  = shift // 1;
	my $retry     = $_OPTIONS{maxretries};
	my $htm;
	
	$htm = $_cache->get( $url )
		if $cancache && $_cache_age ne $EXPIRES_NOW;
	
	return $htm
		if defined $htm;
	
DOWNLOAD:
	my %headers;
	   $headers{'User-Agent'      } = $_USERAGENT;
	   $headers{'Cookie'          } = $_cookie         if $_cookie;
	   $headers{'X-Requested-With'} = 'XMLHttpRequest' if index( $url, '/book/reviews/' ) != -1;
	   $headers{'Referer'         } = $_last_url; 
	   $headers{'Accept-Language' } = 'en-US;q=0.8,en;q=0.7';  # OpenID sign-in requirement
	
	$_last_url = $url;
	
	my $resp = HTTP::Tiny
			->new( timeout => 20 )
			->get( $url, { headers => \%headers });
	
	_updcookie( $resp->{headers}->{'set-cookie'} )  # Security tokens, session ids etc
		if $resp->{headers}->{'set-cookie'};
	
	my $errno = $resp->{status} < 599               # Tiny exception pseudo status code
			? _check_page( $resp->{content} )     # HTTP or GR app errors
			: $_ENO_TRANSPORT;                    # Tiny-lib intern error
	
	warn( _errmsg( $errno, $url, $resp->{content}, $resp->{reason}))
		if $errno >= $warnlevel;
	
	if(( $errno >= $_ENO_CRIT  && !$_OPTIONS{ignore_errors}                 )
	|| ( $errno >= $_ENO_ERROR && !$_OPTIONS{ignore_errors} && $retry-- > 0 ))
	{
		warn( $errno >= $_ENO_CRIT 
				? $_MSG_RETRYING_FOREVER
				: sprintf( $_MSG_RETRYING_NTIMES, $retry + 1 ));
		
		sleep( $_OPTIONS{retrydelay_secs} );
		goto DOWNLOAD;
	}
	
DONE:
	$_cache->set( $url, $resp->{content}, $_cache_age )
		if $cancache && $errno == 0;  # Don't cache errors
	
	return $resp->{content};
}




=head2 C<string> _html_post( I<$url, $rh_form_fields> )

=over

=item * Sends a POST request with given payload to the given URL

=back

=cut

sub _html_post
{
	my $url       = shift or return '';
	my $rh_fields = shift;
	my %headers;
	   $headers{'User-Agent'     } = $_USERAGENT;
	   $headers{'Cookie'         } = $_cookie if $_cookie;
	   $headers{'Referer'        } = $_last_url;
	   $headers{'Accept-Language'} = 'en-US;q=0.8,en;q=0.7';  # OpenID sign-in requirement
	
	$_last_url = $url;
	
	my $resp = HTTP::Tiny
			->new( timeout => 20 )
			->post_form( $url, $rh_fields, { headers => \%headers });
	
	_updcookie( $resp->{headers}->{'set-cookie'} )   # Security tokens, session ids etc
		if $resp->{headers}->{'set-cookie'};
	
	# HTTP::Tiny does auto-redirect for GET and HEAD only
	# so we have to do it manually here:
	return _html( $resp->{headers}->{location}, $_ENO_WARN, 0 )
		if $resp->{status} == 302;  # Goodreads all temporary redirs on POST
	
	return $resp->{content};
}




1;
__END__


