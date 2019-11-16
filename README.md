# :books: Andre's Goodreads Toolbox, v1.22

![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)

9 Perl-scripts for Goodreads.com—the world largest book (cataloging) community. [What's new?](CHANGELOG.md)


## [recentrated.pl](./help/recentrated.md)

Checks all the books in your shelf for new ratings and notifies you
via periodical e-mail. It helps discover new criticisms and users with interesting 
libraries. You can [try this online](https://andre-st.github.io/goodreads/) if you 
don't want to install anything.
It implements the "follow book" feature that was requested in the Goodreads forums. 
[Usage+Schreenshot](./help/recentrated.md)


## [friendrated.pl](./help/friendrated.md)

Prints all books rated 4 or 5 stars by 3 or more persons you follow (including friends). 
It implements the "books common among the people I follow" feature that was requested 
in the Goodreads forums. It also lists the most read authors, the most wished-for 
and hated books.
[Usage+Schreenshot](./help/friendrated.md)


## [friendnet.pl](./help/friendnet.md)

Spiders your social network and creates files with edges and nodes which can be
easily processed with social network analysis software. It answers questions
like: Which members are popular among your friends?
[Usage+Schreenshot](./help/friendnet.md)


## [friendgroup.pl](./help/friendgroup.md)

Prints discussion groups common among the persons you follow (including friends).
Searching groups on Goodreads is a PITA, and sometimes you don't know what you can have 
and wouldn't search for it. [Usage+Schreenshot](./help/friendgroup.md)


## [likeminded.pl](./help/likeminded.md)

Prints Goodreads members who are interested in the same books as you.
It implements the "Finding people based on the books they've read"
feature that was requested in the Goodreads forums.
[Usage+Schreenshot](./help/likeminded.md)


## [similarauth.pl](./help/similarauth.md)

Prints authors who Goodreads thinks are similar to all the authors you're reading.
It implements the "Finding [all] similar authors" feature that was requested in the 
Goodreads forums.
[Usage+Schreenshot](./help/similarauth.md)


## [search.pl](./help/search.md)

Prints a books search result, ordered by average rating and number of ratings 
(most popular books), or date published, optionally with exact title matches. 
The Goodreads website doesn't offer it for some reason.
It implements the "Sort search results by rating" feature that was requested 
in the Goodreads forums.
[Usage+Schreenshot](./help/search.md)


## [savreviews.pl](./help/savreviews.md)

Saves text-reviews for a book to a text-file. It implements the "Extract all 
reviews for a specific book" feature that was requested in the Goodreads forums.
[Usage+Schreenshot](./help/savreviews.md)


## ~~[amz-tradein.pl](./help/amz-tradein.md)~~

This script fetched Amazon Trade-In prices for all books in a Goodreads.com
shelf ("resales" or "donations"). It automated regular manual bid-checking for 
hundreds of books, discovering sales opportunities. Amazon stopped its buyback 
program in 2015.
[Usage+Schreenshot](./help/amz-tradein.md)



## Getting started

1. GNU/Linux terminal:

```console
$ git clone https://github.com/andre-st/goodreads-toolbox.git
$ cd goodreads-toolbox
```

2. [Docker](https://opensource.com/resources/what-docker)-users can run this app in its own container. 
   Access generated reports via web-browser at "localhost:8080":

```console
$ make docker-image
$ make docker-run DOCKER_HTPORT=8080
% ./example-script.pl --help
% ...
% ...
```

2. Non-Docker users can install this app directly on their systems:

```console
$ sudo make             # Gets required Perl modules from CPAN
$ ./example-script.pl --help
$ ...
$ ...
$ sudo make uninstall   # Finally remove cache, logs etc from sys-dirs
```

_Microsoft Windows_ and _Apple's macOS_ is not natively supported:
- a Windows user wrote me that he ran the toolbox on the [Windows 10 Subsystem for Linux](https://linuxhint.com/install_ubuntu_windows_10_wsl/) (WSL)
- there is Docker for Windows (LCOW) and Mac, the ./Dockerfile might be sufficient
- there is [VirtualBox](https://www.virtualbox.org/) for Windows and macOS which can run a [Linux image](https://www.osboxes.org/virtualbox-images/)
- maybe you get the toolbox installed directly to your macOS, along with Perl 5, curl and some hacks

_The usual runtime_ of the programs will be long:
- Goodreads slows down all requests and we have to load a lot of data
- start one program and do other things in the meantime
- you can break any program with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later (reloads from a file-cache)



## Contributing

- Reporting bugs / feature requests
  - add a new issue via [Github's issue tracker](https://github.com/andre-st/goodreads-toolbox/issues/new)
  - [alternative contact options](AUTHORS.md)
  - thank you all who wrote me mails in the past or otherwise reported bugs and ideas :thumbsup:
- Writing your own scripts
  - see the [tests directory](./t/) for examples on how to use the toolbox library
  - see the [toolbox library documentation](./lib/Goodscrapes.pod)
  - user scripts should contain a man page, take the existing user scripts as an example
  - the [less complex issues](https://github.com/andre-st/goodreads-toolbox/labels/beginner)
    would be good first issues to work on for users who want to contribute to this project



## Further readings

- About Goodreads
  - [GR developers group](https://www.goodreads.com/group/show/8095-goodreads-developers)
  - [GR technology stack](https://www.goodreads.com/jobs?id=597248#openPositions) 
		or [here](https://www.glasswaves.co/selected_projects.txt) 
		or [here](https://builtwith.com/goodreads.com) 
		or [DynamoDB+S3+Athena](https://aws.amazon.com/blogs/big-data/how-goodreads-offloads-amazon-dynamodb-tables-to-amazon-s3-and-queries-them-using-amazon-athena/)
  - [GR workplace reviews](https://www.glassdoor.com/Reviews/Goodreads-Reviews-E684833.htm), 
		anonymously about being acquired by Amazon, bureaucracy etc.
  - [GR on Crunchbase](https://www.crunchbase.com/organization/goodreads), 
		people, recent news & activity 
  - [GR members stats](https://www.statista.com/search/?q=goodreads&qKat=search) 
		or [here](https://qz.com/1106341/most-women-reading-self-help-books-are-getting-advice-from-men/) 
		or [here](https://onlinelibrary.wiley.com/doi/abs/10.1002/asi.23733)+[Sci-Hub](https://twitter.com/scihub_love) 
		or [here](https://book.pressbooks.com/chapter/goodreads-otis-chandler) 
		or [here](https://www.buzzfeednews.com/article/annanorth/what-amazon-is-getting-from-goodreads),
		source probably [Goodreads](https://www.goodreads.com/about/us)
  - [GR on Slideshare](https://www.slideshare.net/GoodreadsPresentations/presentations), 
		presenting GR book marketing to authors, see also [Author Feedback Group](https://www.goodreads.com/group/show/31471) 
  - [GR subreddit](https://www.reddit.com/r/goodreads/)
- Further software 
  - I leave statistics about your own reading habits to the following tools; 
		my toolbox, in contrast, focuses on the social periphery, with Goodreads providing the largest user base
  - Paul Klinger's [Bookstats](https://github.com/PaulKlinger/Bookstats) or [here](https://almoturg.com/bookstats/)
  - untested: John Smith's [GoodreadsAnalysis](https://github.com/JohnSmithDev/GoodreadsAnalysis/blob/master/REPORTS.md)
  - untested: Petr's [CompareBooks](https://github.com/vatioz/GoodreadsUserCompare) 
		browser [extension](https://chrome.google.com/webstore/detail/goodreads-compare-books/jcbnjaifalpejkcgfbpjbcmkfdildgpi) 
		adds "compare" info next to usernames
  - untested: Andrea Samorini's [SamoGoodreadsUtility](https://github.com/asamorini/goodreads.utility) 
		adds language filters to GR 
  - untested: Danish Prakash's [goodreadsh](https://github.com/danishprakash/goodreadsh) 
		is a command line interface for Goodreads (off. API)
  - untested: [Greasyfork Browser-Scripts](https://greasyfork.org/en/scripts/by-site/goodreads.com)
  - untested: the [Bookar Android app](https://github.com/intmainreturn00/Bookar) visualizes your books in augmented reality
  - Amazon: [export and filter wishlists](https://github.com/andre-st/amazon-wishless) by price and priority
- Other
  - Data: thousands of books and authors (not GR) https://openlibrary.org/developers/dumps
- Personal
  - [a list of things](./help/GOODTIPS.md) that improved my Goodreads experience: settings, browser extensions etc.
  - [Andre at Goodreads](https://www.goodreads.com/user/show/18418712-andr)


