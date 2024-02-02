# syntax=docker/dockerfile:1

FROM ruby:3.1.4 AS base

FROM base AS dependencies
RUN apt-get update -qq && apt-get install -y gcc cron

FROM dependencies as build
USER root
WORKDIR /app
COPY . .
RUN gem install bundler
RUN bundle install

FROM build as runtime

COPY --from=build /app /app

EXPOSE 3000
CMD ["sh", "-c", "./bin/volume_sweeper --help"]
