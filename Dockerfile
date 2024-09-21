FROM tugboatqa/httpd:latest

ARG NODEJS_VERSION

ENV WP_PROXY_MAP_FILE=/var/lib/tugboat/.tugboat/wp-proxy.yml
ENV WP_PROXY_DIR=/usr/local/wp-proxy

COPY dist ${WP_PROXY_DIR}

RUN set -x \
  && curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
  && apt-get --quiet --yes install nodejs \
  && npm --prefix ${WP_PROXY_DIR} ci \
  && cp ${WP_PROXY_DIR}/run /etc/service/httpd/run \
  && echo "Include ${WP_PROXY_DIR}/wp-proxy.conf" >> "$HTTPD_PREFIX/conf/httpd.conf" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
