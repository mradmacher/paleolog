# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Species < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before do
        @operation = Paleolog::Repository::Species.new(Paleolog.db, authorizer)
      end

      get '/api/species/:id' do
        model_or_errors(@operation.find(params), serializer)
      end

      get '/api/species' do
        model_or_errors(@operation.search(params), serializer, :species)
      end

      post '/api/species' do
        model_or_errors(@operation.create(params), serializer)
      end

      patch '/api/species/:id' do
        model_or_errors(@operation.update(params), serializer)
      end

      private

      def serializer
        lambda do |species|
          {
            id: species.id,
            name: species.name,
            group_id: species.group_id,
            group_name: species.group.name,
            created_at: species.created_at,
          }
        end
      end
    end
  end
end
