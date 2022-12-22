# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Sections < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects/:project_id/sections*' do
      authorize!
    end

    get '/projects/:project_id/sections/:id' do
      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_participations,
      )
      @section = Paleolog::Repo::Section.find_for_project(params[:id].to_i, @project.id)
      using_project_layout { display 'sections/show.html' }
    end
  end
end
