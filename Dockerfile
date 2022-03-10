# The final image is around 138 MB,
# Build time is around 7 minutes
#
FROM alpine:latest

# ----------------------------------------------------------------------------
# Configuring the image:

ENV PROGDIR=/root
ENV HTPORT=80
ENV HTDOCS=$PROGDIR/list-out
ARG BUILD_DATE
ARG PROJECT_VERSION
VOLUME /tmp/FileCache
EXPOSE $HTPORT

# About:
# http://label-schema.org/rc1/
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="Andre's Goodreads Toolbox"
LABEL org.label-schema.description="Tools for Goodreads.com, for finding people based on the books they've read, finding books popular among the people you follow, following new book reviews, etc"
LABEL org.label-schema.maintainer="datakadabra@gmail.com"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.version=$PROJECT_VERSION
LABEL org.label-schema.url="https://github.com/andre-st/goodreads-toolbox/blob/master/README.md"
LABEL org.label-schema.vcs-url="https://github.com/andre-st/goodreads-toolbox/"
LABEL org.opencontainers.image.source="https://github.com/andre-st/goodreads-toolbox/"


# ----------------------------------------------------------------------------
# Building the image:

# Use .dockerignore to exclude everything but the minimum necessary set of files.
COPY . $PROGDIR

WORKDIR $PROGDIR/

RUN apk add --no-cache      \
			build-base   \
			zlib-dev     \
			bash         \
			openssl      \
			openssl-dev  \
			perl-dev     \
			perl-doc     \
			thttpd       \
	&& make                                             \
	&& apk del --purge build-base openssl-dev zlib-dev  \
	;  rm -rf                                     \
			/usr/share/{man,doc,info,groff}/*   \
			$HOME/.cpan/build/*                 \
			$HOME/.cpan/sources/authors/id      \
			$HOME/.cpan/cpan_sqlite_log.*       \
			/tmp/cpan_install_*.txt             \
	; echo $'\
echo "*******************************************"\n\
echo "*** WELCOME TO ANDRES GOODREADS TOOLBOX ***"\n\
echo "*******************************************"\n\
echo "Available Tools:"\n\
ls -1 *.pl | nl -bn \n\
' > $HOME/.bashrc


# ----------------------------------------------------------------------------
# Running the container:

# bash already in WORKDIR:
# CMD service webfs start
ENTRYPOINT  thttpd -h 0.0.0.0 -p $HTPORT -d $HTDOCS -l /dev/null  &&  bash


