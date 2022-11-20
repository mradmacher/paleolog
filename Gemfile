# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'pg'
gem 'pdfkit'
gem 'puma'
gem 'rake'
gem 'RedCloth'
gem 'sequel'
gem 'sinatra'
gem 'param-param', git: 'git@github.com:mradmacher/param-param.git' # tag: 'v0.1.0'

group :development do
  gem 'sinatra-contrib'
end

group :test, :development do
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-rake'
  gem 'rubocop-sequel'
end

group :test do
  gem 'capybara'
  gem 'minitest'
  gem 'minitest-hooks'
  gem 'minitest-rg'
  gem 'rack-test'
  gem 'selenium-webdriver'
end
