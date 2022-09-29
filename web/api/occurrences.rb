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
      end

      # rubocop:disable Metrics/BlockLength
      post '/api/projects/:project_id/occurrences' do
        halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

        if params[:sample_id]
          sample = Paleolog::Repo::Sample.find_for_project(params[:sample_id].to_i, params[:project_id])
        end
        counting = Paleolog::Repo::Counting.find_for_project(params[:counting_id].to_i, params[:project_id])

        max_rank =
          if counting && sample
            Paleolog::Repo::Occurrence
              .all_for_sample(counting, sample)
              .max_by(&:rank)&.rank || 0
          else
            0
          end
        occurrence = Paleolog::Occurrence.new(
          species_id: params[:species_id],
          counting_id: counting&.id,
          sample_id: sample&.id,
          status: params[:status] || Paleolog::CountingSummary::NORMAL,
          rank: max_rank + 1,
        )
        contract = Paleolog::Contract::Occurrence.new(occurrence_repo: Paleolog::Repo::Occurrence)
        validations = contract.call(occurrence.defined_attributes)
        halt 400, validations.errors.to_h.to_json if validations.errors.any?

        occurrence = Paleolog::Repo.save(occurrence)
        {
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

      delete '/api/projects/:project_id/occurrences/:id' do
        halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

        occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
        halt 404 if occurrence.nil?

        Paleolog::Repo::Occurrence.delete(occurrence.id)
        counting_summary = Paleolog::CountingSummary.new(
          Paleolog::Repo::Occurrence.all_for_sample(
            OpenStruct.new(id: occurrence.counting_id),
            OpenStruct.new(id: occurrence.sample_id),
          ),
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
        halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

        occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
        halt 404 if occurrence.nil?

        attributes = {}
        if params.key?(:shift)
          attributes[:quantity] = (occurrence.quantity || 0) + params[:shift].to_i
          attributes[:quantity] = nil if attributes[:quantity].negative?
        end
        attributes[:status] = params[:status] if params.key?(:status)
        attributes[:uncertain] = params[:uncertain] if params.key?(:uncertain)
        occurrence = Paleolog::Repo::Occurrence.update(occurrence.id, attributes) unless attributes.empty?
        counting_summary = Paleolog::CountingSummary.new(
          Paleolog::Repo::Occurrence.all_for_sample(
            OpenStruct.new(id: occurrence.counting_id),
            OpenStruct.new(id: occurrence.sample_id),
          ),
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
