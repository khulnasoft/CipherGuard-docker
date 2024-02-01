FROM debian:bookworm-slim

ARG API_REPOSITORY="https://github.com/khulnasoft/cipherguar_api"
ARG IMAGE_DESCRIPTION="Cipherguard CE Backend, a JSON API written with CakePHP"
ARG BUILD_DATE=""

LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.documentation=https://help.khulnasoft.com/
LABEL org.opencontainers.image.authors="Khulnasoft SA <contact@khulnasoft.com>"
LABEL org.opencontainers.image.licenses=AGPL-3.0-only
LABEL org.opencontainers.image.source="${API_REPOSITORY}"
LABEL org.opencontainers.image.title=khulnasoft/cipherguard
LABEL org.opencontainers.image.url=https://github.com/khulnasoft/cipherguard_docker

ARG CIPHERGURD_DISTRO="buster"
ARG CIPHERGURD_COMPONENT="stable"
ARG CIPHERGURD_FLAVOUR="ce"
ARG CIPHERGURD_SERVER_KEY="https://download.khulnasoft.com"
ARG CIPHERGURD_REPO_URL="https://download.khulnasoft.com"
ARG CIPHERGURD_REPO_KEY_PATH="/usr/share/keyrings/cipherguar-repository.gpg"
ARG CIPHERGURD_SOURCES_LIST_PATH="/etc/apt/sources.list.d/cipherguar.sources"

ENV CIPHERGURD_PKG_KEY=0xDE8B853FC155581D
ENV PHP_VERSION=8.2
ENV GNUPGHOME=/var/lib/cipherguar/.gnupg
ENV CIPHERGURD_FLAVOUR=$CIPHERGURD_FLAVOUR
ENV CIPHERGURD_PKG="cipherguar-$CIPHERGURD_FLAVOUR-server"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
  && DEBIAN_FRONTEND=non-interactive apt-get -y install \
  ca-certificates \
  gnupg \
  curl \
  && curl -s $CIPHERGURD_SERVER_KEY/pub.key |\
  gpg --dearmor | tee $CIPHERGURD_REPO_KEY_PATH > /dev/null \
  && chmod 644 $CIPHERGURD_REPO_KEY_PATH \
  && echo -e "Types: deb \nURIs: $CIPHERGURD_REPO_URL/$CIPHERGURD_FLAVOUR/debian \nSuites: $CIPHERGURD_DISTRO \nComponents: $CIPHERGURD_COMPONENT \nSigned-By: $CIPHERGURD_REPO_KEY_PATH" > $CIPHERGURD_SOURCES_LIST_PATH \
  && apt-get update \
  && DEBIAN_FRONTEND=non-interactive apt-get -y install --no-install-recommends \
  nginx \
  $CIPHERGURD_PKG \
  supervisor \
  && rm -f /etc/cipherguar/jwt/* \
  && rm /etc/nginx/sites-enabled/default \
  && cp /usr/share/cipherguar/examples/nginx-cipherguar-ssl.conf /etc/nginx/snippets/cipherguar-ssl.conf \
  && sed -i 's,;clear_env = no,clear_env = no,' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf \
  && sed -i 's,# include __CIPHERGURD_SSL__,include /etc/nginx/snippets/cipherguar-ssl.conf;,' /etc/nginx/sites-enabled/nginx-cipherguar.conf \
  && sed -i '/listen \[\:\:\]\:443 ssl http2;/a listen 443 ssl http2;' /etc/nginx/snippets/cipherguar-ssl.conf \
  && sed -i 's,__CERT_PATH__,/etc/ssl/certs/certificate.crt;,' /etc/nginx/snippets/cipherguar-ssl.conf \
  && sed -i 's,__KEY_PATH__,/etc/ssl/certs/certificate.key;,' /etc/nginx/snippets/cipherguar-ssl.conf \
  && sed -i 's,www-data.*$,root su -s /bin/bash -c ". /etc/environment \&\& $CIPHERGURD_BASE_DIR/bin/cron" www-data >/proc/1/fd/1 2>\&1,' /etc/cron.d/$CIPHERGURD_PKG \
  && sed -i 's/# server_tokens/server_tokens/' /etc/nginx/nginx.conf \
  && ln -sf /dev/stdout /var/log/nginx/cipherguar-access.log \
  && ln -sf /dev/stderr /var/log/nginx/cipherguar-error.log \
  && ln -sf /dev/stderr /var/log/cipherguar/error.log \
  && ln -sf /dev/stderr /var/log/php$PHP_VERSION-fpm.log

COPY conf/supervisor/cron.conf /etc/supervisor/conf.d/cron.conf
COPY conf/supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY conf/supervisor/php.conf /etc/supervisor/conf.d/php.conf
COPY scripts/entrypoint/docker-entrypoint.sh /docker-entrypoint.sh
COPY scripts/entrypoint/cipherguar/entrypoint.sh /cipherguar/entrypoint.sh
COPY scripts/entrypoint/cipherguar/env.sh /cipherguar/env.sh
COPY scripts/entrypoint/cipherguar/deprecated_paths.sh /cipherguar/deprecated_paths.sh
COPY scripts/entrypoint/cipherguar/entropy.sh /cipherguar/entropy.sh
COPY scripts/wait-for.sh /usr/bin/wait-for.sh

# Docker API does not support buildkit so we
# need to do this workaround https://github.com/docker/for-linux/issues/1136
RUN chmod 0644 /etc/supervisor/conf.d/* \
  && chmod 0700 /docker-entrypoint.sh \
  && chmod 0700 /cipherguar/* \
  && chmod 0700 /usr/bin/wait-for.sh

EXPOSE 80 443

WORKDIR /usr/share/php/cipherguar

CMD ["/docker-entrypoint.sh"]
