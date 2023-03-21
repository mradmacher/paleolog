# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Sections < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before '/api/sections*' do
        authorize_api!
      end

      post '/api/sections' do
        model_or_errors(*Paleolog::Operation::Section.create(params, user_id: authorizer.user_id), serializer)
      end

      patch '/api/sections/:id' do
        model_or_errors(*Paleolog::Operation::Section.rename(params, user_id: authorizer.user_id), serializer)
      end

      private

      def serializer
        lambda do |section|
          {
            id: section.id,
            project_id: section.project_id,
            name: section.name,
            created_at: section.created_at,
            updated_at: section.updated_at,
          }
        end
      end
    end
  end
end
