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
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id]).value
      @section_id = params[:id].to_i
      using_project_layout { display 'sections/show.html' }
    end
  end
end
