FROM debian:jessie
MAINTAINER Herisson Silva <herisson.cleiton.r@gmail.com>
RUN \
  apt-get update && \
  apt-get install -y \
  curl \
  wget \
  git

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

RUN \
  apt-get update && \
  apt-get install -y \
  apache2 \
  vim \
  locales \
  iptables \
  php7.0 \
  php7.0-fpm \
  php7.0-mysql \
  php7.0-gd \
  php7.0-imagick \
  php7.0-dev \
  php7.0-curl \
  php7.0-opcache \
  php7.0-cli \
  php7.0-sqlite \
  php7.0-intl \
  php7.0-tidy \
  php7.0-imap \
  php7.0-json \
  php7.0-pspell \
  php7.0-recode \
  php7.0-common \
  php7.0-sybase \
  php7.0-sqlite3 \
  php7.0-bz2 \
  php7.0-mcrypt \
  php7.0-common \
  php7.0-apcu-bc \
  php7.0-memcached \
  php7.0-redis \
  php7.0-xml \
  php7.0-shmop \
  php7.0-mbstring \
  php7.0-zip \
  php7.0-bcmath \
  php7.0-soap \
  nano \

    # Cleaning...
    && apt-get clean && apt-get autoclean && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require hirak/prestissimo && \
    composer global require phpro/grumphp && \
    wget http://robo.li/robo.phar && \
    chmod +x robo.phar && mv robo.phar /usr/bin/robo

RUN echo Europe/Brussels > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

RUN echo 'de_DE ISO-8859-1\n\
de_DE.UTF-8 UTF-8\n\
de_DE@euro ISO-8859-15\n\
en_GB ISO-8859-1\n\
en_GB.ISO-8859-15 ISO-8859-15\n\
en_US ISO-8859-1\n\
en_US.ISO-8859-15 ISO-8859-15\n\
en_US.UTF-8 UTF-8\n\
fr_FR ISO-8859-1\n\
fr_FR.UTF-8 UTF-8\n\
fr_FR@euro ISO-8859-15\n\
nl_BE ISO-8859-1\n\
nl_BE.UTF-8 UTF-8\n\
nl_BE@euro ISO-8859-15\n\
nl_NL ISO-8859-1\n\
nl_NL.UTF-8 UTF-8\n\
nl_NL@euro ISO-8859-15\n'\
>> /etc/locale.gen &&  \
usr/sbin/locale-gen

RUN usermod -u 1000 www-data

ENV ENVIRONMENT dev
ENV PHP_FPM_USER www-data
ENV PHP_FPM_PORT 9000
ENV PHP_ERROR_REPORTING "E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED"
ENV PATH "/root/.composer/vendor/bin:$PATH"
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_LOCK_DIR  /var/lock
ENV APACHE_PID_FILE  /var/run/apache2.pid

VOLUME /var/www/html
#ADD . /var/www/html/


COPY php.ini    /etc/php/7.0/fpm/conf.d/
COPY php.ini    /etc/php/7.0/cli/conf.d/
COPY www.conf   /etc/php/7.0/fpm/pool.d/
ADD  run.sh /run.sh

COPY run.sh /run.sh
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ZendFramework-1.12.3.tar.gz /etc/zend/ZendFramework-1.12.3.tar.gz
RUN tar -xvzf /etc/zend/ZendFramework-1.12.3.tar.gz
RUN rm -rf /etc/zend/ZendFramework-1.12.3.tar.gz
COPY php.ini /etc/php5/apache2/php.ini
COPY .bashrc /root/.bashrc
#RUN source .bashrc
COPY run /usr/local/bin/run
RUN chmod +x /var/www
RUN chmod +x /usr/local/bin/run
# Enables apache rewrite module
RUN a2enmod rewrite

#SSL
#RUN /usr/sbin/a2ensite default-ssl
#RUN /usr/sbin/a2enmod ssl
# https://httpd.apache.org/docs/2.4/mod/prefork.html
#RUN /usr/sbin/a2dismod 'mpm_*' && /usr/sbin/a2enmod mpm_prefork
LABEL Description=" Apache 2.4.7 Webserver - PHP 7.0.3"
EXPOSE 80

ENTRYPOINT ["/bin/bash", "/run.sh"]


#SSL
#EXPOSE 443

CMD ["/usr/local/bin/run"]
