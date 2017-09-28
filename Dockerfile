# LAMP
#
# VERSION   1.0

# use the ubuntu base image
FROM php:7.0-apache

ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_SERVERADMIN=admin@localhost \
    APACHE_SERVERNAME=localhost \
    APACHE_SERVERALIAS=docker.localhost \
    APACHE_DOCUMENTROOT=/var/www/html \
    APACHE_LOG_DIR=/var/log/apache2

ENV DEBIAN_FRONTEND noninteractive

RUN a2enmod rewrite headers

# Install bash-completion
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install bash-completion

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq\
        curl \
        git \
        libpng12-dev \
        libjpeg-dev \
        libmcrypt-dev \
        wget \
        zlib1g-dev \
        locales \
        build-essential \
        ca-certificates \
        libcurl4-openssl-dev \
        libffi-dev \
        libgdbm-dev \
        libpq-dev \
        libreadline6-dev \
        libssl-dev \
        libtool \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        software-properties-common \
        wget \
        zlib1g-dev \
        yui-compressor \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd mysqli mbstring zip


#Install and enable xdebug
RUN pecl install xdebug-2.5.0 \
    && docker-php-ext-enable xdebug

# Install intl     #php7.0-intl
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libicu-dev \
    && docker-php-ext-install -j$(nproc) intl

# Configure timezone and locale
RUN echo "Europe/Paris" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

RUN locale-gen
ENV LANGUAGE=en_US.UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV locale-gen=en_US.UTF-8

COPY website.conf /etc/apache2/sites-available/
COPY php.ini /usr/local/etc/php/conf.d/
RUN ln -s /etc/apache2/sites-available/website.conf /etc/apache2/sites-enabled/
RUN rm /etc/apache2/sites-enabled/000-default.conf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install Ruby.
# Install MRI Ruby 2.3.3
RUN curl -O http://ftp.ruby-lang.org/pub/ruby/2.3/ruby-2.3.3.tar.gz && \
    tar -zxvf ruby-2.3.3.tar.gz && \
    cd ruby-2.3.3 && \
    ./configure --disable-install-doc && \
    make && \
    make install && \
    cd .. && \
    rm -r ruby-2.3.3 ruby-2.3.3.tar.gz && \
    echo 'gem: --no-document' > /usr/local/etc/gemrc

# Set $PATH so that non-login shells will see the Ruby binaries
ENV PATH $PATH:/opt/rubies/ruby-2.3.3/bin

# Install rubygems and bundler
#ADD http://production.cf.rubygems.org/rubygems/rubygems-2.3.0.tgz /tmp/
RUN wget https://rubygems.org/rubygems/rubygems-2.6.8.tgz -P /tmp/
RUN cd /tmp && \
    tar -zxf /tmp/rubygems-2.6.8.tgz && \
    cd /tmp/rubygems-2.6.8 && \
    ruby setup.rb && \
    /bin/bash -l -c 'gem install bundler --no-rdoc --no-ri' && \
    echo "gem: --no-ri --no-rdoc" > ~/.gemrc

RUN gem cleanup cmdparse
COPY Gemfile /tmp/
RUN cd /tmp/ && bundle install
#RUN gem install cmdparse -v 2.0.6
#RUN gem install bundler rails
#RUN gem install guard guard-sass guard-process sass juicer
#RUN juicer install yui_compressor

# Clean up APT and temporary files when done
RUN apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["${APACHE_DOCUMENTROOT}"]
EXPOSE 80 443
