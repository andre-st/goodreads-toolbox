# recentrated.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Know when people rate or write reviews about a book

From the _Goodreads Feedback_ forum, 
[Scribble (2010)](https://www.goodreads.com/topic/show/440170-follow-user-reviews----follow-the-book)
or [Jimmy (2011)](https://www.goodreads.com/topic/show/563115-follow-a-book)
or [PetraX (2014)](https://www.goodreads.com/topic/show/2136206-following-books)
or [Lucas (2018)](https://www.goodreads.com/topic/show/19212816-follow-all-reviews-of-a-book)
or [Jason (2018)](https://www.goodreads.com/topic/show/19540183-subscribe-to-book-reviews-of-certain-books)
or [Elizabeth (2016):](https://www.goodreads.com/topic/show/18060629-follow-book)
> I know this has been requested before, but I'd really like the opportunity to
> follow a book. I'd like to know when people rate or write reviews about a
> book and to be notified of such. I have some favorites that are not
> particularly well known or often read, and I'd like to know about who chooses
> to read them. 


**Receive notification e-mails:**
```
From: yourmail@example.com
To: yourmail@example.com
Subject: New ratings on Goodreads.com
Date: Wed, 10 Jan 2018 21:10:50 +0100

Recently rated books in your "watch-ratings" shelf:

  "The Machine Question"
   www.goodreads.com/user/show/54336239   [*****]

  "Spam: A Shadow History of the Internet"
   www.goodreads.com/book/show/16718273   [9 new]

  "Understanding Beliefs"
   www.goodreads.com/review/show/22346637 [TTTT ]
   www.goodreads.com/user/show/24850532   [**   ]


--
 [***  ] 3/5 stars rating without text
 [TTT  ] 3/5 stars rating with some text
 [9 new] ratings better viewed on book page
 ...   
```
- low-bandwidth, distraction-free plaintext mail; HTML mail appeals to marketers because it's another place to stick their logo, nobody else needs it
- most mail-clients recognize the signature and the links and make the latter clickable
- changes are collected in periodic mails; individual mails would be annoying
- text-reviews in the mail are bloat, a click on a review-link is bearable - I would have checked the reviewer on the GR website anyway
- usernames in the mail are bloat - 99% are unknown/random letters to me and I would see it on the GR website anyway


## How to "follow books" 

### Installation-free:

1. visit [https://andre-st.github.io/goodreads/](https://andre-st.github.io/goodreads/) 
2. enter your e-mail and shelf address


### Dos and don'ts:

- don't use the "All" or "Read" shelves; be picky, use a separate single purpose shelf
- don't run this on more than one of your shelves; it's possible but better use a single purpose shelf
- don't use this program with well known fiction books that get a lot of reviews; 
  some books receive 300 ratings every day = no insights, readers too random
- create and [populate](http://i0.wp.com/theeverscholar.com/wp-content/uploads/2015/03/goodreads3.jpg) 
	a Goodreads shelf, e.g., "watch-ratings": You can add and remove books at any time. 
	New books will be checked automatically. 
	Such a shelf prevents unnecessary mails and eases manual checks if this system is discontinued someday


### Installation to a server:

1. open a GNU/Linux terminal and install the Goodreads Toolbox:
	```console
	$ git clone https://github.com/andre-st/goodreads.git
	$ cd goodreads
	$ sudo make     # Required Perl modules from CPAN etc.
	```
2. have a sendmail MTA set up (most simple thing is [ssmtp](https://wiki.debian.org/sSMTP)
   or [nullmailer](http://untroubled.org/nullmailer/)
   or [msmtp](http://msmtp.sourceforge.net), 
   with `/usr/sbin/sendmail` being symlinked to one of them), 
   configure default "From:"
   
3. add a cron-job (I prefer [anacrony](https://en.wikipedia.org/wiki/Anacron "performs pending jobs if the computer was previously shut down") daemons such as [dcron](https://github.com/dubiousjim/dcron) or [fcron](https://en.wikipedia.org/wiki/Fcron)):
	edit `/etc/cron.daily/goodratings` and replace ARGUMENTS:
	```sh
	#!/usr/bin/env sh
	# `ifne` is part of `moreutils`
	/path/to/recentrated.pl GOODUSERID SHELFNAME YOURMAIL@EXAMPLE.COM | ifne /usr/sbin/sendmail -t
	
	# Provide this self-hosted service to your Goodreads friends too!
	# ... HERUSERID HERSHELF HERMAIL@EXAMPLE.COM ADMIN@EXAMLE.COM | ...
	# ...
	```
	```sh
	$ sudo chmod +x /etc/cron.daily/goodratings
	```
	See also [cron.daily/goodratings.example](cron.daily/goodratings.example)


## Feedback

If you like this project, give it a star on GitHub.
Report bugs or suggestions [via GitHub](https://github.com/andre-st/goodreads/issues) 
or see the [AUTHORS.md](AUTHORS.md) file.


## See also

- [likeminded.pl](likeminded.md)   - Find Goodreads members with similar book taste
- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [similarauth.pl](similarauth.md) - Find all similar authors
- [search.pl](search.md)           - Sort books-search results by popularity or date published

