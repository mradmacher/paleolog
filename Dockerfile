FROM ruby:3.0
RUN apt-get update && apt-get upgrade
RUN apt-get install sqlite3
WORKDIR /app
COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle config --local deployment true
RUN bundle config --local without "development test"
RUN bundle install
COPY . .
