# WordPress Proxy

**Built by [Tugboat QA](https://www.tugboat.qa) 🚢**

This docker image is intended to be used as a proxy in front of a WordPress
site, to avoid needing to run `wp search-replace`, which on larger sites or
networked sites can be quite time-consuming.

This proxy is intended for use with [Tugboat QA](https://www.tugboat.qa), but
should be usable in other Docker tools, such as Docker Compose, Lando, etc.

This probably goes without saying but this image is…

**💀 NOT for use in a production environment. 💀**

## Usage

1. Create a yaml file that contains the map of sites you'd like to proxy.
```yaml
backend_uri: http://php
sites:
  # To do a simple map and use the defaults, specify the production host on the
  # left as the key, and the proxied host name on the right as the value. This
  # would be equivalent to executing the following 'wp search-replace' command:
  #     wp search-replace www.mister-rogers.com mister-rogers.local
  www.mister-rogers.com: mister-rogers.local

  # Verbose syntax--you can declare everything explicitly:
  kingfriday.com:
    # The scheme of the production site. Defaults to https.
    scheme: http
    # Without setting this explicitly, kingfriday.com would have been used.
    host: www.kingfriday.com
    proxy_host: kingfriday-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa
    # The scheme of the proxy. Defaults to https.
    proxy_scheme: http
    # You can also override the top level backend_uri for a single site.
    backend_uri: http://nginx
```

- `backend_uri`: The proxied service that is serving the wordpress site.
- `sites`: A keyed list of sites. The key will be used as the `host` unless it is explicitly set below.
- `host`: The production host that is stored in the database, e.g. `www.example.com`.
- `scheme`: The http scheme of the real site, i.e. `https` or `http`. Defaults to `https`.
- `proxy_host`: The host the proxy will serve the site from, e.g. `localhost`.
- `proxy_scheme`: The http scheme of the proxied site, i.e. `https` or `http`. Defaults to `https`.

2. Save this file in your repo at `.tugboat/wp-proxy.yml`. Or define a custom
environment variable with the path to the file:

`WP_PROXY_MAP_FILE=path/to/wp-proxy.yml`

When the container starts, Apache will start and read in that file and set up
the necessary vhosts.

## Sample Tugboat config.yml

Here's an example config.yml if you're using this in
[Tugboat](https://www.tugboat.qa):

```yaml
services:
  wp-proxy:
    default: true
    image: q0rban/wp-proxy
    depends: php
  php:
    checkout: true
    image: tugboatqa/php:7.4-apache
    depends: mysql
    commands:
      ...
```

Since the PHP service name is `php`, the `backend_uri` in your `wp-proxy.yml`
would be `http://php`.

If the production URL for this site that's stored in the database is
`https://www.mister-rogers.com`, then you might have the following
`.tugboat/wp-proxy.yml`:

```yaml
backend_uri: http://php
sites:
  www.mister-rogers.com: ${TUGBOAT_DEFAULT_SERVICE_URL_HOST}
```

### Networked / multisite WordPress

If you're dealing with a large networked site, you would want to use Tugboat's
[`aliases`](https://docs.tugboat.qa/reference/tugboat-configuration/#aliases).
For example:

```yaml
services:
  wp-proxy:
    default: true
    image: q0rban/wp-proxy
    depends: php
    aliases:
      - mister-rogers
      - lady-aberlin
      - neighbor-aber
      - handyman-negri
  php:
    ...
```

Then you might have the following `.tugboat/wp-proxy.yml`:

```yaml
backend_uri: http://php
sites:
  www.mister-rogers.com: mister-rogers-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa
  www.lady-aberlin.com: lady-aberlin-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa
  www.neighbor-aber.com: neighbor-aber-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa
  www.handyman-negri.com: handyman-negri-${TUGBOAT_DEFAULT_SERVICE_TOKEN}.tugboat.qa
```
