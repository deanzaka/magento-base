## magento base image 
## magento 2 installation based on https://linuxize.com/post/how-to-install-magento-2-on-ubuntu-18-04/

FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
LABEL maintainer="deanzaka"

## install prereq
RUN apt-get -y update && \
  apt-get -y install \
  nginx \
  curl \
  unzip \
  sudo \
  nano 

## install php
RUN apt-get -y install \
  php7.2-common \
  php7.2-cli \
  php7.2-fpm \
  php7.2-opcache \
  php7.2-gd \
  php7.2-mysql \
  php7.2-curl \
  php7.2-intl \
  php7.2-xsl \
  php7.2-mbstring \
  php7.2-zip \
  php7.2-bcmath \
  php7.2-soap

## set recommended php options
RUN sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.2/fpm/php.ini \
  && sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.2/fpm/php.ini \
  && sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.2/fpm/php.ini \
  && sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.2/fpm/php.ini \
  && sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini \
  && sed -i "s/;opcache.save_comments.*/opcache.save_comments = 1/" /etc/php/7.2/fpm/php.ini

## create an FPM pool for the magento user
COPY magento.conf /etc/php/7.2/fpm/pool.d/magento.conf
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

## add magento user with no password setup
RUN useradd -m -U -r -d /opt/magento magento \
  && usermod -a -G magento www-data \
  && chmod 750 /opt/magento \
  && echo 'magento  ALL=(ALL)  NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /opt/magento
USER magento

EXPOSE 80 443
CMD sudo service nginx start \
  && sudo service php7.2-fpm start \
  && if [ ! -d "/var/www/html/magento2/bin" ]; \
    then echo -e "Composer project not found, please follow instruction at: \n\
https://cloud.docker.com/u/deanzaka/repository/docker/deanzaka/magento-base"; fi \
  && if [ ! -f "/var/www/html/config/magento" ]; \
    then echo -e "nginx config file not found, please follow instruction at: \n\
https://cloud.docker.com/u/deanzaka/repository/docker/deanzaka/magento-base"; \
    else \
      sudo ln -sf /var/www/html/config/magento /etc/nginx/sites-available; \
      sudo ln -sf /var/www/html/config/magento /etc/nginx/sites-enabled; fi \
  && sudo nginx -t \
  && sudo service nginx restart \
  && sudo tail -f /var/log/nginx/access.log; fi