FROM ruby:2.6.10-slim

# PGSQL_VERSION=9.3

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    git-core \
    libcurl4-openssl-dev \
    libpq-dev \
    libsqlite3-dev \
    libxml2 \
    libxml2-dev \
    libxslt1.1 \
    libxslt1-dev \
    nodejs \
    sqlite3 \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=C.UTF-8

RUN gem update --system && gem install bundler

WORKDIR /usr/src/app

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
