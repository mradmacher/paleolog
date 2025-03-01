# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Countings < Sinatra::Base
      helpers Web::AuthHelpers, Web::ApiHelpers

      before do
        @operation = Paleolog::Repository::Counting.new(Paleolog.db, authorizer)
      end

      get '/api/countings/:id' do
        model_or_errors(@operation.find(params), serializer)
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
          }.tap do |h|
            h[:marker_count] = counting.marker_count if counting.marker_count
            h[:marker_id] = counting.marker_id if counting.marker_id
            h[:marker_name] = counting.marker.name unless counting.marker.nil?
            h[:marker_group_name] = counting.marker.group.name unless counting.marker.nil?
            h[:group_id] = counting.group_id if counting.group_id
            h[:group_name] = counting.group.name unless counting.group.nil?
          end
        end
      end
    end
  end
end
