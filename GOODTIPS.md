# Tips

## Table of Contents
- [Things That Improved My Goodreads.com Experience](#things-that-improved-my-goodreadscom-experience)
- [Discovering Non-Fiction Books](#discovering-non-fiction-books)
- [Feedback](#feedback)


## Things That Improved My Goodreads.com Experience

- **Grouping shelves** with a prefix, e.g., _"region-usa"_,
  _"region-..."_. Goodreads sorts shelf lists in alphabetical order (non-mobile version).
  Related but scattered shelves impair findability.  
  - I moved shelves that are useful to me alone to the _end_ of the list by prefixing them with Unicode 0x3161: ㅡ
  - pseudo sub-shelves in Goodreads: _"parent-child"_

- **Creating a "more-urgent" shelf** from unread books

- **Creating an "abandoned" shelf** to compensate the missing reading-status. 
  Have the exclusive-checkbox [activated](https://www.goodreads.com/shelf/edit)

- **Tracking physical book location** with shelves such as _"shelf-kitchen"_ or 
  _"shelf-berlin"_ if the amount of books exceeds memory (Future me)

- **Limiting the number of shelves** to max. 1 page. 
  Coarse-grained better than fine-grained, easier to navigate.
  Anemic shelves also render functions such as "select multiple" (intersection) useless.
  - avoid shelves that will likely never contain more than 3 books
  - merge strongly overlapping shelves, e.g., _"politics-economy-history"_ or _"software-testing-infosec"_

- **Adding unread books to my custom shelves too.** This works
  well with Goodreads own _"select multiple"_ feature beneath your
  shelf list: Pick your next book by intersection, e.g., _"to-read" +
  "non-fiction" + "lang-de"_. 
  It's clearer than having hundreds of books in _"unread"_ over time,
  and helps others discovering new books more easily.
  
- **Decluttering my library** with cardboxes and GR-shelves labeled
  _"donations"_ and _"resales"_. My city library took 30 books
  after receiving a link to my donations shelf.  Such link may also appear in
  your email signature: "I give away books: ...". 
  PS: There is a "book condition" column (shelf settings: table view, [x] condition).

- **Batch edit** shelf feature

- **Becoming a Goodreads librarian** by applying 
  [there](https://www.goodreads.com/about/apply_librarian). Quickly
  edit wrong or missing book/author info and add cover images by yourself,
  combine stray book editions (take over reviews etc.)

- [Goodreads Ratings for Amazon](https://chrome.google.com/webstore/detail/goodreads-ratings-for-ama/fkkcefhhadenobhjnngfdahhlodolkjg) – a Chrome-browser extension by Rubén Martínez; 
  also reminds you of GR reviews when you're shopping on Amazon 

- **Checking out users who rate good books**. 
  [This service](https://andre-st.github.io/goodreads/) notifies you of new ratings for specific books.
  Be picky, don't submit your whole _"read"_ shelf.

- **Resetting the quasi-random view-settings** when browsing (other people's)
  shelves by rewriting Goodreads URLs via Einar Egilsson's 
  [Redirector](https://chrome.google.com/webstore/detail/redirector/ocgpenflpmgnfapjedencafcfakcekcd)
  Chrome browser extension: 
  ```
  Descrpt: Goodreads Shelves
  Pattern: (https://www\.goodreads\.com/review/list/[^?]+)(?=(?:.*[?&](page=\d+))?)(?=(?:.*[?&](shelf=[^&]+))?)
  RedirTo: $1?per_page=100&sort=rating&order=d&view=covers&$2&$3
  ```
  Always "100 books per page, sort by user-ratings with the highest first, covers-view". 
  The expression takes inexact matches like "page" ∈ "per_page", randomly ordered or missing 
  parameters and Unicode values into account.
  
## Discovering Non-Fiction Books
- checkout the bibliography section of a good book (best signal-to-noise ratio); I use a separate _"bibliogr-to-check"_ Goodreads shelf to keep track of unchecked books
- notice books mentioned in the _footnotes_ section of Wikipedia articles
- notice books mentioned in magazine articles
- notice names dropped in magazine articles and check them against Amazon
- scan interesting websites/blogs for books 
  - internal search or google `site:goodblog.com book`
  - [HackerNewsBooks.com](https://hackernewsbooks.com/)
  - [top books on Reddit](http://booksreddit.com/)
  - [RedditFavorites.com](https://redditfavorites.com/books)
- search [books.google.com](https://www.google.com/search?tbm=bks&q=specific+interest) for "specific interest"
- [Google Alerts](https://www.google.com/alerts): "new book" + "specific interest"
- follow [Goodreads users](https://www.goodreads.com/user/18418712-andr/following) with interesting libraries
- inspect Goodreads books [common among members you follow](https://github.com/andre-st/goodreads/blob/master/friendrated.md)
- follow small or specialized publishers through a [Twitter list](https://twitter.com/voidyll/lists/books), RSS-feed or newsletter (works so lala)
- reddit, quora, ...
- the better book sites:
  - [NewBooksNetwork.com](http://newbooksnetwork.com/)
- recommendation engines hardly work for me: Goodreads never, Amazon sometimes
- [Bookstragram](https://www.instagram.com/explore/tags/bookstagram/) does not work for me
- [BookTube](https://en.wikipedia.org/wiki/BookTube) does not work for me, girls club
- common bestseller lists do not work for me
- Parakweet's BookVibe closed in 2016, they sent you a list of books that your friends are talking about on Twitter
- ...
- rules of thumb:
  - get your keywords right: you have to already know the technical terms/categories you like to learn about
  - despite notable [exceptions](https://www.goodreads.com/user/show/2531665-charlene), 90% female book-community accounts offer either fiction only or shallow non-fiction
- bookmark interesting titles now and inspect them later, books must arouse interest also after one month; I use multiple Amazon wishlists (also shows current 2nd hand prices, my comments and priorization), I have a separate "(lost interest)" wishlist as an alternative to deletion
- evaluate:
  - author and publisher (other titles - loonies?)
  - audience/pre-requirements
  - time of writing
  - context/purpose/goal
  - credibility in the field
  - sources in footnotes/bibliography or unsupported?


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file
