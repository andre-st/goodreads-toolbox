# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org)



## [1.8.1] - 2018-09-01
### Changed

- one `make` target only for all Toolbox programs (simplifies maintenance and usage)


## [1.8.1] - 2018-08-24
### Fixed

- wrong value in `num_ratings` or `num_reviews` if N>=1,000,000


## [1.8.0] - 2018-08-14
### Added

- new program: savreviews.pl
- multiple `--shelf` parameter: `--shelf=music --shelf=science` ([#10](https://github.com/andre-st/goodreads/issues/10))
- `--dict` parameter for custom dictionaries
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


