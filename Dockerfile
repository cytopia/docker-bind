FROM debian:stable-slim
LABEL org.opencontainers.image.authors="cytopia@everythingcli.org"


###
### Install
###
RUN set -eux \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		bind9 \
		dnsutils \
		iputils-ping \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -r /var/lib/apt/lists/* \
	&& mkdir /var/log/named \
	&& chown bind:bind /var/log/named \
	&& chmod 0755 /var/log/named


###
### Bootstrap Scipts
###
COPY ./data/docker-entrypoint.sh /


###
### Ports
###
EXPOSE 53
EXPOSE 53/udp


####
#### Entrypoint
####
ENTRYPOINT ["/docker-entrypoint.sh"]
