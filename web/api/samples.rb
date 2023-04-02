# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Samples < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      post '/api/samples' do
        model_or_errors(*Paleolog::Operation::Sample.create(params, authorizer: authorizer), serializer)
      end

      patch '/api/samples/:id' do
        model_or_errors(*Paleolog::Operation::Sample.update(params, authorizer: authorizer), serializer)
      end

      private

      def serializer
        lambda do |sample|
          {
            id: sample.id,
            section_id: sample.section_id,
            name: sample.name,
            description: sample.description,
            weight: sample.weight,
          }
        end
      end
    end
  end
end
