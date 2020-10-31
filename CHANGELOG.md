# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Version number 1.MINOR.PATCH, increments:
- MINOR version when relevant functionality was added, removed, changed
- PATCH version on bug fixes or small aesthetic changes


## [Unreleased]

- see [GitHub issues labeled "next release"](https://github.com/andre-st/goodreads-toolbox/issues?q=is%3Aopen+is%3Aissue+label%3A"next+release")



## [v1.23] - 2020-10-31
## Note
This is primary a maintenance update after a long time.


## Fixed

- similaraut.pl:
	- failed to load authors because the source markup changed after the last version
- some improvements on the looks of all HTML reports

## Added

- similarauth.pl:
	- new `--minseen` parameter to drop authors that are not similar to at least N other authors;
	  reduces the number of authors and size of the output file

## Changed

- recentrated.pl: 
	`--textonly` option also drops smaller texts now,
	 because the flag's purpose is to cut down "noisy" e-mails with too many ratings
	 and smaller reviews are almost always useless too ("loved it so much!").
	 Without this flag, [\*\*\*\* ], [TTTT ] and [tttt ] are shown as usual.
- lib/Goodscrapes.pl:
	- greadreviews() parameter `text_only` was renamed to `text_minlen`




## [v1.22] - 2019-11-16
## Fixed

- possible cross-site scripting attacks (XSS) against our HTML reports
  by adding Javascript to reviews, usernames, book titles on the Goodreads website.
  This software is too insignificant to be a real target, but you never know.
  
## Added

- `Dockerfile`: Docker is a popular software that allows users to run apps
  in an isolated container with all dependencies included/matched; 
  there are make-targets for Docker, now, see `make help`.
  The container runs a simple web-server so that a host can access 
  any HTML report generated within the container.
  ([#30](https://github.com/andre-st/goodreads-toolbox/issues/30))
  

## Changed

- all programs write to the new `list-out` directory by default and 
  not to the main directory any longer.
  This simplifies sharing files between a Docker container and its host 
  (using Docker volumes or a httpd).
- the `dict` directory was renamed to `list-in`, 
  `dict/default.lst` was renamed to `list-in/dict.lst`



## [v1.21.1] - 2019-10-13
## Fixed

- savreviews.pl: "Undefined subroutine &Goodscrapes::max called at Goodscrapes.pm"



## [v1.21.0] - 2019-10-10
## Fixed

- "Use of uninitialized value $uid in concatenation (.) or string at Goodscrapes.pm" 
  was caused by "NOT A BOOK" books, which actually have different book IDs but lack 
  author info etc

## Added

- all programs support the `--ignore-errors` option which disables retries and let
  a program keep going on despite of errors. This is useful when Goodreads has
  a bad day with permanent timeouts or other problems which often only affect
  a few resources while most of them can be obtained without problems.
  You also can re-run a program without this option, so that missing resources
  are loaded from the web again (and everything else from your local cache)

## Removed

- developers: function `gsetcache()` was removed in favor of `gsetopt( cache_days => int )`



## [v1.20.2] - 2019-08-31
### Fixed

- friendnet.pl: missing ");" at the end (syntax error)
- friendrated.pl: poor table-caption in authors-report file

### Added

- friendrated.pl: new column 'GR Avg' with average rating by the Goodreads community
- git-hooks (developers): automatically check syntax of user-scripts and run library 
  unit-tests before pushing changes to GitHub

### Changed

- friendrated.pl: output-filenames include stars-range and number of favorers
- covers and titles are not in the same column any more; each its own
- renamed "doc" folder to "help"



## [v1.20.0] - 2019-08-26
### Fixed

- login problems due to changed GR source markup
- year numbers < 1000 (including negative B.C.) were extracted as `0`

### Added

- new program: friendnet.pl - saves your social network to CSV files for
  further processing with social network analysis tools
  ([#27](https://github.com/andre-st/goodreads-toolbox/issues/27))
- friendrated.pl:
	- new option `--excludemy=read` to exclude books which you've already read
	  ([#28](https://github.com/andre-st/goodreads-toolbox/issues/28))
	- new column 'Rank' in final books table
	  ([#29](https://github.com/andre-st/goodreads-toolbox/issues/29))
	- new column 'Author' in final books table
- table columns in HTML output are sortable in the web-browser, now

### Changed

- moved all program documentation to the new `doc`-directory
- friendrated.pl:
	- renamed option `--hate` to `--hated`
	- books-table and authors-table are no longer in the same report file: each has its own file now
	- option `--outfile` changed to `--outdir`

### Removed

- report.css was removed in favor of datatables.net libs (loaded from CDN)



## [v1.19.2] - 2019-05-26
### Fixed

- search.pl: Titles were missing in the generated HTML file due to changes
  in the source markup

### Added

- friendrated.pl: `--hate` option to list most hated books among the members you follow
  ([#24](https://github.com/andre-st/goodreads-toolbox/issues/24))
- recentrated.pl: allows login and can be run against non-public member accounts

### Changed

- friendrated.pl: `--rated` option changed to `--minrated`
- recentrated.pl: all option names and positional parameters changed (see --help)



## [v1.18.0] - 2019-05-10
### Fixed

- "Unescaped left brace in regex is illegal here in regex [...] line 1852" 
  error broke programs on some Perl version

### Added

- friendrated: new `--toread` option lists the most wished-for 
  books among the members you follow (program checks the "to-read" 
  shelves instead of the "read" shelves and sets `--rated=0`)
- recentrated: 
	- indicate active text-only option in mail body
	- indicate tweet-size text reviews by [tttt ] versus [TTTT ]



## [v1.17.0] - 2019-03-24
### Fixed

- similarauth.pl: showed 0 authors all the time because the source markup 
  was changed by GR

### Changed

- New CPAN dependencies, run Makefile or just run:
	`$ sudo perl -MCPAN -e "install IO::Prompter"`
- some programs no longer accept the Goodreads user-ID as first positional 
  parameter but expect the user's login email address;
  you can still check another user with the `--userid` option:
	- likeminded.pl
	- friendrated.pl
	- friendgroup.pl
	- similarauth.pl

### Added

- Users don't have to extract the Goodreads cookie from their web-browsers anymore.
  Programs which require a cookie can obtain it themselves now, 
  given the user's login email address and password.
  This should render the toolbox more accessible to its users
  ([#25](https://github.com/andre-st/goodreads-toolbox/issues/25))
- recentrated: `--textonly` option to skip ratings without text
  


## [v1.16.0] - 2019-02-16
### Fixed

- "Undefined subroutine &WWW::Curl::Easy::CURLOPT_TCP_KEEPALIVE" 
  ([#20](https://github.com/andre-st/goodreads-toolbox/issues/20))

### Changed

- savreviews: 
	- writes multiple files at once, with one file per star-rating 
	  ([#14](https://github.com/andre-st/goodreads-toolbox/issues/14))
	- reviews contain review date too
	- `--outfile` option changed to `--outdir`

### Added

- friendrated: second table in document with most read authors
- savreviews: prints statistics with number of reviews per year



## [v1.13.0] - 2019-01-18
### Changed

- likeminded: 
	- `--similar` option was renamed to `--common`
	- final report does not rank members by the number of common authors only but
	  includes library-sizes ([#18](https://github.com/andre-st/goodreads-toolbox/issues/18))
	- final report does not list private accounts anymore
- generated HTML-reports now include `report.css` for styling



## [v1.12.5] - 2019-01-13
### Fixed

- "Experimental keys on scalar is now forbidden" if Perl 5.20+

### Added

- likeminded: new option `--maxauthorbooks` to limit the amount of books per author
  since some authors list more than 2000 books; default is 600 most popular books
- friendrated: more filters, e.g., _"books with less than 1000 ratings 
  and published between 1950 to 1980 and ..."_ 
  ([#16](https://github.com/andre-st/goodreads-toolbox/issues/16))

### Changed

- if Goodreads shows an "unexpected error", all programs retry multiple times but continue in any case;
  critical conditions such as "maintenance mode", "over capacity", connection issues etc
  are handled as usual (continuous retries or user CTRL-C)
 


## [v1.11.0] - 2018-11-28
### Fixed

- missing results in search.pl and other tools
  if `num_ratings` or `num_reviews` &lt; 100
  due to regex mistake, which existed for 3 months 
  (since v1.9.0)



## [v1.10.0] - 2018-09-27
### Added

- new program: friendgroup.pl ([#6](https://github.com/andre-st/goodreads-toolbox/issues/6))
- cookie validity is tested against Goodreads at the start of a program (using cookies)



## [v1.9.1] - 2018-09-01
### Changed

- one `make` target only for all Toolbox programs (simplifies maintenance and usage)



## [v1.9.0] - 2018-08-24
### Fixed

- wrong value in `num_ratings` or `num_reviews` if N>=1,000,000



## [v1.8.0] - 2018-08-14
### Added

- new program: savreviews.pl
- multiple `--shelf` options: `--shelf=music --shelf=science` 
  ([#10](https://github.com/andre-st/goodreads-toolbox/issues/10))
- `--dict` options for custom dictionaries
- added words-based dictionaries to `./dict/` folder (perform better than Ngram dicts)

### Fixed

- search: exit condition bug



## [v1.7.0] - 2018-07-29
### Added

- new program: search.pl



## [v1.6.0] - 2018-07-21
### Added

- likeminded: dictionary-based reviews-search (builtin Ngrams dict) 
  ([#9](https://github.com/andre-st/goodreads-toolbox/issues/9))
    


## [v1.5.0] - 2018-07-05
### Added

- new program: similarauth.pl



## [v1.4.0] - 2018-06-24
### Removed

- XML/XSLT support dropped (YAGNI, less dependencies)


### Changed

- likeminded: compares authors now, not books (see likeminded.md for details)
- all programs write to HTML files now, no XML/XSLT any longer



## [v1.3.0] - 2018-06-22
### Added

- new program: likeminded.pl



## [v1.2.2] - 2018-05-18
### Changed

- recentrated:
	- removed reviewer names from mail (noise)
	- indicates text reviews with `[TTTT ]` vs `[**** ]`
	- shorter URLs (mail clients recognize URLs without protocol too)



## [v1.2.0] - 2018-05-10
### Added

- new program: friendrated.pl



## [v1.1.0] - 2018-01-09
### Added

- new program: recentrated.pl



## [v1.0.0] - 2014-11-05
### Added

- new program: amz-tradein.pl


