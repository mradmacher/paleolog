FROM ruby:3.0
WORKDIR /app
COPY . .
RUN bundle install
ENV RACK_ENV=production
ENTRYPOINT ["bundle", "exec", "rackup", "-p 9292", "-o 0.0.0.0"]
#ENTRYPOINT ["tail", "-f", "/dev/null"]
