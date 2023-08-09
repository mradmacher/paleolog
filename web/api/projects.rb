# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Projects < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before do
        @operation = Paleolog::Operation::Project.new(Paleolog::Repo, authorizer)
      end

      get '/api/projects' do
        model_or_errors(
          @operation.find_all_for_user(authorizer.user_id),
          serializer,
          :projects,
        )
      end

      post '/api/projects' do
        model_or_errors(
          @operation.create(params.merge(user_id: authorizer.user_id)),
          serializer,
        )
      end

      patch '/api/projects/:id' do
        model_or_errors(@operation.rename(params), serializer)
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
