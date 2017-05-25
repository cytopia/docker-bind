# Bind Docker

<small>**Latest build:** 2017-05-24</small>

[![Build Status](https://travis-ci.org/cytopia/docker-bind.svg?branch=master)](https://travis-ci.org/cytopia/docker-bind) [![](https://images.microbadger.com/badges/version/cytopia/bind.svg)](https://microbadger.com/images/cytopia/bind "bind") [![](https://images.microbadger.com/badges/image/cytopia/bind.svg)](https://microbadger.com/images/cytopia/bind "bind") [![](https://images.microbadger.com/badges/license/cytopia/bind.svg)](https://microbadger.com/images/cytopia/bind "bind")

[![cytopia/bind](http://dockeri.co/image/cytopia/bind)](https://hub.docker.com/r/cytopia/bind/)


----

**Bind caching DNS server on Debian with wild-card domain support**

[![Devilbox](https://raw.githubusercontent.com/cytopia/devilbox/master/.devilbox/www/htdocs/assets/img/devilbox_80.png)](https://github.com/cytopia/devilbox)

<sub>This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**</sub>

----

## Options

### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | `0` | Show shell commands executed during start.<br/>Value: `0` or `1` |
| WILDCARD_DOMAIN | string | `` | Specify a wild-card domain to add during startup.<br/>Example: `WILDCARD_DOMAIN=example.com` or `WILDCARD_DOMAIN=local` or `WILDCARD_DOMAIN=loc`<br/>**Note:** `$WILDCARD_ADDRESS` must also be specified. |
| WILDCARD_ADDRESS | string | `` | Specify to which IP address the wild-card domain should point to.<br/>Example: `WILDCARD_ADDRESS=192.168.0.1`<br/>**Note:** $WILDCARD_DOMAIN` must also be specidied. |
| DNS_FORWARDER | string| `` | Specify a comma separated list of IP addresses as custom DNS resolver. This is useful if your LAN already has a DNS server which adds custom/internal domains and you still want to keep them in this DNS server<br/>Example: `DNS_FORWARDER=8.8.8.8,8.8.4.4` |

### Default mount points

- None


### Default ports

| Docker | Description  |
|--------|--------------|
| 53     | DNS Resolver |
| 53/udp | DNS Resolver |

## Usage

**1. Start normally (caching DNS only)**
```bash
$ docker run -i \
    -p 127.0.0.1:53:53 \
    -p 127.0.0.1:53/udp:53/udp \
    -t cytopia/bind
```

**2. Add wildcard Domain (*.example.com)**

`example.com` and all its subdomains (such as: `whatever.example.com`) will point to `192.168.0.1`:

```bash
$ docker run -i \
    -p 127.0.0.1:53:53 \
    -p 127.0.0.1:53/udp:53/udp \
    -e WILDCARD_DOMAIN=example.com \
    -e WILDCARD_ADDRESS=192.168.0.1 \
    -t cytopia/bind
```

**3. Add wildcard Domain (TLD)**

`loc` and all its subdomains (such as: `hostname.loc`) will point to `192.168.0.1`:

```bash
$ docker run -i \
    -p 127.0.0.1:53:53 \
    -p 127.0.0.1:53/udp:53/udp \
    -e WILDCARD_DOMAIN=loc \
    -e WILDCARD_ADDRESS=192.168.0.1 \
    -t cytopia/bind
```

**4. Add wildcard Domain (TLD) and use your corporate DNS server as resolver**

* `loc` and all its subdomains (such as: `hostname.loc`) will point to `192.168.0.1`:
* Your corporate DNS servers are `10.0.15.1` and `10.0.15.2`

```bash
$ docker run -i \
    -p 127.0.0.1:53:53 \
    -p 127.0.0.1:53/udp:53/udp \
    -e WILDCARD_DOMAIN=loc \
    -e WILDCARD_ADDRESS=192.168.0.1 \
	-e DNS_FORWARDER=10.0.15.1,10.0.15,2 \
    -t cytopia/bind
```

## Version

BIND 9.9.5
