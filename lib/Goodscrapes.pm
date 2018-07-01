package Goodscrapes;
use strict;
use warnings;
use 5.18.0;
use utf8;

###############################################################################

=pod

=encoding utf8

=head1 NAME

Goodscrapes - Simple Goodreads.com scraping helpers


=head1 VERSION

=over

=item * Updated: 2018-06-27

=item * Since: 2014-11-05

=back

=cut

our $VERSION = '1.74';  # X.XX version format required by Perl


=head1 COMPARED TO THE OFFICIAL API

=over

=item * less limited, e.g., reading shelves and reviews of other members

=item * official API is slow too; API users are even second-class citizen

=item * theoretically this library is more likely to break, 
        but Goodreads progresses very very slowly: nothing
        actually broke since 2014 (I started this);
        actually their API seems to change more often than
        their web pages; they can and do disable API functions 
        without being noticed by the majority, but they cannot
        easily disable important webpages that we use too

=back


=head1 KNOWN LIMITATIONS AND BUGS

=over

=item * slow: version with concurrent AnyEvent::HTTP requests was marginally 
        faster, so I sticked with simpler code; doesn't actually matter
        due to Amazon's and Goodreads' request throttling. You can only
        speed things up significantly with a pool of work-sharing computers 
        and unique IP addresses...

=item * just text pattern matching, no ECMAScript execution and DOM parsing
        (so far sufficient and faster)

=back


=head1 AUTHOR

https://github.com/andre-st/


=cut

###############################################################################


use base 'Exporter';
our @EXPORT = qw( 
		set_good_cookie 
		set_good_cookie_file 
		set_good_cache 
		amz_book_html 
		query_good_books 
		query_good_user
		query_good_author_books
		query_good_reviews
		query_good_followees );


use HTML::Entities;
use WWW::Curl::Easy;
use Cache::Cache qw( $EXPIRES_NEVER $EXPIRES_NOW );
use Cache::FileCache;
use Time::Piece;  # Core module, no extra install


our $USERAGENT  = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13';
our $COOKIEPATH = '.cookie';
our $_cookie    = undef;
our $_cache     = new Cache::FileCache();
our $_cache_age = $EXPIRES_NOW;  # see set_good_cache()



=head1 DATA STRUCTURES

=head2 Note

=over

=item * never cast 'id' to int or use %d format string, despite digits only

=item * don't expect all attributes set (C<undef>), this depends on context

=back


=head2 %book

=over

=item * id          => C<string>

=item * title       => C<string>

=item * isbn        => C<string>

=item * num_ratings => C<int>

=item * user_rating => C<int>

=item * url         => C<string>

=item * img_url     => C<string>

=item * author      => C<L<%user|"%user">>

=back


=head2 %user

=over

=item * id         => C<string>

=item * name       => C<string>

=item * age        => C<int>

=item * is_friend  => C<bool>

=item * is_author  => C<bool>

=item * is_female  => C<bool> (not supported yet)

=item * is_private => C<bool>

=item * url        => C<string> URL to the user's profile page

=item * img_url    => C<string>

=back


=head2 %review

=over

=item * id          => C<string>

=item * user        => C<L<%user|"%user">>

=item * book_id     => C<string>

=item * rating      => C<int> 
                       with 0 meaning no rating, "added" or "marked it as abandoned" 
                       or something similar

=item * rating_str  => C<string> 
                       represention of rating, e.g., 3/5 as S<"[***  ]"> or S<"[TTT  ]"> 
                       if there's additional text

=item * text        => C<string>

=item * date        => C<Time::Piece>

=item * review_url  => C<string>

=back

=cut




=head1 SUBROUTINES



=head2 C<void> set_good_cookie( I<$cookie_content_str> )

=over

=item * some Goodreads.com pages are only accessible by authenticated members

=item * copy-paste cookie from Chrome's DevTools network-view

=back

=cut

sub set_good_cookie
{
	$_cookie = shift;
}




=head2 C<void> set_good_cookie_file( I<$path_to_cookie_file = '.cookie'> )

=cut

sub set_good_cookie_file
{
	my $path = shift || $COOKIEPATH;
	local $/=undef;
	open my $fh, "<", $path or die
			"[FATAL] Please save a Goodreads cookie to \"$path\". ".
			"Copy the cookie, for example, from Chrome's DevTools Network-view: ".
			"https://www.youtube.com/watch?v=o_CYdZBPDCg";
	
	binmode $fh;
	set_good_cookie( <$fh> );
	close $fh;
}




=head2 C<bool> test_good_cookie()

