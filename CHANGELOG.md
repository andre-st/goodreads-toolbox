# Changelog

All notable changes to this project will be documented in this file.



## [1.18.0] - 2019-05-10
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



## [1.17.0] - 2019-03-24
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
  ([#25](https://github.com/andre-st/goodreads/issues/25))
- recentrated: `--textonly` option to skip ratings without text
  


## [1.16.0] - 2019-02-16
### Fixed

- "Undefined subroutine &WWW::Curl::Easy::CURLOPT_TCP_KEEPALIVE" ([#20](https://github.com/andre-st/goodreads/issues/20))

### Changed

- savreviews: 
	- writes multiple files at once, with one file per star-rating ([#14](https://github.com/andre-st/goodreads/issues/14))
	- reviews contain review date too
	- `--outfile` option changed to `--outdir`

### Added

- friendrated: second table in document with most read authors
- savreviews: prints statistics with number of reviews per year



## [1.13.0] - 2019-01-18
### Changed

- likeminded: 
	- `--similar` option was renamed to `--common`
	- final report does not rank members by the number of common authors only but
	  includes library-sizes ([#18](https://github.com/andre-st/goodreads/issues/18))
	- final report does not list private accounts anymore
- generated HTML-reports now include `report.css` for styling



## [1.12.5] - 2019-01-13
### Fixed

- "Experimental keys on scalar is now forbidden" if Perl 5.20+

### Added

- likeminded: new option `--maxauthorbooks` to limit the amount of books per author
  since some authors list more than 2000 books; default is 600 most popular books
- friendrated: more filters, e.g., _"books with less than 1000 ratings 
  and published between 1950 to 1980 and ..."_ ([#16](https://github.com/andre-st/goodreads/issues/16))

### Changed

- if Goodreads shows an "unexpected error", all programs retry multiple times but continue in any case;
  critical conditions such as "maintenance mode", "over capacity", connection issues etc
  are handled as usual (continuous retries or user CTRL-C)
 


## [1.11.0] - 2018-11-28
### Fixed

- missing results in search.pl and other tools
  if `num_ratings` or `num_reviews` &lt; 100
  due to regex mistake, which existed for 3 months 
  (since v1.9.0)



## [1.10.0] - 2018-09-27
### Added

- new program: friendgroup.pl ([#6](https://github.com/andre-st/goodreads/issues/6))
- cookie validity is tested against Goodreads at the start of a program (using cookies)



## [1.9.1] - 2018-09-01
### Changed

- one `make` target only for all Toolbox programs (simplifies maintenance and usage)



## [1.9.0] - 2018-08-24
### Fixed

- wrong value in `num_ratings` or `num_reviews` if N>=1,000,000



## [1.8.0] - 2018-08-14
### Added

- new program: savreviews.pl
- multiple `--shelf` options: `--shelf=music --shelf=science` ([#10](https://github.com/andre-st/goodreads/issues/10))
- `--dict` options for custom dictionaries
- added words-based dictionaries to `./dict/` folder (perform better than Ngram dicts)

### Fixed

- search: exit condition bug



## [1.7.0] - 2018-07-29
### Added

- new program: search.pl



## [1.6.0] - 2018-07-21
### Added

- likeminded: dictionary-based reviews-search (builtin Ngrams dict) ([#9](https://github.com/andre-st/goodreads/issues/9))
    


## [1.5.0] - 2018-07-05
### Added

- new program: similarauth.pl



## [1.4.0] - 2018-06-24
### Removed

- XML/XSLT support dropped (YAGNI, less dependencies)


### Changed

- likeminded: compares authors now, not books (see likeminded.md for details)
- all programs write to HTML files now, no XML/XSLT any longer



## [1.3.0] - 2018-06-22
### Added

- new program: likeminded.pl



## [1.2.2] - 2018-05-18
### Changed

- recentrated:
	- removed reviewer names from mail (noise)
	- indicates text reviews with [TTTT ] vs [**** ]
	- shorter URLs (mail clients recognize URLs without protocol too)



## [1.2.0] - 2018-05-10
### Added

- new program: friendrated.pl



## [1.1.0] - 2018-01-09
### Added

- new program: recentrated.pl



## [1.0.0] - 2014-11-05
### Added

- new program: amz-tradein.pl


