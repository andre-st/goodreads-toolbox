# Andre's Goodreads Toolbox Makefile
# 
# TODO: Install perl dependencies to a local dir (no root required), deps-local target?
# TODO: build github packages docker image from the commited github trunk head or official remote repo instead of the dirty local working copy
# 
# 
# 


# Configure Make:
# https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
#.DEFAULT_GOAL := help


# Configure Make rules:
PROJECT_VERSION   = 1.23.2
RR_LOGFILE        = /var/log/good.log
RR_DB_DIR         = /var/db/good
CACHE_DIR         = /tmp/FileCache/Goodscrapes
BUILD_DIR         = .build
PACKAGE           = goodreads-toolbox
DOCKER_BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
DOCKER_IMG_VER    = ${PROJECT_VERSION}
DOCKER_IMG_NAME   = ${PACKAGE}
DOCKER_CON_NAME   = ${PACKAGE}
DOCKER_DIR        = .
DOCKER_HTPORT     = 8080
GITHUB_USER       = andre-st
GITHUB_REPONAME   = ${PACKAGE}
RELEASE           = $(PACKAGE)-$(PROJECT_VERSION)
GITDIR            = $(wildcard .git)

LIBCURLDEV_ERR = "Required packages: build-essential libcurl-dev libwww-curl-perl (Debian/Ubuntu names)"
LIBCURLDEV    := $(shell command -v curl-config 2> /dev/null)



# ----------------------------------------------------------------------------
## make all            :  Installs programs and dependencies from CPAN (default)
all: deps installdirs


# ----------------------------------------------------------------------------
## make installdirs    :  Creates work- and log-files in /var if not existing, prepares program-dir (symlinks)
.PHONY: installdirs $(GITDIR)
installdirs: | $(GITDIR)
	chmod +x *.pl
	ln -sf word-en-l.lst ./list-in/dict.lst
	mkdir -p "${RR_DB_DIR}"
	touch "${RR_LOGFILE}"
	chown --reference=recentrated.pl "${RR_DB_DIR}" "${RR_LOGFILE}"

# Developers:
$(GITDIR):
	# TODO: Since Git 2.9 there is `git config core.hooksPath .git-hooks`
	chmod +x git-hooks/*
	ln -sf ../../git-hooks/pre-commit ./.git/hooks/pre-commit
	ln -sf ../../git-hooks/pre-push   ./.git/hooks/pre-push


# ----------------------------------------------------------------------------
## make uninstall      :  Deletes work- and log-files in /var
.PHONY: uninstall
uninstall:
	rm -rf "${RR_DB_DIR}"
	rm -rf "${RR_LOGFILE}"
	rm -rf "${CACHE_DIR}"


# ----------------------------------------------------------------------------
## make deps           :  Downloads and installs dependencies from CPAN
# CPAN complains without YAML::Any (warning not error)
.PHONY: deps
deps:
ifndef LIBCURLDEV
	$(error ${LIBCURLDEV_ERR})
endif
	perl -MCPAN -e 'install YAML::Any, List::MoreUtils, HTML::Entities, URI::Escape, Cache::FileCache, WWW::Curl::Easy, Text::CSV, Log::Any, IO::Prompter, Test::More, Test::Exception'


# ----------------------------------------------------------------------------
## make check          :  Runs unit tests
.PHONY: check
check:
	prove


# ----------------------------------------------------------------------------
## make docker-image   :  Builds a Docker image from the dirty working copy
## make docker-run     :  Runs Docker image, optionally:
##                        make docker-run DOCKER_HTPORT=8080
##                        make docker-run DOCKER_CON_NAME=goodreads-toolbox
## make github-package :  Builds a Docker image from the official repo and pushes it to GitHub Packages
##                        Expects a PAT from GitHub > Account > Settings > Developer Settings > Personal access tokens
##                        in local file .github-packages.secret
##                        See packages: https://github.com/users/andre-st/packages

.PHONY: docker-image
docker-image: Dockerfile
	docker build \
			--build-arg BUILD_DATE="${DOCKER_BUILD_DATE}"      \
			--build-arg PROJECT_VERSION="${PROJECT_VERSION}"   \
			--tag "${DOCKER_IMG_NAME}:${DOCKER_IMG_VER}"       \
			${DOCKER_DIR}
	@echo "[NEXT] You might like to start the new Docker image with 'make docker-run'"


.PHONY: docker-run
docker-run:
	docker stop         ${DOCKER_CON_NAME} || true
	docker container rm ${DOCKER_CON_NAME} || true
	@echo "[NOTE] Goodreads results are written to 'list-out/', accessible via web-browser at localhost:${DOCKER_HTPORT}"
	@docker run \
			--name=${DOCKER_CON_NAME} \
			--publish=${DOCKER_HTPORT}:80 \
			--interactive \
			--tty \
			"${DOCKER_IMG_NAME}:${DOCKER_IMG_VER}" || true


.PHONY: github-package
github-package: .github-packages.secret
	rm    -rf  "${BUILD_DIR}/official-latest/"
	mkdir -p   "${BUILD_DIR}/official-latest/"
	pushd      "${BUILD_DIR}/official-latest/"
	git   clone  "https://github.com/${GITHUB_USER}/${GITHUB_REPONAME}/"  .
	make  docker-image  DOCKER_IMG_NAME=ghcr.io/${GITHUB_USER}/${GITHUB_REPONAME}  DOCKER_IMG_VER=latest
	popd
	cat .github-packages.secret | docker login ghcr.io -u ${GITHUB_USER} --password-stdin
	docker push "ghcr.io/${GITHUB_USER}/${GITHUB_REPONAME}"


# ----------------------------------------------------------------------------
## make docs           :  Updates documentation, optionally:
##                        make docs PROJECT_VERSION=1.22
.PHONY: docs
docs:
	# vX.X, vX.XX.X, image:X.XX.X
	sed -i -E "s/([v])[0-9\.]+/\1${PROJECT_VERSION}/"  README.md INSTALL.txt


# ----------------------------------------------------------------------------
## make help           :  Prints this help screen
#
# Prints all comments with two leading # characters in this Makefile
#
.PHONY: help
help: Makefile
	@sed -n 's/^## //p' $<



