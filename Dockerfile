# The final image is around 328 MB, 
# Build time is around 10 minutes
#
# An Alpine Linux based image would save 60 MB, but not worth the effort, atm (missing deps etc)
#
FROM ubuntu:18.04
# FROM bitnami/minideb:jessie


# ----------------------------------------------------------------------------
# Configuring the image:

ENV PROGDIR=/app
ENV HTPORT=80
ENV HTDOCS=$PROGDIR/list-out
ARG BUILD_DATE
VOLUME /var/db/good /tmp/FileCache
EXPOSE $HTPORT

# About:
LABEL org.label-schema.name="Andre's Goodreads Toolbox"
LABEL org.label-schema.description="9 tools for Goodreads.com, for finding people based on the books they've read, finding books popular among the people you follow, following new book reviews, etc"
LABEL org.label-schema.maintainer="datakadabra@gmail.com"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.url="https://github.com/andre-st/goodreads-toolbox"


# ----------------------------------------------------------------------------
# Building the image:

# "build-essential":
#     gcc : installing some Perl modules includes compiling C code,
#     make: duplicating the Makefile in this Dockerfile would be error-prone (DRY),
#     CPAN: online repository for required Perl modules
# "libcurl4-openssl-dev":
#     Perl's WWW::Curl module is just a Perl extension interface for libcurl(-dev) 
# "libwww-curl-perl":
#     Makefile.PL in WWW-Curl-4.17.tar.gz will fail otherwise (WWW::Curl module)
#
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
			build-essential        \
			libcurl4-openssl-dev   \
			libwww-curl-perl       \
			webfs                  \
	&& rm -rf /var/lib/apt/lists/*   \
	&& rm -rf /usr/share/{man,doc,info,groff}/*

COPY . $PROGDIR

WORKDIR $PROGDIR/

RUN make \
	&& rm -rf \
			$HOME/.cpan/build/*              \
			$HOME/.cpan/sources/authors/id   \
			$HOME/.cpan/cpan_sqlite_log.*    \
			/tmp/cpan_install_*.txt


# ----------------------------------------------------------------------------
# Running the container:

# Default command if not given another on the command line, already in WORKDIR:
# CMD service webfs start
ENTRYPOINT webfsd -p $HTPORT -r $HTDOCS && bash


