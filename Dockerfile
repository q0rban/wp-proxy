FROM tugboatqa/httpd:latest

ENV WP_PROXY_PREFIX=/usr/local/wp-proxy
ENV YQ_VERSION=v4.14.1
ENV YQ_BINARY=yq_linux_arm64

COPY dist ${WP_PROXY_PREFIX}

RUN apt-get update \
  && apt-get --quiet --yes install gettext-base wget \
  && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq \
  && shasum /usr/bin/yq | grep -q b01750ecc56b739b61d641a2a4797aa96ba8c8f4 \
  && chmod +x /usr/bin/yq \
  && ln -snf ${WP_PROXY_PREFIX}/wp-proxy-setup.sh /usr/local/bin/wp-proxy-setup.sh \
  && cp ${WP_PROXY_PREFIX}/run /etc/service/httpd/run \
  && echo "Include ${WP_PROXY_PREFIX}/wp-proxy.conf" >> "$HTTPD_PREFIX/conf/httpd.conf" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
