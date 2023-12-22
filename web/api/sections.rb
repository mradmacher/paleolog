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

      get '/api/projects/:project_id/sections' do
        model_or_errors(@operation.all_for_project(params), serializer, :sections)
      end

      get '/api/sections/:id' do
        model_or_errors(@operation.find(params), serializer)
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
            samples: section.samples.map { |sample| serialize_sample(sample) },
          }
        end
      end

      def serialize_sample(sample)
        {
          id: sample.id,
          section_id: sample.section_id,
          name: sample.name,
          description: sample.description,
          weight: sample.weight ? Kernel.format('%.2f', sample.weight) : nil,
        }
      end
    end
  end
end
