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
      @projects = Paleolog::Repo::Project.all
      using_application_layout { display 'projects/index.html' }
    end

    get '/projects/:id' do
      @project = Paleolog::Repo::Project.find(
        params[:id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_researchers,
      )
      using_project_layout { display 'projects/show.html' }
    end

    get '/projects/:id/species' do
      @project = Paleolog::Repo::Project.find(params[:id].to_i)
      @filters = {}
      @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      @filters[:name] = params[:name] if params[:name] && !params[:name].empty?
      @filters[:verified] = true if params[:verified] == 'true'

      using_project_without_sidebar_layout { display 'projects/catalog.html' }
    end
  end
end
