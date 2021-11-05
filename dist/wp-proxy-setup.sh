#!/usr/bin/env bash
set -eo pipefail

exitmsg() {
	echo "$1" 1>&2;
	exit 0
}

# Check that yq is available.
hash yq 2>/dev/null || exitmsg "yq not found."
# Check that $WP_PROXY_MAP_FILE is set.
test -n "$WP_PROXY_MAP_FILE" || exitmsg "You must declare the path to the yaml map file in a WP_PROXY_MAP_FILE environment variable."
# Check that the file exists and is readable.
test -r "$WP_PROXY_MAP_FILE" || exitmsg "The yaml map file '${WP_PROXY_MAP_FILE}' does not exist or is not readable."
# Validate the proxy file is yaml.
yq eval 'true' "$WP_PROXY_MAP_FILE" > /dev/null || exitmsg "The file '${WP_PROXY_MAP_FILE}' is not valid yaml."
# If we can't find the conf.d directory, exit.
test -d "${WP_PROXY_PREFIX}/conf.d" || exitmsg "The directory '${WP_PROXY_PREFIX}/conf.d' does not exist."

rm -f "${WP_PROXY_PREFIX}"/conf.d/*.vhost

default_backend_uri=$(yq eval '.backend_uri' "$WP_PROXY_MAP_FILE" | sed -e 's@/*$@@')

(
	for key in $(yq eval '.sites | keys | .[]' "$WP_PROXY_MAP_FILE"); do
		source_host=$key
		if yq --exit-status eval ".sites.\"${key}\".host" "$WP_PROXY_MAP_FILE" >/dev/null 2>&1; then
			source_host=$(yq eval ".sites.\"${key}\".host" "$WP_PROXY_MAP_FILE")
		fi
		export source_host

		backend_uri=$default_backend_uri
		if yq --exit-status eval ".sites.\"${key}\".backend_uri" "$WP_PROXY_MAP_FILE" >/dev/null 2>&1; then
			backend_uri=$(yq eval ".sites.\"${key}\".backend_uri" "$WP_PROXY_MAP_FILE" | sed -e 's@/*$@@')
		fi
		export backend_uri

		source_scheme=https
		if yq --exit-status eval ".sites.\"${key}\".scheme" "$WP_PROXY_MAP_FILE" >/dev/null 2>&1; then
			source_scheme=$(yq eval ".sites.\"${key}\".scheme" "$WP_PROXY_MAP_FILE")
		fi
		export source_scheme

		proxy_scheme=https
		if yq --exit-status eval ".sites.\"${key}\".proxy_scheme" "$WP_PROXY_MAP_FILE" >/dev/null 2>&1; then
			proxy_scheme=$(yq eval ".sites.\"${key}\".proxy_scheme" "$WP_PROXY_MAP_FILE")
		fi
		export proxy_scheme

		proxy_host=$(yq eval ".sites.\"${key}\"" "$WP_PROXY_MAP_FILE")
		if yq --exit-status eval ".sites.\"${key}\".proxy_host" "$WP_PROXY_MAP_FILE" >/dev/null 2>&1; then
			proxy_host=$(yq eval ".sites.\"${key}\".proxy_host" "$WP_PROXY_MAP_FILE")
		fi
		export proxy_host

		envsubst < "${WP_PROXY_PREFIX}"/vhost.tpl.conf > "${WP_PROXY_PREFIX}"/conf.d/"${source_host}".vhost
	done
)
