# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'

module Web
  module Api
    class Projects < Sinatra::Base
      helpers Web::AuthHelpers

      configure do
        set :operation, Paleolog::Operation::Project
      end

      before '/api/projects*' do
        authorize_api!
      end

      get '/api/projects' do
        projects = settings.operation.find_all_for_user(authorizer.user_id)
        {
          projects: projects.map { |project|
                      {
                        id: project.id,
                        name: project.name,
                        created_at: project.created_at,
                      }
                    }
        }.to_json
      end

      post '/api/projects' do
        result = settings.operation.create(params.merge(user_id: authorizer.user_id))
        if result.success?
          {
            project: {
              id: result.value.id,
              name: result.value.name,
              created_at: result.value.created_at,
            }
          }.to_json
        else
          { errors: result.error }.to_json
        end
      end

      delete '/api/projects/:id' do
      end

      patch '/api/projects/:id' do
      end
    end
  end
end
