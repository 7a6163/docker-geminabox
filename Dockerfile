FROM ruby:2.7-alpine AS Builder

RUN apk add --no-cache build-base=0.5-r2
RUN gem install bundler:2.2.17

WORKDIR /app
COPY Gemfile* ./
RUN gem install bundler:2.2.28
RUN bundle install

FROM ruby:2.7-alpine
LABEL maintainer="Zac"

RUN apk add --no-cache tini=0.19.0-r0
WORKDIR /app
COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/
COPY Gemfile* config.ru ./

ENV BASIC_USER=""
ENV BASIC_PASS=""
ENV RACK_ENV="production"

EXPOSE 9292
ENTRYPOINT ["/sbin/tini", "--", "bundle", "exec", "puma"]
