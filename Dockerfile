FROM tugboatqa/httpd:latest

ARG YQ_VERSION=v4.14.1
ARG YQ_BINARY=yq_linux_amd64
ARG YQ_SHASUM=dcc667e2da62f778996c9a99d4db3a95e4b6e500

ENV WP_PROXY_MAP_FILE=/var/lib/tugboat/.tugboat/wp-proxy.yml
ENV WP_PROXY_PREFIX=/usr/local/wp-proxy

COPY dist ${WP_PROXY_PREFIX}

RUN set -x \
  && apt-get update \
  && apt-get --quiet --yes install gettext-base wget \
  && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/local/bin/yq \
  && shasum /usr/local/bin/yq | grep -q ${YQ_SHASUM} \
  && chmod +x /usr/local/bin/yq \
  && ln -snf ${WP_PROXY_PREFIX}/wp-proxy-setup.sh /usr/local/bin/wp-proxy-setup.sh \
  && cp ${WP_PROXY_PREFIX}/run /etc/service/httpd/run \
  && echo "Include ${WP_PROXY_PREFIX}/wp-proxy.conf" >> "$HTTPD_PREFIX/conf/httpd.conf" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
