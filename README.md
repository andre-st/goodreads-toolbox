# :books: Andre's Goodreads Toolbox, v1.20

![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)

9 Perl-scripts for Goodreads.com—the world largest book (cataloging) community. [What's new?](CHANGELOG.md)


## [recentrated.pl](./doc/recentrated.md)

Checks all the books in your shelf for new ratings and notifies you
via periodical e-mail. It helps discover new criticisms and users with interesting 
libraries. You can [try this online](https://andre-st.github.io/goodreads/) if you 
don't want to install anything.
It implements the "follow book" feature that was requested in the Goodreads forums. 
[Learn more](./doc/recentrated.md)


## [friendrated.pl](./doc/friendrated.md)

Prints all books rated 4 or 5 stars by 3 or more persons you follow (including friends). 
It implements the "books common among the people I follow" feature that was requested 
in the Goodreads forums. It also lists the most read authors, the most wished-for 
and hated books.
[Learn more](./doc/friendrated.md)


## [friendnet.pl](./doc/friendnet.md)

Spiders your social network and creates files with edges and nodes which can be
easily processed with social network analysis software. It answers questions
like: Which members are popular among your friends?
[Learn more](./doc/friendnet.md)


## [friendgroup.pl](./doc/friendgroup.md)

Prints discussion groups common among the persons you follow (including friends).
Searching groups on Goodreads is a PITA, and sometimes you don't know what you can have 
and wouldn't search for it. [Learn more](./doc/friendgroup.md)


## [likeminded.pl](./doc/likeminded.md)

Prints Goodreads members who are interested in the same books as you.
It implements the "Finding people based on the books they've read"
feature that was requested in the Goodreads forums.
[Learn more](./doc/likeminded.md)


## [similarauth.pl](./doc/similarauth.md)

Prints authors who Goodreads thinks are similar to all the authors you're reading.
It implements the "Finding [all] similar authors" feature that was requested in the 
Goodreads forums.
[Learn more](./doc/similarauth.md)


## [search.pl](./doc/search.md)

Prints a books search result, ordered by average rating and number of ratings 
(most popular books), or date published, optionally with exact title matches. 
The Goodreads website doesn't offer it for some reason.
It implements the "Sort search results by rating" feature that was requested 
in the Goodreads forums.
[Learn more](./doc/search.md)


## [savreviews.pl](./doc/savreviews.md)

Saves text-reviews for a book to a text-file. It implements the "Extract all 
reviews for a specific book" feature that was requested in the Goodreads forums.
[Learn more](./doc/savreviews.md)


## ~~[amz-tradein.pl](./doc/amz-tradein.md)~~

This script fetched Amazon Trade-In prices for all books in a Goodreads.com
shelf ("resales" or "donations"). It automated regular manual bid-checking for 
hundreds of books, discovering sales opportunities. Amazon stopped its buyback 
program in 2015.
[Learn more](./doc/amz-tradein.md)


## www/

Static webpages that I use to offer [this software as a service](https://andre-st.github.io/goodreads/) 
to people who don't know Linux etc. 
You probably won't need this directory.
I'm not getting any money for this software or service, 
and I hope Goodreads will eventually make those scripts obsolete
by offering own solutions to the Goodreads community.



## Getting started

GNU/Linux terminal:
```console
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make             # Gets required Perl modules from CPAN (details see Makefile)
$ ./example-script.pl --help
$ ...
$ ...
$ sudo make uninstall   # Finally remove cache, logs etc from sys-dirs (see Makefile)
```

_Microsoft Windows_ is not officially supported.
A user wrote me that he ran the toolbox on the 
[Windows 10 Subsystem for Linux](https://linuxhint.com/install_ubuntu_windows_10_wsl/) (WSL).
Otherwise, resort to a virtual machine program such as [VirtualBox](https://www.virtualbox.org/) 
and run a [Linux image](https://www.osboxes.org/virtualbox-images/).


_The usual runtime_ of the programs will be long,
because Goodreads slows down all requests and we have to load a lot of data. 
You should start one program and do other things in the meantime.
You can break any program and continue later 
because it reuses already loaded data (file-cache).


_HTML-tables_ are the output-format of most of these programs, 
so you need a web-browser such as Firefox or Chrome
(or textmode web-browsers such as Lynx or Links) to view the results.



## Contributing

- Reporting bugs / Feature requests
  - add a new issue via [Github's issue tracker](https://github.com/andre-st/goodreads/issues/new)
  - [alternative contact options](AUTHORS.md)
  - thank you all who wrote me mails in the past or otherwise reported bugs and ideas :thumbsup:
- Writing your own scripts
  - see the [tests directory](./t/) for examples on how to use the toolbox library
  - see the [toolbox library documentation](./lib/Goodscrapes.pod)
  - user scripts should contain a man page, take the existing user scripts as an example
  - the [less complex issues](https://github.com/andre-st/goodreads/labels/beginner)
    would be good first issues to work on for users who want to contribute to this project



## Further readings

- About Goodreads
  - [GR developers group](https://www.goodreads.com/group/show/8095-goodreads-developers)
  - [GR technology stack](https://www.goodreads.com/jobs?id=597248#openPositions) or [here](https://www.glasswaves.co/selected_projects.txt) or [here](https://builtwith.com/goodreads.com) or [DynamoDB+S3+Athena](https://aws.amazon.com/blogs/big-data/how-goodreads-offloads-amazon-dynamodb-tables-to-amazon-s3-and-queries-them-using-amazon-athena/)
  - [GR workplace reviews](https://www.glassdoor.com/Reviews/Goodreads-Reviews-E684833.htm), anonymously about being acquired by Amazon, bureaucracy etc.
  - [GR on Crunchbase](https://www.crunchbase.com/organization/goodreads), people, recent news & activity 
  - [GR members stats](https://www.statista.com/search/?q=goodreads&qKat=search) or [here](https://qz.com/1106341/most-women-reading-self-help-books-are-getting-advice-from-men/) or [here](https://onlinelibrary.wiley.com/doi/abs/10.1002/asi.23733)+[Sci-Hub](https://twitter.com/scihub_love) or [here](https://book.pressbooks.com/chapter/goodreads-otis-chandler) – source probably [Goodreads](https://www.goodreads.com/about/us)
  - [GR on Slideshare](https://www.slideshare.net/GoodreadsPresentations/presentations), presenting GR book marketing to authors, see also [Author Feedback Group](https://www.goodreads.com/group/show/31471) 
  - [GR subreddit](https://www.reddit.com/r/goodreads/) with my [comments](https://redditcommentsearch.com/?query=goodreads&user=andre-st&go=true)
- Further software 
  - I leave statistics about your own reading habits to the following tools; my toolbox, in contrast, focuses on the social periphery, with Goodreads providing the largest user base
  - Paul Klinger's [Bookstats](https://github.com/PaulKlinger/Bookstats) or [here](https://almoturg.com/bookstats/)
  - untested: John Smith's [GoodreadsAnalysis](https://github.com/JohnSmithDev/GoodreadsAnalysis/blob/master/REPORTS.md)
  - untested: Petr's [CompareBooks](https://github.com/vatioz/GoodreadsUserCompare) browser [extension](https://chrome.google.com/webstore/detail/goodreads-compare-books/jcbnjaifalpejkcgfbpjbcmkfdildgpi) which adds "compare" info next to usernames ([GR forum](https://www.goodreads.com/topic/show/1259264?comment=182399130#comment_182399130))
  - untested: Andrea Samorini's [SamoGoodreadsUtility](https://github.com/asamorini/goodreads.utility) which adds language filters to GR ([GR forum](https://www.goodreads.com/topic/show/19375556?comment=188383878#comment_188383878))
  - untested: [Greasyfork Browser-Scripts](https://greasyfork.org/en/scripts/by-site/goodreads.com)
- Other
  - Data: thousands of books and authors (not GR) https://openlibrary.org/developers/dumps
- Personal
  - [a list of things](GOODTIPS.md) that improved my Goodreads experience: settings, browser extensions etc.
  - [Andre at Goodreads](https://www.goodreads.com/user/show/18418712-andr)
