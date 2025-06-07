FROM php:8.3.7-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libpq-dev zip unzip git \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_pgsql

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite for Laravel
RUN a2enmod rewrite

# Set Apache document root to Laravel's public directory
ENV APACHE_DOCUMENT_ROOT /var/www/laravel/public
RUN if [ -d /etc/apache2/sites-available ]; then sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf; fi \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# Set working directory
WORKDIR /var/www/laravel

# Copy application files and setup script
COPY laravel/ .
COPY config-stateless/ /var/www/config-stateless/
COPY .env.example /var/www/.env.example
COPY setup.sh /var/www/setup.sh

# Set permissions and verify setup script
RUN chown -R www-data:www-data /var/www /var/www/laravel \
    && chmod -R 775 /var/www \
    && chmod +x /var/www/setup.sh \
    && ls -la /var/www/setup.sh > /var/www/setup_verify.log

# Expose port
EXPOSE 80

CMD ["apache2-foreground"]