# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'
require_relative '../api_helpers'

module Web
  module Api
    class Occurrences < Sinatra::Base
      helpers Web::AuthHelpers
      helpers Web::ApiHelpers

      before '/api/projects/:project_id/occurrences*' do
        authorize_api!
        @operation = Paleolog::Repository::Occurrence.new(Paleolog.db, authorizer)
        @project_operation = Paleolog::Repository::Project.new(Paleolog.db, authorizer)
        @sample_operation = Paleolog::Repository::Sample.new(Paleolog.db, authorizer)
        @counting_operation = Paleolog::Repository::Counting.new(Paleolog.db, authorizer)
      end

      # rubocop:disable Metrics/BlockLength
      get '/api/projects/:project_id/occurrences' do
        project, sample, counting = nil
        result = @project_operation
          .find(id: params[:project_id])
          .on_success { project = _1 }
          .and_then { @sample_operation.find(id: params[:sample_id], project_id: project.id) }
          .on_success { sample = _1 }
          .and_then do
            @counting_operation.find(id: params[:counting_id], project_id: project.id)
          end
          .on_success { counting = _1 }
          .and_then do
            if counting && sample
              @operation.find_all(counting_id: counting.id, sample_id: sample.id)
            else
              Resonad.success([])
            end
          end

        render_json(result) do |occurrences|
          counting_summary = Paleolog::CountingSummary.new(occurrences)
          {
            occurrences: occurrences.map do |occurrence|
              {
                id: occurrence.id,
                group_name: occurrence.species.group.name,
                species_name: occurrence.species.name,
                quantity: occurrence.quantity,
                status: occurrence.status,
                status_symbol: Paleolog::CountingSummary.status_symbol(occurrence.status) +
                  (occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : ''),
                uncertain: occurrence.uncertain,
              }
            end,
            summary: {
              countable: counting_summary.countable_sum,
              uncountable: counting_summary.uncountable_sum,
              total: counting_summary.total_sum,
            },
          }
        end
      end
      # rubocop:enable Metrics/BlockLength

      post '/api/projects/:project_id/occurrences' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        sample, counting = nil
        @sample_operation.find(id: params[:sample_id], project_id: params[:project_id])
                         .on_success { sample = _1 }
        @counting_operation.find(id: params[:counting_id], project_id: params[:project_id])
                           .on_success { counting = _1 }
        result = @operation.create(
          counting_id: counting&.id,
          sample_id: sample&.id,
          species_id: params[:species_id],
        )
        render_json(result) do |occurrence|
          {
            occurrence: {
              id: occurrence.id,
              group_name: occurrence.species.group.name,
              species_name: occurrence.species.name,
              quantity: occurrence.quantity,
              status: occurrence.status,
              status_symbol: Paleolog::CountingSummary.status_symbol(occurrence.status) +
                (occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : ''),
              uncertain: occurrence.uncertain,
            },
          }
        end
      end
      delete '/api/projects/:project_id/occurrences/:id' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        occurrence = nil
        result = @operation.find(id: params[:id], project_id: params[:project_id])
                           .on_success { occurrence = _1 }
                           .and_then { @operation.delete(id: occurrence.id) }
                           .and_then do
          @operation.find_all(counting_id: occurrence.counting_id,
                              sample_id: occurrence.sample_id,)
        end
        render_json(result) do |occurrences|
          counting_summary = Paleolog::CountingSummary.new(occurrences)
          {
            summary: {
              countable: counting_summary.countable_sum,
              uncountable: counting_summary.uncountable_sum,
              total: counting_summary.total_sum,
            },
            occurrence: {
              id: occurrence.id,
            },
          }
        end
      end

      # rubocop:disable Metrics/BlockLength
      patch '/api/projects/:project_id/occurrences/:id' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        the_occurrence = nil
        result = @operation
          .find(id: params[:id], project_id: params[:project_id])
          .and_then do |occurrence|
            attributes = {}
            if params.key?(:shift)
              attributes[:quantity] = (occurrence.quantity || 0) + params[:shift].to_i
              attributes[:quantity] = nil if attributes[:quantity].negative?
            elsif params.key?(:quantity)
              attributes[:quantity] = params[:quantity]
            end
            attributes[:status] = params[:status] if params.key?(:status)
            attributes[:uncertain] = params[:uncertain] if params.key?(:uncertain)
            attributes[:id] = occurrence.id
            @operation.update(**attributes)
          end
          .on_success { the_occurrence = _1 }
          .and_then do |occurrence|
            @operation.find_all(counting_id: occurrence.counting_id, sample_id: occurrence.sample_id)
          end

        render_json(result) do |occurrences|
          counting_summary = Paleolog::CountingSummary.new(occurrences)
          {
            summary: {
              countable: counting_summary.countable_sum,
              uncountable: counting_summary.uncountable_sum,
              total: counting_summary.total_sum,
            },
            occurrence: {
              id: the_occurrence.id,
              quantity: the_occurrence.quantity,
              status: the_occurrence.status,
              status_symbol: Paleolog::CountingSummary.status_symbol(the_occurrence.status) +
                (the_occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : ''),
              uncertain: the_occurrence.uncertain,
            },
          }
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
