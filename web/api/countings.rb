# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Countings < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before do
        @operation = Paleolog::Operation::Counting.new(Paleolog::Repo, authorizer)
      end

      post '/api/countings' do
        model_or_errors(@operation.create(params), serializer)
      end

      patch '/api/countings/:id' do
        model_or_errors(@operation.update(params), serializer)
      end

      private

      def serializer
        lambda do |counting|
          {
            id: counting.id,
            project_id: counting.project_id,
            name: counting.name,
          }
        end
      end
    end
  end
end