=over

=item * not supported at the moment

=back

=cut

sub test_good_cookie()
{
	# TODO: check against a page that needs sign-in
	# TODO: call in set_good_cookie() or by the lib-user separately?
	
	say STDERR "[WARN] Not yet implemented: test_good_cookie()";
	return 1;
}




=head2 C<void> set_good_cache( I<$maximum_age_in_words> )

=over

=item * scraping Goodreads.com is a very slow process

=item * scraped documents can be cached if you don't need them "fresh"

=item * e.g., during development time

=item * e.g., during long running sessions (cheap recovery on crash or pause)

=item * pass something like C<"60 minutes">, C<"6 hours">, C<"6 days">

=back

=cut

sub set_good_cache
{
	$_cache_age = shift;
}




=head2 C<string> _shelf_url( I<$user_id, $shelf_name, $page_number> )

=head3 Notes on the URL

=over

=item * page with a list of books (not all books)

=item * "&per_page=100" has no effect (GR actually loads 5x 20 books via JavaScript)

=item * "&print=true" not included, any advantages?

=item * "&view=table" puts I<all> book data in code, although invisible (display=none)

=item * "&sort=rating" is important for `friendrated.pl` with its book limit:
        Some users read 9000+ books and scraping would take forever. 
        We sort lower-rated books to the end and just scrape the first pages:
        Even those with 9000+ books haven't top-rated more than 2700 books.

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _shelf_url  
{
	my $uid   = shift;
	my $shelf = shift;
	my $page  = shift;
	return "https://www.goodreads.com/review/list/${uid}?shelf=${shelf}&page=${page}&view=table&sort=rating&order=d";
}




=head2 C<string> _followees_url( I<$user_id, $page_number> )

=head3 Notes on the URL

=over

=item * page with a list of the people $user is following

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _followees_url
{
	my $uid  = shift;
	my $page = shift;
	return "https://www.goodreads.com/user/${uid}/following?page=${page}";
}




=head2 C<string> _friends_url( I<$user_id, $page_number> )

=head3 Notes on the URL

=over

=item * page with a list of people befriended to C<$user_id>

=item * "&sort=date_added" (as opposed to 'last online') avoids 
        moving targets while reading page by page

=item * "&skip_mutual_friends=false" because we're not doing
        this just for me

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _friends_url
{
	my $uid  = shift;
	my $page = shift;
	return "https://www.goodreads.com/friend/user/${uid}?page=${page}&skip_mutual_friends=false&sort=date_added";
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
	my $uid    = shift;
	my $is_aut = shift || 0;
	return 'https://www.goodreads.com/'.( $is_aut ? 'author' : 'user' )."/show/${uid}";
}




=head2 C<string> _reviews_url( I<$book_id, $can_sort_newest, $page_number> )

=over

=item * "&sort=newest" reduces the number of reviews for some reason (also observable 
        on the Goodreads website), so only use if really needed (&sort=default)

=item * the maximum of retrievable reviews is 300 (state 2018-06-22)

=back

=cut

sub _reviews_url
{
	my $bid  = shift;
	my $sort = shift;
	my $page = shift;
	return "https://www.goodreads.com/book/reviews/${bid}?".( $sort ? 'sort=newest&' : '' )."page=${page}";
}




=head2 C<string> _review_url( I<$review_id> )

=cut

sub _review_url
{
	my $rid = shift;
	return "https://www.goodreads.com/review/show/${rid}";
}




=head2 C<string> _author_books_url( I<$user_id, $page_number> )

=cut

sub _author_books_url
{
	my $uid  = shift;
	my $page = shift;
	return "https://www.goodreads.com/author/list/${uid}?per_page=100&page=${page}";
}




=head2 C<string> _amz_url( I<L<%book|"%book">> )

=over

=item * Requires at least {isbn=>string}

=back

=cut

