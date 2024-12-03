# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'entitainer', git: 'https://github.com/mradmacher/entitainer.git', tag: 'adef45a'
gem 'optiomist', '~> 0.0.3'
gem 'param_param', '~> 0.1.0'
gem 'pdfkit'
gem 'pg'
gem 'puma'
gem 'rackup'
gem 'rake'
gem 'redcarpet'
gem 'resonad'
gem 'sequel'
gem 'sinatra', '>= 4.1.0'

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
  gem 'selenium-webdriver', '~> 4.8.0'
end
