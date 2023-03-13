# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Projects < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      configure do
        set :operation, Paleolog::Operation::Project
      end

      before '/api/projects*' do
        authorize_api!
      end

      get '/api/projects' do
        projects = settings.operation.find_all_for_user(authorizer.user_id)
        {
          projects: projects.map { |project| serializer.call(project) },
        }.to_json
      end

      post '/api/projects' do
        model_or_errors(*settings.operation.create(name: params[:name], user_id: authorizer.user_id), serializer)
      end

      patch '/api/projects/:id' do
        halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:id])

        model_or_errors(*settings.operation.rename(params[:id], name: params[:name]), serializer)
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
