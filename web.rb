# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, 'lib')

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/reloader'
require 'paleolog'

class PaleologWeb < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    erb 'home.html'.to_sym, layout: 'application.html'.to_sym
  end

  get '/catalogue' do
    @filters = {}
    @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
    @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

    @species = Paleolog::Repositories::SpeciesRepository.new(Paleolog::Repositories::Repository.db).search_verified(@filters)
    @available_filters = {}
    @available_filters[:groups] = Paleolog::Repositories::GroupRepository.new(Paleolog::Repositories::Repository.db).all

    erb 'catalogue.html'.to_sym, layout: 'application.html'.to_sym
  end
end
