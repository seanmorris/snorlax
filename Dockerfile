ARG UID=1000
ARG GID=1000

FROM debian:bookworm-20240812-slim AS base
MAINTAINER Sean Morris <sean@seanmorr.is>

ARG UID
ARG GID

SHELL ["/bin/bash", "-c"]

RUN set -eux;\
	apt-get update;\
	apt-get install -y --no-install-recommends\
		apache2 bsdmainutils make file openssl uuid-runtime inotify-tools;

RUN set -eux;\
	a2enmod \
	actions \
	alias \
	allowmethods \
	cgi \
	http2 \
	rewrite;

RUN set -eux;\
	chmod -R ug+rw   /var/log/apache2 /var/run/apache2 /var/www;\
	chown -R +${UID} /var/log/apache2 /var/run/apache2 /var/www; \
	chgrp -R +${GID} /var/log/apache2 /var/run/apache2 /var/www; \
	ln -sf /proc/self/fd/2 /var/log/apache2/access.log;\
	ln -sf /proc/self/fd/2 /var/log/apache2/error.log;

RUN set -eux;\
	apt-get autoremove -y;  \
	apt-get clean;

COPY methods.conf /etc/apache2/mods-enabled/

RUN set -eux;\
	apt-get update;\
	apt-get install -y --no-install-recommends\
		pandoc python-jsonschema jq;

USER $UID

ENTRYPOINT ["apachectl", "-D", "FOREGROUND"]
