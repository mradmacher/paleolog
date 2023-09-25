# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'optiomist', '~> 0.0.3'
gem 'param_param', '~> 0.1.0'
gem 'entitainer', git: 'https://github.com/mradmacher/entitainer.git', tag: '4da8473'
gem 'resonad'
gem 'pdfkit'
gem 'pg'
gem 'puma', '~> 5.6.7'
gem 'rake'
gem 'redcarpet'
gem 'sequel'
gem 'sinatra'

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
