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

**Available Architectures:**  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le`

----

Bind caching DNS server based on Debian slim with support for DNS forwarders, infinite wild-card DNS, infinite extra hosts, reverse DNS, DNSSEC timing settings and others.


| Docker Hub | Upstream Project |
|------------|------------------|
| <a href="https://hub.docker.com/r/cytopia/bind"><img height="82px" src="http://dockeri.co/image/cytopia/bind" /></a> | <a href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |

## Available Docker tags

| Docker Tag                     | Description                                                  |
|--------------------------------|--------------------------------------------------------------|
| `latest`                       | Latest Debian stable image (default)                         |
| `stable`                       | Latest Debian stable image                                   |
| `alpine`                       | Latest Alpine image                                          |
|                                |                                                              |
| `[0-9]\.[0-9]+`                | Git tagged Debian stable image. E.g: `0.53`                  |
| `stable-[0-9]\.[0-9]+`         | Git tagged Debian stable image. E.g: `stable-0.53`           |
| `alpine-[0-9]\.[0-9]+`         | Git tagged Alpine image. E.g: `alpine-0.53`                  |
|                                |                                                              |
| `release-[0-9]\.[0-9]+`        | Git branch Debian stable image. E.g: `release-0.53`          |
| `stable-release-[0-9]\.[0-9]+` | Git branch Debian stable image. E.g: `stable-release-0.53`   |
| `alpine-release-[0-9]\.[0-9]+` | Git branch Alpine image. E.g: `alpine-release-0.53`          |


----

**Table of Contents**

1. [Environmental variables](#environmental-variables)
    1. [Required environmental variables](#required-environmental-variables)
    2. [Optional environmental variables](#optional-environmental-variables)
        1. [DEBUG_ENTRYPOINT](#debug_entrypoint)
        2. [DOCKER_LOGS](#docker_logs)
        3. [DNS_A](#dns_a)
        4. [DNS_CNAME](#dns_cname)
        5. [DNS_PTR](#dns_ptr)
        6. [DNSSEC_VALIDATE](#dnssec_validate)
        7. [DNS_FORWARDER](#dns_forwarder)
        8. [MAX_CACHE_SIZE](#max_cache_size)
        9. [TTL_TIME](#ttl_time)
        10. [REFRESH_TIME](#refresh_time)
        11. [RETRY_TIME](#retry_time)
        12. [EXPIRY_TIME](#expiry_time)
        13. [MAX_CACHE_TIME](#max_cache_time)
        14. [ALLOW_QUERY](#allow_query)
        15. [ALLOW_RECURSION](#allow_recursion)
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
| `DNS_A`            | string |           | Comma separated list of A records (wildcard supported). |
| `DNS_CNAME`        | string |           | Comma separated list of CNAME records (wildcard supported). |
| `DNS_PTR`          | string |           | Comma separated list of PTR records (reverse DNS). |
| `DNSSEC_VALIDATE`  | string | `no`      | Control the behaviour of DNSSEC validation. The default is to not validate: `no`. Other possible values are: `yes` and `auto`. |
| `DNS_FORWARDER`    | string |           | Specify a comma separated list of IP addresses as custom DNS resolver. This is useful if your LAN already has a DNS server which adds custom/internal domains and you still want to keep them in this DNS server<br/>Example: `DNS_FORWARDER=8.8.8.8,8.8.4.4` |
| `MAX_CACHE_SIZE`   | size   | `90%`     | Amount of memory used by the server (cached results) |
| `ttl_time`         | int    | `3600`    | (time in seconds) see [bind ttl](http://www.zytrax.com/books/dns/apa/ttl.html) and [bind soa](http://www.zytrax.com/books/dns/ch8/soa.html)|
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

#### DNS_A

The `DNS_A` option allows you to specify one or more A records (including wildcard if required) which can either
be a full TLD, a domain or any kind of subdomain. It allows you to map your Domain to a specific
IP address.

The general format is as follows:
```bash
# Structure
DNS_A='tld1=1.1.1.1, tld2=2.2.2.2, *.tld3=3.3.3.3'
```

Some examples:
```bash
# 1. One entry:
# The following catches all queries to *.tld (wildcard) and redirects them to 192.168.0.1
DNS_A='*.tld=192.168.0.1'

