# Andre's Goodreads Toolbox Makefile
# 
# TODO: Install perl dependencies to a local dir (no root required)
# TODO: convert perl scripts to Windows executables (Windows release)
# 

RR_LOGFILE  = /var/log/good.log
RR_DB_DIR   = /var/db/good
CACHE_DIR   = /tmp/FileCache/Goodscrapes
BUILD_DIR   = .build
PACKAGE     = gtoolbox
VERSION     = $(shell date +"%Y.%m%d")
RELEASE     = $(PACKAGE)-$(VERSION)
RELEASE_WIN = $(PACKAGE)-$(VERSION)-win


LIBCURLDEV_ERR = "Requires: libcurl-dev (on Debian or Ubuntu try `apt-get install libcurl-dev` before running this)"
LIBCURLDEV    := $(shell command -v curl-config 2> /dev/null)

# ----------------------------------------------------------------------------
## make all      :  Installs programs and dependencies (CPAN)
all :
ifndef LIBCURLDEV
	$(error ${LIBCURLDEV_ERR})
endif
perl -MCPAN -e 'install List::MoreUtils, HTML::Entities, URI::Escape, Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any, IO::Prompter'
	chmod +x *.pl
	ln -sf words-en-xl.lst            ./dict/default.lst
	ln -sf ../../git-hooks/pre-commit ./.git/hooks/pre-commit
	mkdir -p "${RR_DB_DIR}"
	touch "${RR_LOGFILE}"
	chown --reference=recentrated.pl "${RR_DB_DIR}" "${RR_LOGFILE}"


# ----------------------------------------------------------------------------
## make uninstall:  Deletes work- and log-files in /var
.PHONY : uninstall
uninstall :
	rm -rf "${RR_DB_DIR}"
	rm -rf "${RR_LOGFILE}"
	rm -rf "${CACHE_DIR}"


# ----------------------------------------------------------------------------
## make dist     :  Builds Linux or Windows release archives (NOT SUPPORTED)
.PHONY : dist
dist :
	

# ----------------------------------------------------------------------------
# Prints all comments with two leading # characters in this Makefile
.PHONY : help
help : Makefile
	@sed -n 's/^## //p' $<


