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
          projects: projects.map { |project| serialize(project) },
        }.to_json
      end

      post '/api/projects' do
        project, errors = settings.operation.create(params.merge(user_id: authorizer.user_id))
        if errors.empty?
          { project: serialize(project) }.to_json
        else
          { errors: errors }.to_json
        end
      end

      patch '/api/projects/:id' do
      end

      private

      def serialize(project)
        {
          id: project.id,
          name: project.name,
          created_at: project.created_at,
        }
      end
    end
  end
end
