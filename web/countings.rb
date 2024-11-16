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
      result = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id])
                                           .on_success { @project = _1 }
                                           .and_then do
        Paleolog::Repository::Counting.new(Paleolog.db, authorizer)
                                     .find(id: params[:id], project_id: @project.id)
      end
      case result
      in { value: }
        @counting = value
        @counting_id = @counting.id
        @section_id = params[:section]
        @sample_id = params[:sample]
        using_project_layout { display 'countings/show.html' }
      in { error: }
        redirect projects_path
      end
    end
  end
end
