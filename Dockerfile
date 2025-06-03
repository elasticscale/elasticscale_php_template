FROM php:8.3.7-apache

# Build-time environment variables for Vite
ARG VITE_PUSHER_APP_KEY
ARG VITE_PUSHER_PORT
ARG VITE_APP_NAME
ARG VITE_PUSHER_SCHEME
ARG VITE_PUSHER_APP_CLUSTER

# Runtime environment variables for Vite
ENV VITE_PUSHER_APP_KEY=$VITE_PUSHER_APP_KEY
ENV VITE_PUSHER_PORT=$VITE_PUSHER_PORT
ENV VITE_APP_NAME=$VITE_APP_NAME
ENV VITE_PUSHER_SCHEME=$VITE_PUSHER_SCHEME
ENV VITE_PUSHER_APP_CLUSTER=$VITE_PUSHER_APP_CLUSTER
ENV VITE_ORIGIN="./"

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    npm git unzip curl gnupg \
    && curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        gd pdo_mysql zip intl soap pcntl bcmath calendar mysqli opcache sockets apcu yaml memcached excimer

# Configure Apache to use Laravel's public folder and ports
ENV APACHE_DOCUMENT_ROOT /var/app/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri 's|80|8080|g' /etc/apache2/sites-available/*.conf && \
    sed -ri 's|80|8080|g' /etc/apache2/ports.conf && \
    sed -ri 's|443|8081|g' /etc/apache2/ports.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN a2enmod rewrite headers ssl

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Timezone and PHP settings
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    echo "date.timezone=$TZ" > $PHP_INI_DIR/conf.d/timezone.ini

RUN echo "memory_limit=8192M" > $PHP_INI_DIR/conf.d/memory.ini && \
    echo "display_errors=1" > $PHP_INI_DIR/conf.d/errors.ini && \
    echo "upload_max_filesize=100M" > $PHP_INI_DIR/conf.d/upload.ini && \
    echo "post_max_size=100M" > $PHP_INI_DIR/conf.d/postsize.ini && \
    echo "opcache.enable=1" > $PHP_INI_DIR/conf.d/opcache.ini && \
    echo "opcache.enable_cli=1" >> $PHP_INI_DIR/conf.d/opcache.ini

# Copy app
COPY . /var/app

# Set correct permissions for Tinker (PsySH)
RUN mkdir -p /var/app/.config/psysh && chown -R www-data:www-data /var/app/.config

# Run Laravel & NPM builds
RUN cd /var/app && npm install && npm run build

# Fix permissions before switching to www-data
RUN chown -R www-data:www-data /var/app \
    && mkdir -p /var/app/storage/framework/{cache,views,sessions,logs} \
    && chmod -R 777 /var/app/storage

# Set working HOME for www-data
ENV HOME=/var/app
USER www-data

# Install Laravel dependencies
RUN cd /var/app && composer install -n --prefer-dist --optimize-autoloader --no-scripts --apcu-autoloader

# Storage link
RUN cd /var/app && php artisan storage:link || true

EXPOSE 8080
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
