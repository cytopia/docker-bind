###
### BIND
###
FROM debian:stable
MAINTAINER "cytopia" <cytopia@everythingcli.org>


###
### Labels
###
LABEL \
	name="cytopia's Bind Image" \
	image="bind" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2018-01-11"


###
### Install
###
RUN apt-get update && apt-get -y install \
    bind9 \
  && rm -r /var/lib/apt/lists/*


###
### Bootstrap Scipts
###
COPY ./scripts/docker-entrypoint.sh /


###
### Ports
###
EXPOSE 53
EXPOSE 53/udp


####
#### Entrypoint
####
ENTRYPOINT ["/docker-entrypoint.sh"]