sub _amz_url
{
	my $book = shift;
	return $book->{isbn} ? 'http://www.amazon.de/gp/product/' . $book->{isbn} : undef;
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




=head2 C<(L<%book|"%book">,...)> _extract_books( I<$shelf_tableview_html_str> )

=cut

sub _extract_books
{
	my $html = shift;
	my @result;
	while( $html =~ /<tr id="review_\d+" class="bookalike review">(.*?)<\/tr>/gs ) # each book row
	{	
		my $row  = $1;
		my $id   = $1 if $row =~ /data-resource-id="([0-9]+)"/;
		my $isbn = $1 if $row =~ /<label>isbn<\/label><div class="value">\s*([0-9X\-]*)/;
		my $numr = $1 if $row =~ /<label>num ratings<\/label><div class="value">\s*([0-9]+)/;
		my $img  = $1 if $row =~ /<img [^>]* src="([^"]+)"/;
		my $auid = $1 if $row =~ /author\/show\/([0-9]+)/;
		my $aunm = $1 if $row =~ /author\/show\/[^>]+>([^<]+)/;
		   $aunm = decode_entities( $aunm );
		
		# Count occurances; dont match "staticStars" (trailing s) or "staticStar p0"
		my $urat = () = $row =~ /staticStar p10/g;
		
		# Extract title
		# + Remove HTML in "Title <span style="...">(Volume 35)</span>"
		# + Reduce "   " to " " and remove line breaks
		# + Replace &quot; etc with " etc
		my $tit  = $1 if $row =~ /<label>title<\/label><div class="value">\s*<a[^>]+>\s*(.*?)\s*<\/a>/s;
		   $tit  =~ s/\<[^\>]+\>//g;
		   $tit  =~ s/( {1,}|[\r\n])/ /g;  
		   $tit  = decode_entities( $tit );
		
		push @result, { 
				id          => $id, 
				title       => $tit, 
				isbn        => $isbn, 
				author      => { 
					id         => $auid,
					name       => $aunm,
					url        => _user_url( $auid, 1 ),
					img_url    => undef,
					is_autor   => 1,
					is_private => 0,
					is_female  => undef,
					is_friend  => undef
				},
				num_ratings => $numr, 
				user_rating => $urat, 
				url         => _book_url( $id ),
				img_url     => $img };
	}
	return @result;
}




=head2 C<(L<%book|"%book">,...)> _extract_author_books( I<$html_str> )

=cut

sub _extract_author_books
{
	my $html  = shift;
	my $auimg = $1 if $html =~ /(https:\/\/images.gr-assets.com\/authors\/.*?\.jpg)/gs;
	   $auimg = 'https://s.gr-assets.com/assets/nophoto/user/u_50x66-632230dc9882b4352d753eedf9396530.png' if !$auimg;
	my $auid  = $1 if $html =~ /author\/show\/([0-9]+)/;
	my $aunm  = $1 if $html =~ /<h1>Books by ([^<]+)/;
	   $aunm  = decode_entities( $aunm );
	
	my @result;
	while( $html =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row  = $1;
		my $id   = $1 if $row =~ /book\/show\/([0-9]+)/;
		my $tit  = $1 if $row =~ /<span itemprop='name'>([^<]+)/;
		my $img  = $1 if $row =~ /src="[^"]+/;
		
		push @result, {
			id          => $id,
			title       => decode_entities( $tit ),
			isbn        => undef,
			author      => {
				id         => $auid,
				name       => $aunm,
				url        => _user_url( $auid, 1 ),
				img_url    => $auimg,
				is_author  => 1,
				is_private => 0,
				is_female  => undef,
				is_friend  => undef
			},
			num_ratings => undef,
			user_rating => undef,
			url         => _book_url( $id ),
			img_url     => $img }
	}
	return @result;
}




=head2 C<(L<%user|"%user">,...)> _extract_followees( I<$following_page_html_str> )

=cut

sub _extract_followees
{
	my $html = shift;
	my @result;
	while( $html =~ /<div class='followingItem elementList'>(.*?)<\/a>/gs )
	{
		my $row = $1;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $aid = $1 if $row =~ /\/author\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /img alt="([^"]+)/;
		   $nam = decode_entities( $nam );
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		
		push @result, { 
				id         => $id, 
				name       => $nam, 
				url        => _user_url( $id, $aid ),
				img_url    => $img,
				age        => undef,
				is_author  => $aid, 
				is_private => undef,
				is_female  => undef,
				is_friend  => 0 };
	}
	return @result;
}




=head2 C<(L<%user|"%user">,...)> _extract_friends( I<$friends_page_html_str> )

=cut

sub _extract_friends
{
	my $html = shift;
	my @result;
	while( $html =~ /<tr>\s*<td width="1%">(.*?)<\/td>/gs )
	{
		my $row = $1;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $aid = $1 if $row =~ /\/author\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /img alt="([^"]+)/;
		   $nam = decode_entities( $nam );
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		
		push @result, { 
				id         => $id, 
				name       => $nam, 
				url        => _user_url( $id, $aid ),
				img_url    => $img, 
				age        => undef,
				is_author  => $aid, 
				is_private => undef,
				is_female  => undef,
				is_friend  => 1 };
	}
	return @result;
}




