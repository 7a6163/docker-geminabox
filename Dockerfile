FROM ruby:3.2-alpine AS builder

RUN apk add --no-cache build-base=0.5-r3 git=2.45.2-r0
WORKDIR /app
COPY Gemfile* ./
RUN gem install bundler:2.5.11 && bundle install -j4

FROM ruby:3.2-alpine

RUN apk add --no-cache tini=0.19.0-r3
WORKDIR /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY Gemfile* config.ru ./

ENV BASIC_USER=""
ENV BASIC_PASS=""
ENV RACK_ENV="production"

EXPOSE 9292
ENTRYPOINT ["/sbin/tini", "--", "bundle", "exec", "puma"]
