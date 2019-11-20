# The final image is around 199 MB,
# Build time is around 10 minutes
#
# An Alpine Linux based image would save 60 MB, but not worth the effort, atm (missing deps etc)
#
FROM ubuntu:18.04


# ----------------------------------------------------------------------------
# Configuring the image:

ENV PROGDIR=/app
ENV HTPORT=80
ENV HTDOCS=$PROGDIR/list-out
ARG BUILD_DATE
ARG PROJECT_VERSION
VOLUME /var/db/good /tmp/FileCache
EXPOSE $HTPORT

# About:
# http://label-schema.org/rc1/
LABEL org.label-schema.schema-version = "1.0"
LABEL org.label-schema.name           = "Andre's Goodreads Toolbox"
LABEL org.label-schema.description    = "9 tools for Goodreads.com, for finding people based on the books they've read, finding books popular among the people you follow, following new book reviews, etc"
LABEL org.label-schema.maintainer     = "datakadabra@gmail.com"
LABEL org.label-schema.build-date     = $BUILD_DATE
LABEL org.label-schema.version        = $PROJECT_VERSION
LABEL org.label-schema.url            = "https://github.com/andre-st/goodreads-toolbox/blob/master/README.md"
LABEL org.label-schema.vcs-url        = "https://github.com/andre-st/goodreads-toolbox"


# ----------------------------------------------------------------------------
# Building the image:

# ubuntu:18.04 [64 MB]:
#     base image
#
# "build-essential" [157 MB]:
#     gcc : installing some Perl modules includes compiling C code,
#     make: duplicating the Makefile in this Dockerfile would be error-prone (DRY),
#     CPAN: online repository for required Perl modules
#
# "libcurl4-openssl-dev":
#     Perl's WWW::Curl module is just a Perl extension interface for libcurl(-dev) 
#
# "libwww-curl-perl":
#     Makefile.PL in WWW-Curl-4.17.tar.gz will fail otherwise (WWW::Curl module)
#
# "perl-doc":
#     display ./script.pl --help page correctly
#
# "webfs":
#     allow host to access generated HTML reports via web-browser (instead of bindmounts)
#

COPY . $PROGDIR
WORKDIR $PROGDIR/

RUN apt-get update   \
	&& apt-get install -y --no-install-recommends   \
			build-essential        \
			libcurl4-openssl-dev   \
			libwww-curl-perl       \
			perl-doc               \
			webfs                  \
	&& make                          \
	&& apt-get purge -y --auto-remove build-essential   \
	&& rm -rf                                     \
			/var/lib/apt/lists/*                \
			/usr/share/{man,doc,info,groff}/*   \
			$HOME/.cpan/build/*                 \
			$HOME/.cpan/sources/authors/id      \
			$HOME/.cpan/cpan_sqlite_log.*       \
			/tmp/cpan_install_*.txt


# webfsd:
# http://svn.apache.org/viewvc/httpd/httpd/trunk/docs/conf/mime.types?view=co
RUN echo $'\
application/javascript         js           \n\
application/json               json         \n\
application/xml                xml xsl      \n\
application/xml-dtd            dtd          \n\
application/pdf                pdf          \n\
application/zip                zip          \n\
application/x-rar-compressed   rar          \n\
image/jpeg                     jpeg jpg jpe \n\
image/png                      png          \n\
image/gif                      gif          \n\
image/svg+xml                  svg svgz     \n\
text/css                       css          \n\
text/csv                       csv          \n\
text/html                      html htm     \n\
text/plain                     txt text conf def list lst log in \n\
' > /etc/mime.types


# ----------------------------------------------------------------------------
# Running the container:

# bash already in WORKDIR:
# CMD service webfs start
ENTRYPOINT webfsd -p $HTPORT -r $HTDOCS && bash