=head2 C<(L<%review|"%review">,...)> _extract_reviews( I<$since_time_piece, $reviews_xhr_html_str> )

=cut

sub _extract_reviews
{
	my $since_tpiece = shift;
	my $html         = shift;  # < is \u003c, > is \u003e,  " is \" literally
	my $bid          = $1 if $html =~ /%2Fbook%2Fshow%2F([0-9]+)/;
	
	my @result;
	while( $html =~ /div id=\\"review_\d+(.*?)div class=\\"clear/gs )
	{		
		my $row = $1;
		my $rid = $1 if $row =~ /\/review\/show\/([0-9]+)/;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		
		# img alt=\"David T\"   
		# img alt=\"0\"
		# img alt="\u0026quot;Greg Adkins\u0026quot;\"
		my $nam = $1 if $row =~ /img alt=\\"(.*?)\\"/;   
		   $nam = '"0"' if $nam eq '0';              # Avoid eval to false somewhere
		   $nam = decode_entities( $nam );
		   
		my $rat = () =  $row =~ /staticStar p10/g;   # count occurances
		my $dat = $1 if $row =~ /([A-Z][a-z][a-z] \d+, \d{4})/;
		my $txt = $1 if $row =~ /id=\\"freeTextContainer[^"]+"\\u003e(.*?)\\u003c\/span/;
		   $txt = $txt ? decode_entities( $txt ) : '';  # I expected rather '' than undef, so...
		
		my $dat_tpiece = Time::Piece->strptime( $dat, '%b %d, %Y' );
		
		next if $dat_tpiece < $since_tpiece;
		
		push @result, {
				id   => $rid,
				user => { 
					id         => $uid, 
					name       => $nam, 
					url        => _user_url( $uid ),
					img_url    => undef,  # TODO
					age        => undef,
					is_author  => undef,
					is_private => undef,
					is_female  => undef,
					is_friend  => undef
				},
				rating     => $rat,
				rating_str => $rat ? ('[' . ($txt ? 'T' : '*') x $rat . ' ' x (5-$rat) . ']') : '[added]',
				review_url => _review_url( $rid ),
				text       => $txt,
				date       => $dat_tpiece,
				book_id    => $bid };
	}
	return @result;
}




=head2 C<bool> _check_page( I<$url, $html> )

=over

