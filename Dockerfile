FROM --platform=${TARGETPLATFORM:-linux/amd64} crazymax/alpine-s6:3.12

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

LABEL maintainer="CrazyMax" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/anonaddy/docker" \
  org.opencontainers.image.source="https://github.com/anonaddy/docker" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="CrazyMax" \
  org.opencontainers.image.title="AnonAddy" \
  org.opencontainers.image.description="AnonAddy - Anonymous Email Forwarding" \
  org.opencontainers.image.licenses="MIT"

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    curl \
    gnupg \
    gpgme \
    imagemagick \
    libgd \
    libressl \
    mysql-client \
    nginx \
    php7 \
    php7-cli \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-fileinfo \
    php7-fpm \
    php7-gd \
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
    php7-session \
    php7-simplexml \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-zip \
    php7-zlib \
    postfix \
    postfix-mysql \
    shadow \
    su-exec \
    tar \
    tzdata \
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
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/cache/apk/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"\
  ANONADDY_VERSION="v0.2.13" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN apk --update --no-cache add -t build-dependencies \
    git \
    nodejs \
    npm \
  && node --version \
  && npm -- version \
  && mkdir -p /var/www \
  && addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git clone --branch ${ANONADDY_VERSION} https://github.com/anonaddy/anonaddy /var/www/anonaddy \
  && cd /var/www/anonaddy \
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi \
  && npm config set unsafe-perm true \
  && npm install --global cross-env \
  && npm install \
  && npm run production \
  && chown -R nobody.nogroup /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer /root/.config /root/.npm /var/cache/apk/* /var/www/anonaddy/node_modules /tmp/*

COPY rootfs /

RUN chmod a+x /usr/local/bin/*

EXPOSE 25 8000
WORKDIR /var/www/anonaddy
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
