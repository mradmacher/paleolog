FROM mradmacher/paleolog_env:latest
WORKDIR /app
COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle config --local deployment true
RUN bundle config --local without "development test"
RUN bundle install
COPY . .
