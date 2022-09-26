# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'dry-validation'
gem 'pg'
gem 'pdfkit'
gem 'puma'
gem 'rake'
gem 'RedCloth'
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

group :production do
  # gem 'puma'
end
