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
  libapache2-mod-php7.0 \
  php-pear \
  apt-transport-https \
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
COPY run.sh /run.sh
ADD  run.sh /run.sh

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY php.ini /etc/php/7.0/apache2/php.ini
#COPY .bashrc /root/.bashrc
#RUN source .bashrc
COPY run.sh /usr/local/bin/run
RUN chmod +x /var/www
RUN chmod +x /usr/local/bin/run
# Enables apache rewrite module
RUN a2enmod rewrite

RUN curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update

RUN apt-get install msodbcsql17 mssql-tools

RUN \
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile \
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

RUN \
source ~/.bashrc \
apt-get install unixodbc-dev \
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
locale-gen

RUN sudo apt-get install -y unixodbc-dev php7.0-dev \
    && wget -nv "https://github.com/Microsoft/msphpsql/archive/PHP-7.0-Linux.tar.gz" \
    && tar -xf PHP-7.0-Linux.tar.gz \
    && cd msphpsql-PHP-7.0-Linux/source/ \
    && cp -r shared/ pdo_sqlsrv/ \
    && cd pdo_sqlsrv/ \
    && phpize \
    && ./configure CXXFLAGS=-std=c++11 \
    && make \
    && sudo make "INSTALL=$(pwd)/build/shtool install -c --mode=0644" install \
    && printf "; priority=20\nextension=pdo_sqlsrv.so" \
    | sudo tee /etc/php/7.0/mods-available/pdo_sqlsrv.ini \
    && sudo phpenmod pdo_sqlsrv \
    && php --rextinfo pdo_sqlsrv \
    && sudo phpdismod pdo_sqlsrv \
    && sudo rm -f /usr/lib/php/20151012/pdo_sqlsrv.so

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
