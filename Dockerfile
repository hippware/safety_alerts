FROM ruby:2.7-alpine

RUN apk upgrade --no-cache --update
RUN apk add --no-cache postgresql-libs curl geos
RUN apk add --no-cache --virtual .build gcc g++ make postgresql-dev geos-dev
RUN gem update

RUN mkdir safety_alerts
WORKDIR safety_alerts

COPY Gemfile* ./
RUN bundle install
RUN apk del --force .build

COPY import_* ./
COPY lib lib
