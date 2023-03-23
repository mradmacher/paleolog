# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Countings < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      post '/api/countings' do
        model_or_errors(*Paleolog::Operation::Counting.update(params, authorizer: authorizer), serializer)
      end

      patch '/api/countings/:id' do
        model_or_errors(*Paleolog::Operation::Counting.update(params, authorizer: authorizer), serializer)
      end

      private

      def serializer
        lambda do |counting|
          {
            id: counting.id,
            project_id: counting.project_id,
            name: counting.name,
            created_at: counting.created_at,
            updated_at: counting.updated_at,
          }
        end
      end
    end
  end
end
