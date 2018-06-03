# André's Goodreads Toolbox Makefile
# Some day I'll try a MakeMaker Makefile.PL 

RR_LOGFILE = /var/log/good.log
RR_DB_DIR  = /var/db/good
ON_ERROR   = (echo "Please send your error messages to datakadabra@gmail.com" && false)


.PHONY : help
help : Makefile
	@sed -n 's/^## //p' $<


.PHONY : base
base :
	perl -MCPAN -e 'install Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any, XML::Writer' || $(ON_ERROR)
	chmod +x *.pl


## make dev        :  Setups .git directory (symlinks ./git-hooks etc)
.PHONY : dev
dev :
	@echo "TODO"


## make friendrated:  Installs Perl modules
.PHONY : friendrated
friendrated : base


## make recentrated:  Installs Perl modules and creates database and log in /var
.PHONY : recentrated
recentrated : base recentrated.pl
	mkdir -p "${RR_DB_DIR}"
	touch "${RR_LOGFILE}"
	chown --reference=recentrated.pl "${RR_DB_DIR}" "${RR_LOGFILE}"


## make all        :  Installs all programs
all : recentrated friendrated


## make uninstall  :  Deletes work and log files in /var
.PHONY : uninstall
uninstall :
	rm -r "${RR_DB_DIR}"
	rm -r "${RR_LOGFILE}"





