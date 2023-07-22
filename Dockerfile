# syntax=docker/dockerfile:1

ARG ANONADDY_VERSION=0.14.1

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6:3.18-2.2.0.3

COPY --from=yasu / /
RUN apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    gnupg \
    gpgme \
    imagemagick \
    libgd \
    mysql-client \
    nginx \
    openssl \
    php81 \
    php81-cli \
    php81-ctype \
    php81-curl \
    php81-dom \
    php81-fileinfo \
    php81-fpm \
    php81-gd \
    php81-gmp \
    php81-iconv \
    php81-intl \
    php81-json \
    php81-opcache \
    php81-openssl \
    php81-pdo \
    php81-pdo_mysql \
    php81-pecl-imagick \
    php81-pecl-mailparse \
    php81-phar \
    php81-redis \
    php81-session \
    php81-simplexml \
    php81-sodium \
    php81-tokenizer \
    php81-xml \
    php81-xmlreader \
    php81-xmlwriter \
    php81-zip \
    php81-zlib \
    postfix \
    postfix-mysql \
    rspamd \
    rspamd-controller \
    rspamd-proxy \
    shadow \
    tar \
    tzdata \
  && cp /etc/postfix/master.cf /etc/postfix/master.cf.orig \
  && cp /etc/postfix/main.cf /etc/postfix/main.cf.orig \
  && apk --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    libtool \
    pcre-dev \
    php81-dev \
    php81-pear \
  && pecl81 install gnupg \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/www/*

ARG ANONADDY_VERSION
ENV ANONADDY_VERSION=$ANONADDY_VERSION \
  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

WORKDIR /var/www/anonaddy
RUN apk --no-cache add -t build-dependencies \
    git \
    nodejs \
    npm \
  && node --version \
  && npm --version \
  && addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && addgroup anonaddy mail \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git config --global --add safe.directory /var/www/anonaddy \
  && git init . && git remote add origin "https://github.com/anonaddy/anonaddy.git" \
  && git fetch --depth 1 origin "v${ANONADDY_VERSION}" && git checkout -q FETCH_HEAD \
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi \
  && chown -R anonaddy. /var/www/anonaddy \
  && npm install --global cross-env \
  && npm ci --ignore-scripts --only=production \
  && npm run production \
  && npm prune --production \
  && chown -R nobody.nogroup /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer \
    /root/.config \
    /root/.npm \
    /var/www/anonaddy/.git \
    /var/www/anonaddy/node_modules \
    /tmp/*

COPY rootfs /

EXPOSE 25 8000 11334
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
