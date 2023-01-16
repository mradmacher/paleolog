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
        Paleolog::Repo::Project.with_participations,
      )
      using_project_layout { display 'projects/show.html' }
    end
  end
end
