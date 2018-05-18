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

=item * Updated: 2018-05-15

=item * Since: 2014-11-05

=back

=cut

our $VERSION = '1.60';  # X.XX version format required by Perl


=head1 KNOWN LIMITATIONS AND BUGS

=over

=item * slow: version with concurrent AnyEvent::HTTP requests was marginally 
        faster, so I sticked with simpler code; but might be up to my system

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
		query_good_reviews
		query_good_followees );


use WWW::Curl::Easy;
use Cache::Cache qw( $EXPIRES_NEVER $EXPIRES_NOW );
use Cache::FileCache;
use Time::Piece;  # Core module, no extra install


our $_useragent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13';
our $_cookie    = undef;
our $_cache     = new Cache::FileCache();
our $_cache_age = $EXPIRES_NOW;  # see set_good_cache()



=head1 DATA STRUCTURES

=head2 Note

=over

=item * never cast 'id' to int or use %d format string, despite digits only

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

=back


=head2 %user

=over

=item * id          => C<string>

=item * name        => C<string>

=item * age         => C<int>

=item * is_friend   => C<bool>

=item * is_author   => C<bool>

=item * is_female   => C<bool>

=item * profile_url => C<string>

=item * img_url     => C<string>

=back


=head2 %review

=over

=item * id         => C<string>

=item * user       => C<L<%user|"%user">>

=item * book_id    => C<string>

=item * rating     => C<int>

=item * rating_str => C<string> represention of rating, e.g., 3 as "***--"

=item * text       => C<string>

=item * date       => C<Time::Piece>

=item * review_url => C<string>

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




=head2 C<void> set_good_cookie_file( I<$path_to_cookie_file> )

=cut

sub set_good_cookie_file
{
	my $path = shift;
	local $/=undef;
	open my $fh, "<", $path or die
			"FATAL: Please save a Goodreads cookie to \"$path\". ".
			"Copy the cookie, for example, from Chrome's DevTools Network-view.";
	
	binmode $fh;
	set_good_cookie( <$fh> );
	close $fh;
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




=head2 C<string> good_shelf_url( I<$user_id, $shelf_name, $page_number> )

=head3 Notes on the URL

=over

=item * page with a list of books (not all books)

=item * "&per_page=100" has no effect (GR actually loads 5x 20 books via JavaScript)

=item * "&view=table" puts I<all> book data in code, although invisible (display=none)

=item * "&sort=rating" is important for `friendrated.pl` with its book limit:
        Some users read 9000+ books and scraping would take forever. 
        We sort lower-rated books to the end and just scrape the first pages:
        Even those with 9000+ books haven't top-rated more than 2700 books.

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub good_shelf_url  
{
	my $uid   = shift;
	my $shelf = shift;
	my $page  = shift;
	return "https://www.goodreads.com/review/list/${uid}?shelf=${shelf}&page=${page}&view=table&sort=rating&order=d";
}




=head2 C<string> good_following_url( I<$user_id, $page_number> )

=head3 Notes on the URL

=over

=item * page with a list of the people $user is following

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub good_following_url
{
	my $uid  = shift;
	my $page = shift;
	return "https://www.goodreads.com/user/${uid}/following?page=${page}";
}




=head2 C<string> good_friends_url( I<$user_id, $page_number> )

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

sub good_friends_url
{
	my $uid  = shift;
	my $page = shift;
	return "https://www.goodreads.com/friend/user/${uid}?page=${page}&skip_mutual_friends=false&sort=date_added";
}




=head2 C<string> good_book_url( I<L<%book|"%book">> )

=over

=item * Requires at least {id=>string}

=back

=cut

sub good_book_url
{
	my $book = shift;
	return 'https://www.goodreads.com/book/show/' . $book->{id};
}




=head2 C<string> good_user_url( I<$user_id, $is_author = 0> )

=cut

sub good_user_url
{
	my $uid    = shift;
	my $is_aut = shift || 0;
	return 'https://www.goodreads.com/'.( $is_aut ? 'author' : 'user' )."/show/${uid}";
}




=head2 C<string> good_reviews_url( I<$book_id> )

=cut

sub good_reviews_url
{
	my $bid = shift;
	return "https://www.goodreads.com/book/reviews/${bid}?sort=newest";
}




=head2 C<string> good_review_url( I<$review_id> )

=cut

sub good_review_url
{
	my $rid = shift;
	return "https://www.goodreads.com/review/show/${rid}";
}




=head2 C<string> amz_url( I<L<%book|"%book">> )

=over

=item * Requires at least {isbn=>string}

=back

=cut

sub amz_url
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
	return _html( amz_url( shift ) );
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
		
		# Count occurances; dont match "staticStars" (trailing s) or "staticStar p0"
		my $urat = () = $row =~ /staticStar p10/g;
		
		# Extract title
		# + Remove HTML in "Title <span style="...">(Volume 35)</span>"
		# + Reduce "   " to " " and remove line breaks
		my $tit  = $1 if $row =~ /<label>title<\/label><div class="value">\s*<a[^>]+>\s*(.*?)\s*<\/a>/s;
		   $tit  =~ s/\<[^\>]+\>//g;
		   $tit  =~ s/( {1,}|[\r\n])/ /g;  
		
		push @result, { 
				id          => $id, 
				title       => $tit, 
				isbn        => $isbn, 
				num_ratings => $numr, 
				user_rating => $urat, 
				url         => good_book_url({ id => $id }),
				img_url     => $img };
	}
	return @result;
}