=item * sign-in page (https://www.goodreads.com/user/sign_in) or in-page message: warn and continue

=item * page unavailable, Goodreads request took too long: warn and continue

=item * page unavailable, An unexpected error occurred. We will investigate this problem as soon 
        as possible — please check back soon!: scraping process dies as this will show up for subsequent URLs too

=item * page not found: warn and continue

=item * over capacity: scraping process dies

=item * maintenance mode: scraping process dies

=cut

sub _check_page
{
	my $url  = shift;
	my $html = shift;
	
	# Try to be precise, don't stop just because someone wrote a pattern 
	# in his review or a book title. Characters such as < and > are 
	# encoded in user texts:
	
	
	say STDERR "[WARN] Sign-in for $url => Cookie invalid or not set: set_good_cookie_file()"
		and return 0
			if $html =~ /<head>\s*<title>\s*Sign in\s*<\/title>/s;
	
	
	say STDERR "[WARN] Not found: $url"
		and return 0
			if $html =~ /<head>\s*<title>\s*Page not found\s*<\/title>/s;
	
	
	die "[FATAL] Goodreads encountered an unexpected error. Continue later to ensure data quality."
		if $html =~ /<head>\s*<title>\s*Goodreads - unexpected error\s*<\/title>/s;
	
	
	# "<?>Goodreads is over capacity.</?> 
	#  <?>You can never have too many books, but Goodreads can sometimes
	#  have too many visitors. Don't worry! We are working to increase 
	#  our capacity.</?>
	#  <?>Please reload the page to try again.</?>
	#  <a ...>get the latest on Twitter</a>"
	#  https://pbs.twimg.com/media/DejvR6dUwAActHc.jpg
	#  https://pbs.twimg.com/media/CwMBEJAUIAA2bln.jpg
	#  https://pbs.twimg.com/media/CFOw6YGWgAA1H9G.png  (with title)
	#  
	# TODO Pattern best guess from Screenshot and the other examples
	# 
	die "[FATAL] Goodreads is over capacity. Continue later to ensure data quality."
		if $html =~ /<head>\s*<title>\s*Goodreads is over capacity\s*<\/title>/s;

	
	# "<?>Goodreads is down for maintenance.</?>
	#  <?>We expect to be back within minutes. Please try again soon!<?>
	#  <a ...>Get the latest on Twitter</a>"
	#  https://pbs.twimg.com/media/DgKMR6qXUAAIBMm.jpg
	#  https://i.redditmedia.com/-Fv-2QQx2DeXRzFBRKmTof7pwP0ZddmEzpRnQU1p9YI.png
	#  
	# TODO Pattern best guess given the other examples
	# 
	die "[FATAL] Goodreads is down for maintenance. Continue later."
		if $html =~ /<head>\s*<title>\s*Goodreads is down for maintenance\s*<\/title>/s;
	
	
	return 1;  # Allow caching etc
}




=head2 C<string> _html( I<$url> )

=over

=item * HTML body of a web document

=item * might stop process on severe problems

=back

=cut

sub _html
{
	my $url  = shift or return '';
	my $curl = WWW::Curl::Easy->new;
	my $buf;
	my $result;
	
	$result = $_cache->get( $url );
	return $result if defined $result;
	
	$curl->setopt( $curl->CURLOPT_URL,            $url  );
	$curl->setopt( $curl->CURLOPT_REFERER,        $url  );  # https://www.goodreads.com/...  [F5]
	$curl->setopt( $curl->CURLOPT_USERAGENT,      $USERAGENT );
	$curl->setopt( $curl->CURLOPT_HEADER,         0     );
	$curl->setopt( $curl->CURLOPT_WRITEDATA,      \$buf );
	$curl->setopt( $curl->CURLOPT_HTTPGET,        1     );
	$curl->setopt( $curl->CURLOPT_FOLLOWLOCATION, 1     );
	$curl->setopt( $curl->CURLOPT_COOKIE,         $_cookie ) if $_cookie;
	
	my $curl_ret = $curl->perform;
	$result      = $buf;
	
	die "[FATAL] $curl_ret " 
	           . $curl->strerror( $curl_ret ) . " " 
	           . $curl->errbuf
		unless $curl_ret == 0;
		
	# Don't cache error pages for the URL, but don't stop, though
	$_cache->set( $url, $result, $_cache_age ) if _check_page( $url, $result );
	
	return $result;
}




=head2 C<(L<%book|"%book">,...)> query_good_books( I<$user_id, $shelf_name> )

=cut

sub query_good_books
{
	my $uid       = shift;
	my $shelf     = shift;
	my $page      = 1; 
	my $max_books = 2700;   # TODO
	my @books;
	
	@books = (@books, @_) 
		while( @_ = _extract_books( _html( _shelf_url( $uid, $shelf, $page++ ) ) ) );
	
	return @books;
}




=head2 C<(L<%book|"%book">,...)> query_good_author_books( I<$user_id> )

=cut

sub query_good_author_books
{
	my $uid  = shift;
	my $page = 1;
	my @books;
	
	@books = (@books, @_)
		while( @_ = _extract_author_books( _html( _author_books_url( $uid, $page++ ) ) ) );
	
	return @books;
}




=head2 C<(L<%review|"%review">,...)> query_good_reviews( I<$book_id, $since_time_piece = undef> )

=over

=item * access seems less throttled / faster than querying books

=back

=cut

sub query_good_reviews
{
	my $bid        = shift;
	my $since      = shift;
	my $since_date = $since 
			? Time::Piece->strptime( $since->ymd,  '%Y-%m-%d' )  # Nullified time in GR too
			: Time::Piece->strptime( '1970-01-01', '%Y-%m-%d' ); 
	
	my $needs_sort = defined $since;
	my $page       = 1;
	my @revs;
	
	@revs = (@revs, @_) 
		while( @_ = _extract_reviews( $since_date, _html( _reviews_url( $bid, $needs_sort, $page++ ) ) ) );
	
	return @revs;
}




=head2 C<(id =E<gt> L<%user|"%user">,...)> query_good_followees( I<$user_id> )

=over

=item * Precondition: set_good_cookie()

=item * returns friends and followees

=back

=cut

sub query_good_followees
{
	my $uid = shift;
	my %result;
	my $page;

	$page = 1;
	while( my @somef = _extract_followees( _html( _followees_url( $uid, $page++ ) ) ) )
	{
		$result{$_->{id}} = $_ foreach (@somef)
	}
	
	$page = 1;
	while( my @somef = _extract_friends( _html( _friends_url( $uid, $page++ ) ) ) )
	{
		$result{$_->{id}} = $_ foreach (@somef)
	}
	
	return %result;
}






1;
__END__


