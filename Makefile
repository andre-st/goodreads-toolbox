# André's Goodreads Toolbox Makefile
# Some day I'll try a MakeMaker Makefile.PL 
# 

RR_LOGFILE = /var/log/good.log
RR_DB_DIR  = /var/db/good


LIBCURLDEV_ERR = "Requires: libcurl-dev (on Debian or Ubuntu try `apt-get install libcurl-dev` before running this)"
LIBCURLDEV    := $(shell command -v curl-config 2> /dev/null)


# Prints all comments with two leading # characters in this Makefile
.PHONY : help
help : Makefile
	@sed -n 's/^## //p' $<


.PHONY : base
base :
ifndef LIBCURLDEV
	$(error ${LIBCURLDEV_ERR})
endif
	perl -MCPAN -e 'install HTML::Entities, Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any'
	chmod +x *.pl


## make dev        :  Setups .git directory (symlinks ./git-hooks etc)
.PHONY : dev
dev :
	ln -s ../../git-hooks/pre-commit ./.git/hooks/pre-commit


## make friendrated:  Installs Perl modules
.PHONY : friendrated
friendrated : base


## make likeminded :  Installs Perl modules
.PHONY : likeminded
likeminded : base


## make similarauth:  Installs Perl modules
.PHONY : similarauth
similarauth : base


## make recentrated:  Installs Perl modules and creates database and log in /var
.PHONY : recentrated
recentrated : base recentrated.pl
	mkdir -p "${RR_DB_DIR}"
	touch "${RR_LOGFILE}"
	chown --reference=recentrated.pl "${RR_DB_DIR}" "${RR_LOGFILE}"


## make all        :  Installs all programs
all : dev recentrated friendrated likeminded similarauth


## make uninstall  :  Deletes work- and log-files in /var
.PHONY : uninstall
uninstall :
	rm -rf "${RR_DB_DIR}"
	rm -rf "${RR_LOGFILE}"





