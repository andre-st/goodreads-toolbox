# André's Goodreads Toolbox Makefile
# Some day I'll try a MakeMaker Makefile.PL 
# 
# TODO: perl -MCPAN exit code 0 despite errors
# 

RR_LOGFILE = /var/log/good.log
RR_DB_DIR  = /var/db/good


.PHONY : help
help : Makefile
	@sed -n 's/^## //p' $<


.PHONY : base
base :
	perl -MCPAN -e 'install HTML::Entities, Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any, XML::Writer'
	chmod +x *.pl


## make dev        :  Setups .git directory (symlinks ./git-hooks etc)
.PHONY : dev
dev :
	@echo "TODO"


## make friendrated:  Installs Perl modules
.PHONY : friendrated
friendrated : base


## make likeminded:  Installs Perl modules
.PHONY : likeminded
likeminded : base


## make recentrated:  Installs Perl modules and creates database and log in /var
.PHONY : recentrated
recentrated : base recentrated.pl
	mkdir -p "${RR_DB_DIR}"
	touch "${RR_LOGFILE}"
	chown --reference=recentrated.pl "${RR_DB_DIR}" "${RR_LOGFILE}"


## make all        :  Installs all programs
all : recentrated friendrated likeminded


## make uninstall  :  Deletes work and log files in /var
.PHONY : uninstall
uninstall :
	rm -rf "${RR_DB_DIR}"
	rm -rf "${RR_LOGFILE}"





