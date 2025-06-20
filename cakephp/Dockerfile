FROM php:8.3.7-apache
# this is the production / staging image, not the devcontainer

# install the php extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions gd redis pdo_mysql zip intl soap pcntl bcmath calendar mysqli opcache sockets apcu yaml memcache pcov excimer

# set webroot
ENV APACHE_DOCUMENT_ROOT=/var/app/webroot
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && sed -ri 's|80|8080|g' /etc/apache2/sites-available/*.conf
RUN sed -ri 's|80|8080|g' /etc/apache2/ports.conf && sed -ri 's|443|8081|g' /etc/apache2/ports.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# enable apache mods
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# utc time
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "date.timezone=$TZ" > $PHP_INI_DIR/conf.d/timezone.ini

# php settings
RUN echo "memory_limit=8192M" >> $PHP_INI_DIR/conf.d/memory.ini
RUN echo "display_errors=1" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "display_startup_errors=0" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "error_reporting=E_ALL" >> $PHP_INI_DIR/conf.d/errors.ini
RUN echo "upload_max_filesize=100M" >> $PHP_INI_DIR/conf.d/upload.ini
RUN echo "post_max_size=100M" >> $PHP_INI_DIR/conf.d/postsize.ini

# security settings
RUN echo "expose_php=0" >> $PHP_INI_DIR/conf.d/security.ini
RUN echo "allow_url_fopen=0" >> $PHP_INI_DIR/conf.d/security.ini
RUN echo "allow_url_include=0" >> $PHP_INI_DIR/conf.d/security.ini
RUN echo "display_errors=0" >> $PHP_INI_DIR/conf.d/security.ini
RUN echo "display_startup_errors=0" >> $PHP_INI_DIR/conf.d/security.ini
RUN echo "disable_functions=exec,passthru,shell_exec,system,popen,parse_ini_file,show_source,phpinfo" >> $PHP_INI_DIR/conf.d/security.ini

# add app user
RUN groupadd --gid 1000 app
RUN adduser --gid 1000 --uid 1000 app

# setup the volume so we can control permissions
RUN mkdir /var/app && chown app:app /var/app
VOLUME /var/app
COPY . /var/app

# www data owns this stuff below and can run apache, provided we fix the port
RUN chown app:app /var/app && chown -R app:app /var/app
RUN chmod -R 775 /var/app
RUN chmod +x /var/app/bin/*

# run it as user app and not root
USER app

#  run on 8080
EXPOSE 8080

# Set workdir
WORKDIR /var/app

# run composer install
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# run apache
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
