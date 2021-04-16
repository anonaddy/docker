ARG ANONADDY_VERSION=0.7.2

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6:3.13-2.2.0.3
LABEL maintainer="CrazyMax"

COPY --from=yasu / /
RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    curl \
    gnupg \
    gpgme \
    imagemagick \
    libgd \
    mysql-client \
    nginx \
    opendkim \
    opendkim-libs \
    opendkim-utils \
    openssl \
    php7 \
    php7-cli \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
    php7-gmp \
    php7-iconv \
    php7-imagick \
    php7-intl \
    php7-json \
    php7-mailparse \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-phar \
    php7-redis \
    php7-session \
    php7-simplexml \
    php7-sodium \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
    postfix \
    postfix-mysql \
    shadow \
    tar \
    tzdata \
  && apk --update-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing add \
    opendmarc \
    opendmarc-libs \
  && apk --update --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    libtool \
    pcre-dev \
    php7-dev \
    php7-pear \
  && pecl install gnupg \
  && addgroup opendkim postfix \
  && addgroup postfix opendkim \
  && addgroup opendmarc postfix \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/cache/apk/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG ANONADDY_VERSION
WORKDIR /var/www/anonaddy
RUN apk --update --no-cache add -t build-dependencies \
    git \
    nodejs \
    npm \
  && node --version \
  && npm -- version \
  && addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && addgroup anonaddy opendkim \
  && addgroup anonaddy mail \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git clone --branch v${ANONADDY_VERSION} https://github.com/anonaddy/anonaddy . \
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi \
  && npm config set unsafe-perm true \
  && npm install --global cross-env \
  && npm install \
  && npm run production \
  && chown -R nobody.nogroup /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer \
    /root/.config \
    /root/.npm \
    /var/cache/apk/* \
    /var/www/anonaddy/.git \
    /var/www/anonaddy/node_modules \
    /tmp/*

COPY rootfs /

EXPOSE 25 8000
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
