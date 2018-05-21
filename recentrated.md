# recentrated.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


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
   www.goodreads.com/user/show/54336239  [*****]

  "Spam: A Shadow History of the Internet"
   www.goodreads.com/book/show/16718273  [9 new]

  "Understanding Beliefs"
   www.goodreads.com/user/show/22346637  [TTTT ]
   www.goodreads.com/user/show/24850532  [**   ]


--
 [***  ] 3/5 stars rating without text
 [TTT  ] 3/5 stars rating with add. text
 [9 new] ratings better viewed on book page
 ...   
```

## How to "follow books" 

### Installation-free:

1. visit [https://andre-st.github.io/goodreads/](https://andre-st.github.io/goodreads/) 
2. enter your e-mail and shelf address

### Self-hosted:

1. open a GNU/Linux terminal and install the Goodreads Toolbox:
	``` sh
	$ git clone https://github.com/andre-st/goodreads.git
	$ cd goodreads
	$ sudo make recentrated
	```
2. have a sendmail MTA set up (most simple thing is [ssmtp](https://wiki.debian.org/sSMTP)
   or [nullmailer](http://untroubled.org/nullmailer/)
   or [msmtp](http://msmtp.sourceforge.net), 
   with `/usr/sbin/sendmail` being symlinked to one of them), 
   configure default "From:"
   
3. add a cron-job (I prefer [anacrony](https://en.wikipedia.org/wiki/Anacron "performs pending jobs if the computer was previously shut down") daemons such as [dcron](https://github.com/dubiousjim/dcron) or [fcron](https://en.wikipedia.org/wiki/Fcron)):
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


## Dos and don'ts

- don't use the "All" or "Read" shelves; be picky, use a separate single purpose shelf
- don't run this on more than one of your shelves; it's possible but better use a single purpose shelf
- don't use this program with well known fiction books that get a lot of reviews; no insights, readers too random
- create and [populate](http://i0.wp.com/theeverscholar.com/wp-content/uploads/2015/03/goodreads3.jpg) 
	a Goodreads shelf, e.g., "watch-ratings": You can add and remove books at any time. 
	New books will be checked automatically. 
	Such a shelf prevents unnecessary mails and eases manual checks if this system is discontinued someday


## Feedback

Use [GitHub](https://github.com/andre-st/goodreads/issues) or see [AUTHORS.md](AUTHORS.md) file


## Licence

Creative Commons BY-SA


