# recentrated.pl

## Know when people rate or write reviews about a book

From the _Goodreads Feedback_ forum, [Elizabeth:](https://www.goodreads.com/topic/show/18060629-follow-book)
> I know this has been requested before, but I'd really like the opportunity to
> follow a book. I'd like to know when people rate or write reviews about a
> book and to be notified of such. I have some favorites that are not
> particularly well known or often read, and I'd like to know about who chooses
> to read them. 


## This
```
From: yourmail@example.com
To: yourmail@example.com
Subject: New ratings on Goodreads.com
Date: Wed, 10 Jan 2018 21:10:50 +0100

Recently rated books in your "watch-ratings" shelf:

  "The Machine Question"
   https://www.goodreads.com/user/show/54336239  *****  Alfred Leto

  "Spam: A Shadow History of the Internet"
   https://www.goodreads.com/book/show/16718273  [12 new]
   
  "Understanding Beliefs"
   https://www.goodreads.com/user/show/22346637  ****-  Rainer Bitz
   https://www.goodreads.com/user/show/24850532  **---  Lisa Short

```

## How to "follow books" without installation

1. visit [https://andre-st.github.io/goodreads/](https://andre-st.github.io/goodreads/) 
2. enter your e-mail and shelf address


## Dos and don'ts

- don't use the "All" or "Read" shelves; be picky, use a separate single purpose shelf
- don't run this on more than one of your shelves; it's possible but better use a single purpose shelf
- don't use this program with well known fiction books that get a lot of reviews; no insights, readers too random


## How to "follow books" using GNU/Linux

1. have a [Goodreads.com](https://www.goodreads.com) account

2. optionally create and [populate](http://i0.wp.com/theeverscholar.com/wp-content/uploads/2015/03/goodreads3.jpg) 
	a Goodreads shelf, e.g., "watch-ratings": You can add and remove books at any time. 
	New books will be checked automatically. 
	Such a shelf prevents unnecessary mails and eases manual checks if this system is discontinued someday.
	
3. open a terminal and install the Goodreads Toolbox:
	``` sh
	$ git clone https://github.com/andre-st/goodreads.git
	$ cd goodreads
	$ chmod +x recentrated.pl
	$ sudo mkdir -p /var/db/good/
	$ sudo touch /var/log/good.log
	$ sudo chown $USER:$USER /var/db/good /var/log/good.log
	$ sudo perl -MCPAN -e 'install Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any'
	```
4. have a sendmail MTA set up (most simple thing is [ssmtp](https://wiki.debian.org/sSMTP)
   or [nullmailer](http://untroubled.org/nullmailer/)
   or [msmtp](http://msmtp.sourceforge.net), 
   with `/usr/sbin/sendmail` being symlinked to one of them), 
   configure default "From:"
   
5. add a cron-job (I prefer [anacrony](https://en.wikipedia.org/wiki/Anacron "performs pending jobs if the computer was previously shut down") daemons: [dcron](https://github.com/dubiousjim/dcron) or [fcron](https://en.wikipedia.org/wiki/Fcron)):
	edit `/etc/cron.daily/goodratings` and replace ARGUMENTS:
	``` sh
	#!/usr/bin/env sh
	# `ifne` is part of `moreutils`
	/path/to/recentrated.pl GOODUSERID SHELFNAME YOURMAIL@EXAMPLE.COM | ifne /usr/sbin/sendmail -t
	
	# Provide this service to your Goodreads friends too!
	# ... HERUSERID HERSHELF HERMAIL@EXAMPLE.COM ADMIN@EXAMLE.COM | ...
	# ...
	```
	```sh
	$ sudo chmod +x /etc/cron.daily/goodratings
	```
	See also [cron.daily/goodratings.example](cron.daily/goodratings.example)


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## Licence

Creative Commons BY-SA


