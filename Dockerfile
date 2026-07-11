FROM wordpress:7.0.1-php8.4-apache

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        imagemagick \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmagickwand-dev \
        libpq-dev \
        libpng-dev \
        libwebp-dev \
        unzip; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" exif gd pdo_pgsql pgsql; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    if ! php -m | grep -qi '^imagick$'; then pecl install imagick; fi; \
    docker-php-ext-enable imagick || true; \
    { \
        echo 'upload_max_filesize=64M'; \
        echo 'post_max_size=64M'; \
        echo 'memory_limit=512M'; \
        echo 'max_execution_time=300'; \
        echo 'max_input_time=300'; \
    } > /usr/local/etc/php/conf.d/uploads.ini; \
    rm -rf /var/lib/apt/lists/*

ARG COMPOSER_VERSION=2.7.9

RUN set -eux; \
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}; \
    rm -f /tmp/composer-setup.php

RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp

ARG PLUGINS_CACHE_BUST=1

RUN set -eux; \
    curl -fsSL https://github.com/mralaminahamed/wp-pgsql-database/archive/refs/heads/trunk.zip -o /tmp/wp-pgsql-database.zip; \
    unzip /tmp/wp-pgsql-database.zip -d /usr/src/wordpress/wp-content/plugins; \
    mv /usr/src/wordpress/wp-content/plugins/wp-pgsql-database-trunk /usr/src/wordpress/wp-content/plugins/wp-pgsql-database; \
    rm -f /tmp/wp-pgsql-database.zip; \
    if [ -f /usr/src/wordpress/wp-content/plugins/wp-pgsql-database/composer.json ]; then composer install --no-dev --prefer-dist --no-interaction --no-progress --working-dir=/usr/src/wordpress/wp-content/plugins/wp-pgsql-database; fi; \
    curl -fsSL https://github.com/humanmade/S3-Uploads/archive/refs/heads/master.zip -o /tmp/s3-uploads.zip; \
    unzip /tmp/s3-uploads.zip -d /usr/src/wordpress/wp-content/plugins; \
    mv /usr/src/wordpress/wp-content/plugins/S3-Uploads-master /usr/src/wordpress/wp-content/plugins/s3-uploads; \
    rm -f /tmp/s3-uploads.zip; \
    if [ -f /usr/src/wordpress/wp-content/plugins/s3-uploads/composer.json ]; then composer install --no-dev --prefer-dist --no-interaction --no-progress --working-dir=/usr/src/wordpress/wp-content/plugins/s3-uploads; fi; \
    curl -fsSL https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip -o /tmp/redis-cache.zip; \
    unzip /tmp/redis-cache.zip -d /usr/src/wordpress/wp-content/plugins; \
    rm -f /tmp/redis-cache.zip; \
    mkdir -p /var/www/html/wp-content/mu-plugins; \
    chown -R www-data:www-data /var/www/html/wp-content

# Patch PostgreSQL translator: fix ON CONFLICT target + VALUES(col) → EXCLUDED.col
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
