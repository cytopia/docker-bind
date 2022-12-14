# Bind Docker

[![Tag](https://img.shields.io/github/tag/cytopia/docker-bind.svg)](https://github.com/cytopia/docker-bind/releases)
[![lint](https://github.com/cytopia/docker-bind/workflows/lint/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Alint)
[![build](https://github.com/cytopia/docker-bind/workflows/build/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Abuild)
[![nightly](https://github.com/cytopia/docker-bind/workflows/nightly/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Anightly)
[![License](https://img.shields.io/badge/license-MIT-%233DA639.svg)](https://opensource.org/licenses/MIT)

[![Discord](https://img.shields.io/discord/1051541389256704091?color=8c9eff&label=Discord&logo=discord)](https://discord.gg/2wP3V6kBj4)
[![Discourse](https://img.shields.io/discourse/https/devilbox.discourse.group/status.svg?colorB=%234CB697&label=Discourse&logo=discourse)](https://devilbox.discourse.group)

**Available Architectures:**  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le`

[![](https://img.shields.io/docker/pulls/cytopia/bind.svg)](https://hub.docker.com/r/cytopia/bind)

Bind caching DNS server based on Alpine and Debian slim with support for DNS forwarders, infinite wild-card DNS, infinite extra hosts, reverse DNS, DNSSEC timing settings and others.

| Bind Project        | Reference Implementation |
|:-------------------:|:------------------------:|
| <a title="Docker Bind" href="https://github.com/cytopia/docker-bind" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/06/png/banner_256_trans.png" /></a> | <a title="Devilbox" href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |
| [Bind DNS Server](https://github.com/cytopia/docker-bind) | The [Devilbox](https://github.com/cytopia/devilbox) |


## 🐋 Available Docker tags

[![](https://img.shields.io/docker/pulls/cytopia/bind.svg)](https://hub.docker.com/r/cytopia/bind)

[`latest`][tag_latest] [`stable`][tag_stable] [`alpine`][tag_alpine]
```bash
docker pull cytopia/bind
```

[tag_latest]: Dockerfiles/Dockerfile.latest
[tag_stable]: Dockerfiles/Dockerfile.stable
[tag_alpine]: Dockerfiles/Dockerfile.alpine

#### Rolling Releases

The following Docker image tags are rolling releases and are built and updated every night.

[![nightly](https://github.com/cytopia/docker-bind/workflows/nightly/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Anightly)

| Docker Tag                       | Git Ref      | Available Architectures                                                      |
|----------------------------------|--------------|------------------------------------------------------------------------------|
| **[`latest`][tag_latest]**       | master       | `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |
| [`stable`][tag_stable]           | master       | `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |
| [`alpine`][tag_alpine]           | master       | `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |

#### Point in time releases

The following Docker image tags are built once and can be used for reproducible builds. Its version never changes so you will have to update tags in your pipelines from time to time in order to stay up-to-date.

[![build](https://github.com/cytopia/docker-bind/workflows/build/badge.svg)](https://github.com/cytopia/docker-bind/actions?query=workflow%3Abuild)

| Docker Tag                       | Git Ref      | Available Architectures                                                       |
|----------------------------------|--------------|-------------------------------------------------------------------------------|
| **[`<tag>`][tag_latest]**        | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |
| [`<tag>-stable`][tag_stable]     | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |
| [`<tag>-alpine`][tag_alpine]     | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6`, `ppc64le`, `s390x`, `mips64le` |

> 🛈 Where `<tag>` refers to the chosen git tag from this repository.<br/>
> ⚠ **Warning:** The latest available git tag is also build every night and considered a rolling tag.


----

**Table of Contents**

1. [Environment variables](#-environmental-variables)
    1. [Required environment variables](#required-environment-variables)
    2. [Optional environment variables](#optional-environment-variables)
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
2. [Volumes](#-volumes)
3. [Exposed Ports](#-exposed-ports)
4. [Examples](#-examples)
    1. [Default run](#default-run)
    2. [Wildcard domain](#wildcard-domain)
    3. [Wildcard subdomain](#wildcard-subdomain)
    4. [Wildcard TLD](#wildcard-tld)
    5. [Wildcard TLD and reverse DNS entry](#wildcard-tld-and-reverse-dns-entry)
    6. [Wildcard TLD and DNS resolver](#wildcard-tld-and-dns-resolver)
    7. [Wildcard TLD, DNS resolver and extra hosts](#wildcard-tld-dns-resolver-and-extra-hosts)
    8. [Extra hosts, DNS resolver, allow query, and allow recursion](#extra-hosts-dns-resolver-allow-query-and-allow-recursion)
5. [Host integration](#-host-integration)
6. [Sister Projects](#-sister-projects)
7. [Community](#-community)
8. [Articles](#-articles)
9. [Credits](#-credits)
10. [Maintainer](#-maintainer)
11. [License](#-license)

---

## ∑ Environment Variables

### Required environment variables

- None

### Optional environment variables

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
| `TTL_TIME`         | int    | `3600`    | (time in seconds) see [bind ttl](http://www.zytrax.com/books/dns/apa/ttl.html) and [bind soa](http://www.zytrax.com/books/dns/ch8/soa.html)|
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

## 📂 Volumes

- None


## 🖧 Exposed Ports

| Docker | Description  |
|--------|--------------|
| 53     | DNS Resolver |
| 53/udp | DNS Resolver |


## 💡 Examples

The following examples start the container in foreground and use `-i`, so you can easily stop
it by pressing `<Ctrl> + c`. For a production run, you would rather use `-d` to send it to the
background.

#### Default run

Exposing the port is mandatory if you want to use it for your host operating system.
```bash
docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -t cytopia/bind
```

#### Wildcard domain

Let's add a wildcard zone for `*.example.com`. All subdomains (but not example.com itself) will resolve
to `192.168.0.1`.
```bash
docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard subdomain

Let's add a wildcard zone for `*.aws.example.com`. All subdomains (but not aws.example.com itself) will resolve
to `192.168.0.1`.
```bash
docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.aws.example.com=192.168.0.1' \
    -t cytopia/bind
```

#### Wildcard TLD

Let's add a wildcard zone for `*.loc`. All domains, subdomain (but not loc itself) will resolve
to `192.168.0.4`.
```bash
docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='*.loc=192.168.0.4' \
    -t cytopia/bind
```

#### Wildcard TLD and reverse DNS entry

Let's add a wildcard zone for `*.loc`, and an A record for loc. All domains, subdomain and loc itself will resolve
to `192.168.0.4`. Additionally we specify that `host.loc` will be the reverse loopup for `192.168.0.4`.
```bash
docker run -i \
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
docker run -i \
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
docker run -i \
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
docker run -i \
    -p 53:53/tcp \
    -p 53:53/udp \
    -e DNS_A='host1=192.168.0.11' \
    -e DNS_FORWARDER=8.8.8.8,8.8.4.4 \
    -e ALLOW_QUERY=192.168.0.0/24,127.0.0.1 \
    -e ALLOW_RECURSION=192.168.0.0/24,127.0.0.1 \
    -t cytopia/bind
```

## 🔧 Host integration

You can run this DNS container locally without having to worry to affect any corporate DNS server
that are given to you via DHCP.

Add the following line to the very beginning to `/etc/dhcp/dhclient.conf`:
```bash
prepend domain-name-servers 127.0.0.1;
```
Restart network manager
```bash
# Via service command
sudo service network-manager restart

# Or the systemd way
sudo systemctl restart network-manager
```

This will make sure that whenever your `/etc/resolv.conf` is deployed, you will have `127.0.0.1`
as the first entry and also make use of any other DNS server which are deployed via the LAN's DHCP server.

If `cytopia/bind` is not running, it does not affect the name resolution, because you will still
have entries in `/etc/resolv.conf`.


## 🖤 Sister Projects

Show some love for the following sister projects.

<table>
 <tr>
  <th>🖤 Project</th>
  <th>🐱 GitHub</th>
  <th>🐋 DockerHub</th>
 </tr>
 <tr>
  <td><a title="Devilbox" href="https://github.com/cytopia/devilbox" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/cytopia/devilbox"><code>Devilbox</code></a></td>
  <td></td>
 </tr>
 <tr>
  <td><a title="Docker PHP-FMP" href="https://github.com/devilbox/docker-php-fpm" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/02/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-php-fpm"><code>docker-php-fpm</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/php-fpm"><code>devilbox/php-fpm</code></a></td>
 </tr>
 <tr>
  <td><a title="Docker PHP-FMP-Community" href="https://github.com/devilbox/docker-php-fpm-community" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/03/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-php-fpm-community"><code>docker-php-fpm-community</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/php-fpm-community"><code>devilbox/php-fpm-community</code></a></td>
 </tr>
 <tr>
  <td><a title="Docker MySQL" href="https://github.com/devilbox/docker-mysql" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/04/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-mysql"><code>docker-mysql</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/mysql"><code>devilbox/mysql</code></a></td>
 </tr>
 <tr>
  <td><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/05/png/banner_256_trans.png" /></td>
  <td>
   <a href="https://github.com/devilbox/docker-apache-2.2"><code>docker-apache-2.2</code></a><br/>
   <a href="https://github.com/devilbox/docker-apache-2.4"><code>docker-apache-2.4</code></a><br/>
   <a href="https://github.com/devilbox/docker-nginx-stable"><code>docker-nginx-stable</code></a><br/>
   <a href="https://github.com/devilbox/docker-nginx-mainline"><code>docker-nginx-mainline</code></a>
  </td>
  <td>
   <a href="https://hub.docker.com/r/devilbox/apache-2.2"><code>devilbox/apache-2.2</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/apache-2.4"><code>devilbox/apache-2.4</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/nginx-stable"><code>devilbox/nginx-stable</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/nginx-mainline"><code>devilbox/nginx-mainline</code></a>
  </td>
 <tr>
  <td><a title="Bind DNS Server" href="https://github.com/cytopia/docker-bind" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/06/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/cytopia/docker-bind"><code>docker-bind</code></a></td>
  <td><a href="https://hub.docker.com/r/cytopia/bind"><code>cytopia/bind</code></a></td>
 </tr>
 </tr>
</table>


## 👫 Community

In case you seek help, go and visit the community pages.

<table width="100%" style="width:100%; display:table;">
 <thead>
  <tr>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.readthedocs.io">📘 Documentation</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://discord.gg/2wP3V6kBj4">🎮 Discord</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.discourse.group">🗪 Forum</a></h3></th>
  </tr>
 </thead>
 <tbody style="vertical-align: middle; text-align: center;">
  <tr>
   <td>
    <a target="_blank" href="https://devilbox.readthedocs.io">
     <img title="Documentation" name="Documentation" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/readthedocs.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://discord.gg/2wP3V6kBj4">
     <img title="Chat on Discord" name="Chat on Discord" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discord.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://devilbox.discourse.group">
     <img title="Devilbox Forums" name="Forum" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discourse.png" />
    </a>
   </td>
  </tr>
  <tr>
  <td><a target="_blank" href="https://devilbox.readthedocs.io">devilbox.readthedocs.io</a></td>
  <td><a target="_blank" href="https://discord.gg/2wP3V6kBj4">discord/devilbox</a></td>
  <td><a target="_blank" href="https://devilbox.discourse.group">devilbox.discourse.group</a></td>
  </tr>
 </tbody>
</table>


## 📜 Articles

* [Serving Bind DNS in Kubernetes](https://medium.com/swlh/serving-bind-dns-in-kubernetes-8639fce37448)


## ❤️ Credits

Thanks for contributing 🖤

- **[@atomicbaum1](https://github.com/atomicbaum1)**
- **[@ericp-mrel](https://github.com/ericp-mrel)**
- **[@Zighy](https://github.com/Zighy)**


## 🧘 Maintainer

**[@cytopia](https://github.com/cytopia)**

I try to keep up with literally **over 100 projects** besides a full-time job.
If my work is making your life easier, consider contributing. 🖤

* [GitHub Sponsorship](https://github.com/sponsors/cytopia)
* [Patreon](https://www.patreon.com/devilbox)
* [Open Collective](https://opencollective.com/devilbox)

**Findme:**
**🐱** [cytopia](https://github.com/cytopia) / [devilbox](https://github.com/devilbox) |
**🐋** [cytopia](https://hub.docker.com/r/cytopia/) / [devilbox](https://hub.docker.com/r/devilbox/) |
**🐦** [everythingcli](https://twitter.com/everythingcli) / [devilbox](https://twitter.com/devilbox) |
**📖** [everythingcli.org](http://www.everythingcli.org/)

**Contrib:** PyPI: [cytopia](https://pypi.org/user/cytopia/) **·**
Terraform: [cytopia](https://registry.terraform.io/namespaces/cytopia) **·**
Ansible: [cytopia](https://galaxy.ansible.com/cytopia)


## 🗎 License

**[MIT License](LICENSE.md)**

Copyright (c) 2022 [cytopia](https://github.com/cytopia)
