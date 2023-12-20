# frozen_string_literal: true

require 'sinatra/base'
require_relative '../auth_helpers'

module Web
  # rubocop:disable Metrics/ClassLength
  module Api
    class Occurrences < Sinatra::Base
      helpers Web::AuthHelpers

      before '/api/projects/:project_id/occurrences*' do
        authorize_api!
        @operation = Paleolog::Operation::Occurrence.new(Paleolog::Repo, authorizer)
      end

      # rubocop:disable Metrics/BlockLength
      get '/api/projects/:project_id/occurrences' do
        halt 403 unless authorizer.can_view?(Paleolog::Project, params[:project_id])
        halt 422 unless params[:sample_id] && params[:counting_id]

        project = Paleolog::Repo::Project.find(params[:project_id].to_i)
        sample = Paleolog::Repo::Sample.find_for_project(params[:sample_id].to_i, project.id)
        counting = Paleolog::Repo::Counting.find_for_project(params[:counting_id].to_i, project.id)

        occurrences =
          if counting && sample
            Paleolog::Repo::Occurrence.all_for_sample(counting.id, sample.id)
          else
            []
          end
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
        }.to_json
      end
      # rubocop:enable Metrics/BlockLength

      post '/api/projects/:project_id/occurrences' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        if params[:sample_id]
          sample = Paleolog::Repo::Sample.find_for_project(params[:sample_id].to_i,
                                                           params[:project_id],)
        end
        counting = Paleolog::Repo::Counting.find_for_project(params[:counting_id].to_i, params[:project_id])

        result = @operation.create(
          counting_id: counting&.id,
          sample_id: sample&.id,
          species_id: params[:species_id],
        )
        halt 400, result.error.to_json if result.failure?

        occurrence = Paleolog::Repo::Occurrence.find(
          result.value.id, Paleolog::Repo::Occurrence.with_species_and_group
        )
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
        }.to_json
      end

      delete '/api/projects/:project_id/occurrences/:id' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
        halt 404 if occurrence.nil?

        Paleolog::Repo::Occurrence.delete(occurrence.id)
        counting_summary = Paleolog::CountingSummary.new(
          Paleolog::Repo::Occurrence.all_for_sample(occurrence.counting_id, occurrence.sample_id),
        )
        {
          summary: {
            countable: counting_summary.countable_sum,
            uncountable: counting_summary.uncountable_sum,
            total: counting_summary.total_sum,
          },
          occurrence: {
            id: occurrence.id,
          },
        }.to_json
      end

      # rubocop:disable Metrics/BlockLength
      patch '/api/projects/:project_id/occurrences/:id' do
        halt 403 unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

        occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
        halt 404 if occurrence.nil?

        attributes = {}
        if params.key?(:shift)
          attributes[:quantity] = (occurrence.quantity || 0) + params[:shift].to_i
          attributes[:quantity] = nil if attributes[:quantity].negative?
        elsif params.key?(:quantity)
          attributes[:quantity] = params[:quantity]
        end
        attributes[:status] = params[:status] if params.key?(:status)
        attributes[:uncertain] = params[:uncertain] if params.key?(:uncertain)
        result = @operation.update(occurrence.id, **attributes)
        halt 400, result.error.to_json if result.failure?

        occurrence = result.value
        counting_summary = Paleolog::CountingSummary.new(
          Paleolog::Repo::Occurrence.all_for_sample(occurrence.counting_id, occurrence.sample_id),
        )
        {
          summary: {
            countable: counting_summary.countable_sum,
            uncountable: counting_summary.uncountable_sum,
            total: counting_summary.total_sum,
          },
          occurrence: {
            id: occurrence.id,
            quantity: occurrence.quantity,
            status: occurrence.status,
            status_symbol: Paleolog::CountingSummary.status_symbol(occurrence.status) +
              (occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : ''),
            uncertain: occurrence.uncertain,
          },
        }.to_json
      end
      # rubocop:enable Metrics/BlockLength
    end
    # rubocop:enable Metrics/ClassLength
  end
end
