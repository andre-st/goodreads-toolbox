# friendgroup.pl

![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)


## Discussion groups common among the people you follow

From the _Goodreads Feedback_ forum, [Carlissa (2018)](https://web.archive.org/web/20190525013220/https://www.goodreads.com/topic/show/19548229-finding-a-particular-type-of-group):
> ... The best way to find a group is by word of mouth from friends ...

or Faith (ibidem):
> Look at the lists of groups to which your friends or people you follow belong. 


## This
 
![Screenshot](img/friendgroup.png?raw=true "Screenshot")



## How to generate this on a GNU/Linux operating system

```console
$ git clone https://github.com/andre-st/goodreads.git
$ cd goodreads
$ sudo make        # Required Perl modules from CPAN
$ ./friendgroup.pl --help
$ ./friendgroup.pl goodlogin@example.com

Enter GR password for goodlogin@example.com: *****************
Signing in to Goodreads... OK
Getting list of members known to #18418712... 141 members (0.18s)
[  0%] Aron Mellendar            #21254511      0 groups     0.41s
[  1%] Moshe Fiono               #3932835       0 groups     0.80s
[  2%] Peter Glowwa              #18936366      2 groups     0.58s
[  3%] DuyGeboad                 #73957929      9 groups     0.05s
[  3%] Michael                   #9482539       0 groups     0.15s
[  5%] Peter Prischl             #17272051      0 groups     1.47s
[  6%] Steven Shoffork           #51011129      0 groups     0.15s
[  7%] 2mo                       #32504210     12 groups     0.07s
...
[ 99%] Charlene                  #2442665       0 groups     2.41s
[100%] David                     #7634567       0 groups     0.01s

Perfect! Got groups of 141 users.
Writing results to "friendgroup-1234567.html"... 245 groups (0.31s)
Total time: 2 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days and saves to /tmp/FileCache/.



## Observations and limitations

- long runtime: Goodreads slows down all requests and we have to load a lot of data
- sometimes you don't know what you can have and you wouldn't search for it, but it might show up here


## Feedback

If you like this project, give it a star on GitHub.
Report bugs or suggestions [via GitHub](https://github.com/andre-st/goodreads/issues) 
or see the [AUTHORS.md](../AUTHORS.md) file.


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [friendnet.pl](friendnet.md)     - Social network analysis
- [likeminded.pl](likeminded.md)   - Find Goodreads members with similar book taste
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [search.pl](search.md)           - Sort books-search results by popularity or date published
- [savreviews.pl](savreviews.md)   - Get all reviews of a book