=head2 C<(L<%user|"%user">,...)> _extract_following( I<$following_page_html_str> )

=cut

sub _extract_following
{
	my $html = shift;
	my @result;
	while( $html =~ /<div class='followingItem elementList'>(.*?)<\/a>/gs )
	{
		my $row = $1;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $aid = $1 if $row =~ /\/author\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /img alt="([^"]+)/;
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		push @result, { 
				id          => $id, 
				name        => $nam, 
				profile_url => good_user_url( $id, $aid ),
				img_url     => $img,
				age         => undef,
				is_author   => $aid, 
				is_female   => undef,
				is_friend   => 0 };
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
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		push @result, { 
				id          => $id, 
				name        => $nam, 
				profile_url => good_user_url( $id, $aid ),
				img_url     => $img, 
				age         => undef,
				is_author   => $aid, 
				is_female   => undef,
				is_friend   => 1 };
	}
	return @result;
}




=head2 C<(L<%review|"%review">,...)> _extract_reviews( I<$reviews_xhr_html_str> )

=cut

sub _extract_reviews
{
	my $html = shift;  # < is \u003c, > is \u003e,  " is \" literally
	my @result;
	while( $html =~ /div id=\\"review_\d+(.*?)div class=\\"clear/gs )
	{
		my $row = $1;
		my $rid = $1 if $row =~ /\/review\/show\/([0-9]+)/;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /alt=\\"([^\\]+)/;   # alt=\"David T\"
		my $rat = () =  $row =~ /staticStar p10/g;   # count occurances
		my $dat = $1 if $row =~ /([A-Z][a-z][a-z] \d+, \d{4})/;
		
		push @result, {
				id   => $rid,
				user => { 
					id          => $uid, 
					name        => $nam, 
					profile_url => good_user_url( $uid ),
					img_url     => undef,  # TODO
					age         => undef,
					is_author   => undef,
					is_female   => undef,
					is_friend   => undef
				},
				rating     => $rat,
				rating_str => '*' x $rat . '-' x (5-$rat),  # ***--  Or stars \x{2605} and \x{2606}?
				review_url => good_review_url( $rid ),
				text       => undef,  # TODO
				date       => Time::Piece->strptime( $dat, '%b %d, %Y' ),
				book_id    => undef };
	}
	return @result;
}




=head2 C<string> _html( I<$url> )

=over

=item * HTML body of a web document

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
	$curl->setopt( $curl->CURLOPT_USERAGENT,      $_useragent );
	$curl->setopt( $curl->CURLOPT_HEADER,         0     );
	$curl->setopt( $curl->CURLOPT_WRITEDATA,      \$buf );
	$curl->setopt( $curl->CURLOPT_HTTPGET,        1     );
	$curl->setopt( $curl->CURLOPT_FOLLOWLOCATION, 1     );
	$curl->setopt( $curl->CURLOPT_COOKIE,         $_cookie ) if $_cookie;
	
	my $curl_ret = $curl->perform;
	$result      = $buf;
	
	die "FATAL: $curl_ret " 
	          . $curl->strerror( $curl_ret ) . " " 
	          . $curl->errbuf
		unless $curl_ret == 0;
	
	$_cache->set( $url, $result, $_cache_age );
	
	return $result;
}




=head2 C<(L<%book|"%book">,...)> query_good_books( I<$user_id, $shelf_name, $max_books = 2700> )

=cut

sub query_good_books
{
	my $uid       = shift;
	my $shelf     = shift;
	my $max_books = shift || 2700;  # TODO
	my $page      = 1; 
	my @books;
	
	@books = (@books, @_) while( @_ = _extract_books( _html( good_shelf_url( $uid, $shelf, $page++ ) ) ) );
	return @books;
}




=head2 C<(L<%review|"%review">,...)> query_good_reviews( I<$book_id, $since_time_piece> )

=over

=item * latest reviews first

=back

=cut

sub query_good_reviews
{
	my $bid        = shift;
	my $since      = shift;
	my $since_date = Time::Piece->strptime( $since->ymd, '%Y-%m-%d' );  # Nullified time in GR too
	my @revs       = _extract_reviews( _html( good_reviews_url( $bid ) ) );
	my @sel        = grep $_->{date} >= $since_date, @revs;
	return @sel;
}




=head2 C<(id =E<gt> L<%user|"%user">,...)> query_good_followees( I<$user_id> )

=over

=item * Precondition: set_good_cookie()

=item * returns friends and followees

=back

=cut

sub query_good_followees
{
	my $uid  = shift;
	my %result;
	my $page;

	$page = 1;
	while( my @somef = _extract_following( _html( good_following_url( $uid, $page++ ) ) ) )
	{
		$result{$_->{id}} = $_ foreach (@somef)
	}
	
	$page = 1;
	while( my @somef = _extract_friends( _html( good_friends_url( $uid, $page++ ) ) ) )
	{
		$result{$_->{id}} = $_ foreach (@somef)
	}
	
	return %result;
}


1;
__END__


