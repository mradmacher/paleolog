# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Projects < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before '/api/projects*' do
        authorize_api!
      end

      get '/api/projects' do
        projects = Paleolog::Operation::Project.find_all_for_user(authorizer.user_id)
        {
          projects: projects.map { |project| serializer.call(project) },
        }.to_json
      end

      post '/api/projects' do
        model_or_errors(*Paleolog::Operation::Project.create(params, user_id: authorizer.user_id), serializer)
      end

      patch '/api/projects/:id' do
        model_or_errors(*Paleolog::Operation::Project.rename(params, user_id: authorizer.user_id), serializer)
      end

      private

      def serializer
        lambda do |project|
          {
            id: project.id,
            name: project.name,
            created_at: project.created_at,
          }
        end
      end
    end
  end
end
