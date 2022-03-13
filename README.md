# Bind Docker


[![lint](https://github.com/cytopia/docker-bind/workflows/lint/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Alint)
[![build](https://github.com/cytopia/docker-bind/workflows/build/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Abuild)
[![nightly](https://github.com/cytopia/docker-bind/workflows/nightly/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Anightly)

[![Tag](https://img.shields.io/github/tag/cytopia/docker-bind.svg)](https://github.com/cytopia/docker-bind/releases)
[![Gitter](https://badges.gitter.im/cytopia/Lobby.svg)](https://gitter.im/cytopia/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Discourse](https://img.shields.io/discourse/https/devilbox.discourse.group/status.svg?colorB=%234CB697)](https://devilbox.discourse.group)
[![](https://images.microbadger.com/badges/version/cytopia/bind.svg)](https://microbadger.com/images/cytopia/bind "bind")
[![](https://images.microbadger.com/badges/image/cytopia/bind.svg)](https://microbadger.com/images/cytopia/bind "bind")
[![License](https://img.shields.io/badge/license-MIT-%233DA639.svg)](https://opensource.org/licenses/MIT)

**Available Architectures:**  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`

----

Bind caching DNS server based on Debian slim with support for DNS forwarders, infinite wild-card DNS, infinite extra hosts, reverse DNS, DNSSEC timing settings and others.


| Docker Hub | Upstream Project |
|------------|------------------|
| <a href="https://hub.docker.com/r/cytopia/bind"><img height="82px" src="http://dockeri.co/image/cytopia/bind" /></a> | <a href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |


----

**Table of Contents**

1. [Environmental variables](#environmental-variables)
    1. [Required environmental variables](#required-environmental-variables)
    2. [Optional environmental variables](#optional-environmental-variables)
        1. [DEBUG_ENTRYPOINT](#debug_entrypoint)
        2. [DOCKER_LOGS](#docker_logs)
        3. [WILDCARD_DNS](#wildcard_dns)
        4. [EXTRA_HOSTS](#extra_hosts)
        5. [DNSSEC_VALIDATE](#dnssec_validate)
        5. [DNS_FORWARDER](#dns_forwarder)
        6. [TTL_TIME](#ttl_time)
        7. [REFRESH_TIME](#refresh_time)
        8. [RETRY_TIME](#retry_time)
        9. [EXPIRY_TIME](#expiry_time)
        10. [MAX_CACHE_TIME](#max_cache_time)
        11. [ALLOW_QUERY](#allow_query)
        12. [ALLOW_RECURSION](#allow_recursion)
2. [Default mountpoints](#default-mountpoints)
3. [Default ports](#default-ports)
4. [Examples](#examples)
    1. [Default run](#default-run)
    2. [Wildcard domain](#wildcard-domain)
    3. [Wildcard subdomain](#wildcard-subdomain)
    4. [Wildcard TLD](#wildcard-tld)
    5. [Wildcard TLD and reverse DNS entry](#wildcard-tld-and-reverse-dns-entry)
    6. [Wildcard TLD and DNS resolver](#wildcard-tld-and-dns-resolver)
    7. [Wildcard TLD, DNS resolver and extra hosts](#wildcard-tld-dns-resolver-and-extra-hosts)
    8. [Extra hosts, DNS resolver, allow query, and allow recursion](#extra-hosts-dns-resolver-allow-query-and-allow-recursion)
5. [Host integration](#host-integration)
6. [Support](#support)
7. [License](#license)

---

## Environmental variables

### Required environmental variables

- None

### Optional environmental variables

| Variable           | Type   | Default   | Description |
|--------------------|--------|-----------|-------------|
| `DEBUG`            | bool   | `0`       | Set to `1` in order to add `set -x` to entrypoint script for bash debugging |
| `DEBUG_ENTRYPOINT` | bool   | `0`       | Show shell commands executed during start.<br/>Values: `0`, `1` or `2` |
| `DOCKER_LOGS`      | bool   | `0`       | Set to `1` to log info and queries to Docker logs. |
| `WILDCARD_DNS`     | string |           | Add one or more tld's, domains or subdomains as catch-all for a specific IP address or CNAME. Reverse DNS is optional and can also be specified. |
| `EXTRA_HOSTS`      | string |           | Add one or more hosts (CNAME: tld's, domains, subdomains) to map to a specific IP address or CNAME. Reverse DNS is optional and can also be specified. |
| `DNSSEC_VALIDATE`  | string | `no`      | Control the behaviour of DNSSEC validation. The default is to not validate: `no`. Other possible values are: `yes` and `auto`. |
| `DNS_FORWARDER`    | string |           | Specify a comma separated list of IP addresses as custom DNS resolver. This is useful if your LAN already has a DNS server which adds custom/internal domains and you still want to keep them in this DNS server<br/>Example: `DNS_FORWARDER=8.8.8.8,8.8.4.4` |
| `TTL_TIME`         | int    | `3600`    | (Time in seconds) See [BIND TTL](http://www.zytrax.com/books/dns/apa/ttl.html) and [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)|
| `REFRESH_TIME`     | int    | `1200`    | (Time in seconds) See [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html) |
| `RETRY_TIME`       | int    | `180`     | (Time in seconds) See [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html) |
| `EXPIRY_TIME`      | int    | `1209600` | (Time in seconds) See [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html) |
| `MAX_CACHE_TIME`   | int    | `10800`   | (Time in seconds) See [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html) |
| `ALLOW_QUERY`      | string |           | Specify a comma separated list of IP addresses with optional CIDR mask to allow queries from a specific IP address or ranges of IP addresses. This allows for control over who is allowed to query the DNS server. If not specified all hosts are allowed to make queries (defaults to `any`). See [BIND QUERIES](http://www.zytrax.com/books/dns/ch7/queries.html) <br/>Example: `ALLOW_QUERY=192.168.1.0/24,127.0.0.1` |
| `ALLOW_RECURSION`  | string |           | Specify a comma separated list of IP addresses with optional CIDR mask to allow queries from a specific IP address or ranges of IP addresses.  This option allows this DNS server to forward a request to another DNS server when an address cannot be resolved. If not present the allow-query-cache default is assumed. See [BIND QUERIES](http://www.zytrax.com/books/dns/ch7/queries.html) <br/>Example: `ALLOW_RECURSION=192.168.1.0/24,127.0.0.1` |
#### DEBUG_ENTRYPOINT

* If set to `0`, only warnings and errors are shown
* If set to `1`, info, warnings and errors are shown
* If set to `2`, info, warnings and errors are shown, as well as commands executed during startup

#### DOCKER_LOGS

* If set to `0`, no additional logging is done during run-time
* If set to `1`, BIND is more verbose during run-time and shows asked queries as well as general information

#### WILDCARD_DNS

The `WILDCARD_DNS` option allows you to specify one or more multiple catch-all DNS zones which can either
be a full TLD, a domain or any kind of subdomain. It allows you to map your catch-all to a specific
IP address or even a CNAME (if it is resolvable by public DNS servers). Optionally you can also assign
the reverse DNS name (PTR record).

The general format is as follows, whereas the string in square brackets it optional and responsible
for the reverse DNS (PTR records):
```bash
# Structure
WILDCARD_DNS='tld1=1.1.1.1[=tld],tld2=2.2.2.2[=tld2]'
WILDCARD_DNS='tld1=CNAME1[=tld],tld2=CNAME2[=tld2]'
```

Some examples:
```bash
# 1. One entry:
# The following catches all queries to *.tld and redirects them to 192.168.0.1
WILDCARD_DNS='tld=192.168.0.1'

# 2. Two entries:
# The following catches all queries to *.tld and redirects them to 192.168.0.1
# As well as all queries from *.example.org and redirects them to 192.168.0.2
WILDCARD_DNS='tld=192.168.0.1,example.org=192.168.0.2'

# 3. Using CNAME's for resolving:
# The following catches all queries to *.tld and redirects them to whatever
# IP example.org resolved to
WILDCARD_DNS='tld=example.org'

# 4. Adding reverse DNS:
# The following catches all queries to *.tld and redirects them to 192.168.0.1
# As well as adding reverse DNS from 192.168.0.1 to resolve to tld
WILDCARD_DNS='tld=192.168.0.1=tld'

# 5. Complex example
# The following catches all queries to *.tld and redirects them to whatever
# IP example.org resolved to. Additionally it adds a reverse DNS record from example.org's
# IP to resolve to tld (PTR record)
# It also adds another catch-all for the subdomain of *.cytopia.tld which will point to 192.168.0.1
# Including a reverse DNS record back to cytopia.tld
WILDCARD_DNS='tld=example.org=tld,cytopia.tld=192.168.0.1=cytopia.tld'
```

#### EXTRA_HOSTS

The `EXTRA_HOSTS` option almost works like the `WILDCARD_DNS` option, except that no wildcard is added,
but rather exactly the host you have specified.

This is useful if you want to add extra hosts to your setup just like the Docker Compose option
[extra_hosts](https://docs.docker.com/compose/compose-file/#extra_hosts)

```bash
# Structure
EXTRA_HOSTS='host1=1.1.1.1[=host1],host2=2.2.2.2[=host2]'
EXTRA_HOSTS='host1=CNAME1[=host1],host2=CNAME2[=host2]'
```

Some examples:
```bash
# 1. One entry:
# The following extra host 'tld' is added and will always point to 192.168.0.1.
# When reverse resolving '192.168.0.1' it will answer with 'tld'.
EXTRA_HOSTS='tld=192.168.0.1'

# 2. One entry:
# The following extra host 'my.host' is added and will always point to 192.168.0.1.
# When reverse resolving '192.168.0.1' it will answer with 'my.host'.
EXTRA_HOSTS='my.host=192.168.0.1'

# 3. Two entries:
# The following extra host 'tld' is added and will always point to 192.168.0.1.
# When reverse resolving '192.168.0.1' it will answer with 'tld'.
# A second extra host 'example.org' is added and always redirects to 192.168.0.2
# When reverse resolving '192.168.0.2' it will answer with 'example.org'.
EXTRA_HOSTS='tld=192.168.0.1,example.org=192.168.0.2'

# 4. Using CNAME's for resolving:
# The following extra host 'my.host' is added and will always point to whatever
# IP example.org resolves to.
# When reverse resolving '192.168.0.1' it will answer with 'my.host'.
EXTRA_HOSTS='my.host=example.org'

# 5. Adding reverse DNS:
# The following extra host 'my.host' is added and will always point to whatever
# IP example.org resolves to.
# As well as adding reverse DNS from 192.168.0.1 to resolve to tld
EXTRA_HOSTS='tld=192.168.0.1=tld'
```

#### DNSSEC_VALIDATE

The `DNSSEC_VALIDATE` variable defines the DNSSEC validation. Default is to not validate (`no`).
Possible values are:

* `yes` - DNSSEC validation is enabled, but a trust anchor must be manually configured. No validation will actually take place.
* `no` - DNSSEC validation is disabled, and recursive server will behave in the "old fashioned" way of performing insecure DNS lookups, until you have manually configured at least one trusted key.
* `auto` - DNSSEC validation is enabled, and a default trust anchor (included as part of BIND) for the DNS root zone is used.

#### DNS_FORWARDER

By default this dockerized BIND is not acting as a DNS forwarder, so it will not have any external
DNS available. In order to apply external DNS forwarding, you will have to specify one or more external
DNS server. This could be the one's from google for example (`8.8.8.8` and `8.8.4.4`) or any others
you prefer. In case your LAN has its own DNS server with already defined custom DNS records that you
need to make available, you should use them.

```bash
# Structure (comma separated list of IP addresses)
DNS_FORWARDER='8.8.8.8,8.8.4.4'
```

Some examples
```bash
DNS_FORWARDER='8.8.8.8'
DNS_FORWARDER='8.8.8.8,192.168.0.10'
```

#### TTL_TIME
Specify time in seconds.
For more information regarding this setting, see [BIND TTL](http://www.zytrax.com/books/dns/apa/ttl.html) and [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)

#### REFRESH_TIME
Specify time in seconds.
For more information regarding this setting, see [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)

#### RETRY_TIME
Specify time in seconds.
For more information regarding this setting, see [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)

#### EXPIRY_TIME
Specify time in seconds.
For more information regarding this setting, see [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)

#### MAX_CACHE_TIME
Specify time in seconds.
For more information regarding this setting, see [BIND SOA](http://www.zytrax.com/books/dns/ch8/soa.html)

#### ALLOW_QUERY

By default this dockerized BIND does not specify query rules.  This exposes the
allow-query options to specify who is allowed to query for results.
Note that ACLs are not yet handled.

```bash
# Structure (comma separated list of IP addresses, IP addresses with CIDR mask, or address match list names "none", "any", "localhost", and "localnets")
ALLOW_QUERY='192.168.1.0/24,127.0.0.1'
```

Some examples
```bash
ALLOW_QUERY='any'
ALLOW_QUERY='192.168.1.0/24,127.0.0.1'
```

#### ALLOW_RECURSION

By default this dockerized BIND does not allow DNS recursion. If BIND cannot resolve an address it
will act as a DNS client and forward the request to another DNS server.  This server is specified in the DNS_FORWARDER list.
Note that ACLs are not yet handled.

```bash
# Structure (comma separated list of IP addresses, IP addresses with CIDR mask, or address match list names "none", "any", "localhost", and "localnets")
ALLOW_RECURSION='192.168.1.0/24,127.0.0.1'
```

Some examples
```bash
ALLOW_RECURSION='any'
ALLOW_RECURSION='192.168.1.0/24,127.0.0.1'
```

## Default mount points

- None


## Default ports

| Docker | Description  |
|--------|--------------|
| 53     | DNS Resolver |
| 53/udp | DNS Resolver |


## Examples

The following examples start the container in foreground and use `-i`, so you can easily stop
it by pressing `<Ctrl> + c`. For a production run, you would rather use `-d` to send it to the
background.

#### Default run

Exposing the port is mandatory if you want to use it for your host operating system.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -t cytopia/bind
```

#### Wildcard domain

Let's add a wildcard zone for `*.example.com`. All subdomains as well as the main domain will resolve
to `192.168.0.1`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard subdomain

Let's add a wildcard zone for `*.aws.example.com`. All subdomains as well as the main subdomain will resolve
to `192.168.0.1`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='aws.example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard TLD

Let's add a wildcard zone for `*.loc`. All domains, subdomain as well as the TLD itself will resolve
to `192.168.0.4`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='loc=192.168.0.4' \
    -t cytopia/bind
```

#### Wildcard TLD and reverse DNS entry

Let's add a wildcard zone for `*.loc`. All domains, subdomain as well as the TLD itself will resolve
to `192.168.0.4`. Additionally we specify that `host.loc` will be the reverse loopup for `192.168.0.4`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='loc=192.168.0.4=host.loc' \
    -t cytopia/bind
```

#### Wildcard TLD and DNS resolver

Let's add a wildcard zone for `*.loc`. All domains, subdomain as well as the TLD itself will resolve
to `192.168.0.4`.

Let's also hook in our imaginary corporate DNS server into this container, so we can make use of
any already defined custom DNS entries by that nameserver.

* `loc` and all its subdomains (such as: `hostname.loc`) will point to `192.168.0.1`:
* Your corporate DNS servers are `10.0.15.1` and `10.0.15.2`

```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='loc=192.168.0.1' \
    -e DNS_FORWARDER=10.0.15.1,10.0.15.2 \
    -t cytopia/bind
```

#### Wildcard TLD, DNS resolver and extra hosts

* `loc` and all its subdomains (such as: `hostname.loc`) will point to `192.168.0.1`:
* Your corporate DNS servers are `10.0.15.1` and `10.0.15.2`
* Also add two extra hosts with custom DNS:
    - host5.loc -> 192.168.0.2
    - host5.org -> 192.168.0.3

```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e WILDCARD_DNS='loc=192.168.0.1' \
    -e EXTRA_HOSTS='host5.loc=192.168.0.2,host5.org=192.168.0.3' \
    -e DNS_FORWARDER=10.0.15.1,10.0.15.2 \
    -t cytopia/bind
```

#### Extra hosts, DNS resolver, allow query, and allow recursion

* Your trusted external DNS servers are `8.8.8.8` and `8.8.4.4` (google DNS servers)
* Allow queries from:
    - All 192.168.0.xxx addresses
    - Localhost aka 127.0.0.1
* Allow recursion to resolve other queries (such as www.google.com) from:
    - All 192.168.0.xxx addresses
    - Localhost aka 127.0.0.1
* Add an extra hosts with custom DNS:
    - host1 -> 192.168.0.11

```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e EXTRA_HOSTS='host1=192.168.0.11' \
    -e DNS_FORWARDER=8.8.8.8,8.8.4.4 \
    -e ALLOW_QUERY=192.168.0.0/24,127.0.0.1 \
    -e ALLOW_RECURSION=192.168.0.0/24,127.0.0.1 \
    -t cytopia/bind
```

## Host integration

You can run this DNS container locally without having to worry to affect any corporate DNS server
that are given to you via DHCP.

Add the following line to the very beginning to `/etc/dhcp/dhclient.conf`:
```bash
prepend domain-name-servers 127.0.0.1;
```
Restart network manager
```bash
# Via service command
$ sudo service network-manager restart

# Or the systemd way
$ sudo systemctl restart network-manager
```

This will make sure that whenever your `/etc/resolv.conf` is deployed, you will have `127.0.0.1`
as the first entry and also make use of any other DNS server which are deployed via the LAN's DHCP server.

If `cytopia/bind` is not running, it does not affect the name resolution, because you will still
have entries in `/etc/resolv.conf`.


## Support

If you need support, join the Gitter Chat: [![Join the chat at https://gitter.im/devilbox/Lobby](https://badges.gitter.im/devilbox/Lobby.svg)](https://gitter.im/devilbox/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


## License

**[MIT License](LICENSE.md)**

Copyright (c) 2016 [cytopia](https://github.com/cytopia)
