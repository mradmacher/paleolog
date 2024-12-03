# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Projects < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects*' do
      authorize!
    end

    get '/projects' do
      @filters = {}
      using_application_layout { display 'projects/index.html' }
    end

    get '/projects/:id' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:id]).value
      using_project_layout { display 'projects/show.html' }
    end

    get '/projects/:id/species' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:id]).value
      @filters = {}
      @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      @filters[:name] = params[:name] if params[:name] && !params[:name].empty?
      @filters[:verified] = true if params[:verified] == 'true'

      using_project_layout { display 'projects/catalog.html' }
    end

    get '/projects/:project_id/species/:id' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id]).value
      @species = Paleolog::Repository::Species.new(Paleolog.db, authorizer).find(id: params[:id]).value
      using_project_layout { using_project_species_layout { display 'species/show.html' } }
    end
  end
end
