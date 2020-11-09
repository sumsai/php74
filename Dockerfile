ARG PHP_VERSION
FROM php:7.4-fpm-alpine

ARG TZ
ARG PHP_EXTENSIONS
ARG CONTAINER_PACKAGE_URL


COPY ./extensions /tmp/extensions
WORKDIR /tmp/extensions


RUN if [ "mirrors.aliyun.com" != "" ]; then \
        sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories; \
    fi


RUN if [ "pdo_mysql,pcntl,posix,mysqli,mbstring,gd,curl,opcache,redis,swoole,inotify" != "" ]; then \
        apk add --no-cache autoconf g++ libtool make curl-dev linux-headers; \
    fi


RUN chmod +x install.sh && sh install.sh && rm -rf /tmp/extensions


RUN apk --no-cache add tzdata \
    && cp "/usr/share/zoneinfo/Asia/Shanghai" /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone


# Fix: https://github.com/docker-library/php/issues/240
RUN apk add gnu-libiconv --no-cache --repository http://mirrors.aliyun.com/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install composer and change it's cache home
RUN curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x /usr/bin/composer
ENV COMPOSER_HOME=/tmp/composer
#安装 inotify
pecl install inotify
#更新源，安装yasm ffmpeg
RUN apk update
RUN apk add yasm && apk add ffmpeg
# php image's www-data user uid & gid are 82, change them to 1000 (primary user)
RUN apk --no-cache add shadow && usermod -u 1000 www-data && groupmod -g 1000 www-data

WORKDIR /www
