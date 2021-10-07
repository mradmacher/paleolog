# frozen_string_literal: true

source 'https://rubygems.org'

gem 'sequel'
gem 'pdfkit'
gem 'rake'
gem 'RedCloth'
gem 'sinatra'
gem 'sqlite3'
gem 'bcrypt'

group :development do
  # gem 'shotgun', platforms: :ruby
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
  gem 'minitest-rg'
  gem 'minitest-hooks'
  gem 'rack-test'
end

group :production do
  # gem 'puma'
end
