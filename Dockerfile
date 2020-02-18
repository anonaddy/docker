# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.10

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="anonaddy" \
  org.label-schema.description="AnonAddy - Anonymous Email Forwarding" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-anonaddy" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-anonaddy" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

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
  && S6_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "amd64"   ;; \
    "linux/arm/v6")  echo "arm"     ;; \
    "linux/arm/v7")  echo "armhf"   ;; \
    "linux/arm64")   echo "aarch64" ;; \
    "linux/386")     echo "x86"     ;; \
    "linux/ppc64le") echo "ppc64le" ;; \
    "linux/s390x")   echo "s390x"   ;; \
    *)               echo ""        ;; esac) \
  && echo "S6_ARCH=$S6_ARCH" \
  && wget -q "https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6_ARCH}.tar.gz" -qO "/tmp/s6-overlay-amd64.tar.gz" \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
  && s6-echo "s6-overlay installed" \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/cache/apk/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"\
  ANONADDY_VERSION="v0.2.3" \
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
  && mkdir -p /data /var/run/nginx /var/run/php-fpm \
  && chown -R anonaddy. /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer /root/.config /root/.npm /var/cache/apk/* /var/www/anonaddy/node_modules /tmp/*

COPY rootfs /

EXPOSE 2500 8000
WORKDIR /var/www/anonaddy
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
