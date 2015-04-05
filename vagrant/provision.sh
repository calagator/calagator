#!/bin/bash

APPDIR="/vagrant"
VAGRANT_USER="vagrant"
PGSQL_VERSION=9.3
RUBY_VERSION=2.1

# Fix locale so that Postgres creates databases in UTF-8
if [ "${LANG}" != "en_US.UTF-8" ] ; then
  locale-gen en_US.UTF-8
  dpkg-reconfigure locales
fi

# Add source for up-to-date ruby
# docs: https://www.brightbox.com/docs/ruby/ubuntu/
if [ ! -e "/etc/apt/sources.list.d/brightbox-ruby-ng-trusty.list" ] ; then
  add-apt-repository -y ppa:brightbox/ruby-ng
  apt-get update -y
fi

# remove preinstalled ruby
apt-get remove ruby1.9.1 libruby1.9.1

# Required packages
apt-get install -y ruby${RUBY_VERSION} ruby${RUBY_VERSION}-dev build-essential phantomjs libcurl4-openssl-dev libsqlite3-dev libxml2 libxml2-dev libxslt1.1 libxslt1-dev

# Useful tools
apt-get install -y git-core screen tmux elinks 

# Postgresql. Do we really want a full postgres running?
apt-get install -y postgresql-$PGSQL_VERSION libpq-dev postgresql-client-common postgresql-contrib-$PGSQL_VERSION postgresql-$PGSQL_VERSION-postgis-$PGIS_VERSION

# Req to build mysql2 gem
apt-get install libmysqlclient-dev

# Install Java for Solr
apt-get install -y openjdk-7-jre-headless

# Create PostgreSQL user
if ! su postgres -c "psql -c '\\du' | grep ${VAGRANT_USER}"; then
    su postgres -c "createuser --superuser ${VAGRANT_USER}"
fi

# tilde expansion on string
eval PROFILE="~${VAGRANT_USER}/.profile"

# add gem path to PATH
if ! grep -q "gem env path" $PROFILE; then
    printf "\nexport PATH=\"`gem env path`:\$PATH\"\n" >> $PROFILE
fi

# cd to APPDIR on login
if ! grep -q "cd ${APPDIR}" $PROFILE; then
    printf "if shopt -q login_shell; then cd ${APPDIR}; fi\n" >> $PROFILE
fi

# install bundler and rake
gem install bundler rake

# Bundle install
su ${VAGRANT_USER} -l -c 'bundle check || bundle --local || bundle'

# Create dummy app
if [ ! -e "${APPDIR}/spec/dummy/" ] ; then
  su ${VAGRANT_USER} -l -c 'bin/calagator new spec/dummy --dummy'
  su ${VAGRANT_USER} -l -c 'rake app:db:migrate app:db:setup'
fi

# Cleanup for box image build
# apt-get clean
# echo "Zeroing free space to improve compression..."
# dd if=/dev/zero of=/EMPTY bs=1M
# rm -f /EMPTY