# 2. Two entries:
# The following catches all queries to *.tld and redirects them to 192.168.0.1
# As well as all queries from *.example.org and redirects them to 192.168.0.2
DNS_A='*.tld=192.168.0.1, *.example.org=192.168.0.2'
```

#### DNS_CNAME

The `DNS_CNAME` option allows you to specify one or more CNAME records (including wildcard if required) which can either
be a full TLD, a domain or any kind of subdomain. It allows you to map your Domain to a specific
IP address.

The general format is as follows:
```
# Structure
DNS_CNAME='tld1=google.com, tld2=www.google.com, *.tld3=example.org'
```

Some examples:
```
# 1. Using CNAME's for resolving:
# The following catches all queries to *.tld and redirects them to whatever
# IP example.org resolved to
DNS_CNAME='*.tld=example.org'
```

#### DNS_PTR

The `DNS_PTR` option allows you to specify PTR records (reverse DNS).

The general format is as follows:
```
# Structure
DNS_PTR='192.168.0.1=www.google.com, 192.168.0.2=ftp.google.com'
```

Some examples:
```
# 1. Adding reverse DNS:
# The following adds reverse DNS from 192.168.0.1 to resolve to tld
DNS_PTR='192.168.0.1=tld'
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
#### MAX_CACHE_SIZE
The amount of RAM used by the server to store results. You can use relative (percent) or absolute (bytes) values.
Examples:
* `MAX_CACHE_SIZE=30%` (Use 30% of the systems memory)
* `MAX_CACHE_SIZE=512M` (Use 512 Megabytes)
* `MAX_CACHE_SIZE=2G` (Use 2 Gigabytes)

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

Let's add a wildcard zone for `*.example.com`. All subdomains (but not example.com itself) will resolve
to `192.168.0.1`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard subdomain

Let's add a wildcard zone for `*.aws.example.com`. All subdomains (but not aws.example.com itself) will resolve
to `192.168.0.1`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.aws.example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard TLD

Let's add a wildcard zone for `*.loc`. All domains, subdomain (but not loc itself) will resolve
to `192.168.0.4`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.loc=192.168.0.4' \
    -t cytopia/bind
```

#### Wildcard TLD and reverse DNS entry

Let's add a wildcard zone for `*.loc`, and an A record for loc. All domains, subdomain and loc itself will resolve
to `192.168.0.4`. Additionally we specify that `host.loc` will be the reverse loopup for `192.168.0.4`.
```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.loc=192.168.0.4, loc=192.168.0.4' \
    -e DNS_PTR='192.168.0.4=host.loc' \
    -t cytopia/bind
```

#### Wildcard TLD and DNS resolver

Let's add a wildcard zone for `*.loc`. All its domains (but not the domain itself) will resolve
to `192.168.0.4`.

Let's also hook in our imaginary corporate DNS server into this container, so we can make use of
any already defined custom DNS entries by that nameserver.

* `loc` and all its subdomains (such as: `hostname.loc`) will point to `192.168.0.1`:
* Your corporate DNS servers are `10.0.15.1` and `10.0.15.2`

```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.loc=192.168.0.1' \
    -e DNS_FORWARDER=10.0.15.1,10.0.15.2 \
    -t cytopia/bind
```

#### Wildcard TLD, DNS resolver and extra hosts

* All subdomains of `loc` (but not `loc` itself) will point to `192.168.0.1`
* Your corporate DNS servers are `10.0.15.1` and `10.0.15.2`
* Also add two additional hosts with A and PTR records:
    - host5.loc -> 192.168.0.2
    - host5.org -> 192.168.0.3

```bash
$ docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.loc=192.168.0.1, host5.loc=192.168.0.2, host5.org=192.168.0.3' \
    -e DNS_PTR='192.168.0.2=host5.loc, 192.168.0.3=host5.org' \
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
    -e DNS_A='host1=192.168.0.11' \
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

Get support here

<table width="100%" style="width:100%; display:table;">
 <thead>
  <tr>
   <th width="25%" style="width:25%;"><h3><a target="_blank" href="https://gitter.im/devilbox/Lobby">Chat</a></h3></th>
   <th width="25%" style="width:25%;"><h3><a target="_blank" href="https://devilbox.discourse.group">Forum</a></h3></th>
  </tr>
 </thead>
 <tbody style="vertical-align: middle; text-align: center;">
  <tr>
   <td>
    <a target="_blank" href="https://gitter.im/devilbox/Lobby">
     <img title="Chat on Gitter" width="100" style="width:100px;" name="Chat on Gitter" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/gitter.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://devilbox.discourse.group">
     <img title="Devilbox Forums" width="100" style="width:100px;" name="Forum" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discourse.png" />
    </a>
   </td>
  </tr>
  <tr>
  <td><a target="_blank" href="https://gitter.im/devilbox/Lobby">gitter.im/devilbox</a></td>
  <td><a target="_blank" href="https://devilbox.discourse.group">devilbox.discourse.group</a></td>
  </tr>
 </tbody>
</table>



## License

**[MIT License](LICENSE.md)**

Copyright (c) 2022 [cytopia](https://github.com/cytopia)
