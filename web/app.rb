# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/reloader' if ENV['RACK_ENV'] == 'development'
require 'redcarpet'
require 'paleolog'
require_relative 'auth_helpers'
require_relative 'api/countings'
require_relative 'api/occurrences'
require_relative 'api/projects'
require_relative 'api/sections'
require_relative 'api/samples'
require_relative 'api/species'
require_relative 'projects'
require_relative 'sections'
require_relative 'countings'
require_relative 'reports'
require_relative 'species'
require_relative 'auths'

class PaleologWeb < Sinatra::Base
  enable :sessions
  set :static, true

  configure :development do
    register Sinatra::Reloader
  end

  configure :production, :development do
    enable :logging
  end

  helpers Web::AuthHelpers

  use Web::Auths
  use Web::Projects
  use Web::Sections
  use Web::Countings
  use Web::Api::Countings
  use Web::Api::Occurrences
  use Web::Api::Projects
  use Web::Api::Samples
  use Web::Api::Sections
  use Web::Api::Species
  use Web::Species
  use Web::Reports

  before do
    require_https!
  end

  get '/' do
    erb :'home.html', layout: :'application.html'
  end

  get '*' do
    redirect '/'
  end
end
