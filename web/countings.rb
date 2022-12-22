# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Countings < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects/:project_id/countings/:id' do
      authorize!
    end

    get '/projects/:project_id/countings/:id' do
      @project = Paleolog::Repo::Project.find(
          params[:project_id].to_i,
          Paleolog::Repo::Project.with_countings,
          Paleolog::Repo::Project.with_sections,
          Paleolog::Repo::Project.with_participations,
        )
      @counting = Paleolog::Repo::Counting.find_for_project(params[:id].to_i, @project.id)
      using_project_layout { display 'countings/show.html' }
    end
  end
end
