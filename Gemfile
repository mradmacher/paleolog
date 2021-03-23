# frozen_string_literal: true

source 'https://rubygems.org'

gem 'dry-struct'
gem 'dry-types'
gem 'rake'
gem 'rom'
gem 'rom-sql'
gem 'sinatra'
gem 'sqlite3'

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
  gem 'rack-test'
end

group :production do
  # gem 'puma'
end
