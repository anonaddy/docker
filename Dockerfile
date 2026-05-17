# syntax=docker/dockerfile:1

ARG ANONADDY_VERSION=1.6.1
ARG ALPINE_VERSION=3.23

FROM tianon/gosu:latest AS gosu

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3
COPY --from=gosu /gosu /usr/local/bin/
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
    php84 \
    php84-cli \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-fileinfo \
    php84-fpm \
    php84-gd \
    php84-gmp \
    php84-iconv \
    php84-intl \
    php84-json \
    php84-mbstring \
    php84-opcache \
    php84-openssl \
    php84-pdo \
    php84-pdo_mysql \
    php84-phar \
    php84-redis \
    php84-session \
    php84-simplexml \
    php84-sodium \
    php84-tokenizer \
    php84-xml \
    php84-xmlreader \
    php84-xmlwriter \
    php84-zip \
    php84-zlib \
    postfix \
    postfix-mysql \
    rspamd \
    rspamd-controller \
    rspamd-proxy \
    shadow \
    tar \
    tzdata \
    cyrus-sasl \
    cyrus-sasl-login \
  && cp /etc/postfix/master.cf /etc/postfix/master.cf.orig \
  && cp /etc/postfix/main.cf /etc/postfix/main.cf.orig \
  && apk --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    imagemagick-dev \
    libtool \
    pcre-dev \
    php84-dev \
    php84-pear \
  && pecl84 install gnupg \
  && echo "extension=gnupg.so" > /etc/php84/conf.d/60_gnupg.ini \
  && pecl84 install mailparse \
  && echo "extension=mailparse.so" > /etc/php84/conf.d/60_mailparse.ini \
  && pecl84 install imagick \
  && echo "extension=imagick.so" > /etc/php84/conf.d/50_imagick.ini \
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
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi --ignore-platform-req=php-64bit \
  && chown -R anonaddy:anonaddy /var/www/anonaddy \
  && npm ci --ignore-scripts --no-audit --no-fund \
  && APP_URL=https://addy-sh.test npm run production \
  && chown -R nobody:nogroup /var/www/anonaddy \
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
