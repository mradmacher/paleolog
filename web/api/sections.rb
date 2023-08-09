# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Sections < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before do
        @operation = Paleolog::Operation::Section.new(Paleolog::Repo, authorizer)
      end

      post '/api/sections' do
        model_or_errors(@operation.create(params), serializer)
      end

      patch '/api/sections/:id' do
        model_or_errors(@operation.update(params), serializer)
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
