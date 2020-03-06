FROM ruby:2.7-alpine

RUN apk upgrade --no-cache --update &&\
    apk add --no-cache postgresql-libs curl geos &&\
    apk add --no-cache --virtual .build gcc g++ make postgresql-dev geos-dev &&\
    gem update &&\
    mkdir safety_alerts

WORKDIR safety_alerts

COPY Gemfile* ./
RUN bundle install && apk del --force .build

COPY import_* .rspec .rubocop.yml ci ./
COPY lib lib
COPY spec spec
