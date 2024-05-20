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
      redirect projects_path unless authorizer.can_view?(Paleolog::Project, params[:project_id].to_i)

      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
      )
      @counting_id = params[:id].to_i
      @counting = Paleolog::Repo::Counting.find_for_project(
        params[:id].to_i, @project.id,
      )
      @section_id = params[:section]
      @sample_id = params[:sample]
      using_project_layout { display 'countings/show.html' }
    end
  end
end
