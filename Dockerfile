# this is the base of all images
FROM ruby:3.4.1-slim-bookworm AS base
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    sqlite3

# build dependencies
FROM base AS dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    gcc \
    git \
    make
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without "development test" && \
  bundle config set --local path "/usr/local/bundle" && \
  bundle install --jobs=3 --retry=3

# set base for all environments
FROM base AS environemnt
ARG USER_UID
COPY --from=dependencies /usr/local/bundle /usr/local/bundle
RUN adduser --disabled-password paleolog --uid ${USER_UID:-1001}

USER paleolog
WORKDIR /home/paleolog
COPY Gemfile Gemfile.lock ./

# production
FROM environemnt AS production
ENV RACK_ENV=production
USER root
RUN bundle config set --local deployment true
USER paleolog
COPY --chown=paleolog . .
CMD ["bundle", "exec", "rackup"]

# development
FROM environemnt AS development
ENV RACK_ENV=development
USER root
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    gcc \
    make
# installing also test and development gems
RUN bundle config unset --local without && bundle install
USER paleolog
