# frozen_string_literal: true

require 'sinatra/base'
require 'ostruct'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Occurrences < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects/:project_id/occurrences' do
      authorize!
    end

    before '/api/projects/:project_id/occurrences*' do
      authorize!
    end

    post '/api/projects/:project_id/occurrences' do
      halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

      sample = Paleolog::Repo::Sample.find_for_project(params[:sample_id].to_i, params[:project_id]) if params[:sample_id]
      counting = Paleolog::Repo::Counting.find_for_project(params[:counting_id].to_i, params[:project_id])

      max_rank =
        if counting && sample
          Paleolog::Repo::Occurrence
          .all_for_sample(counting, sample)
          .max_by { |occ| occ.rank }&.rank || 0
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
        }
      }.to_json
    end

    delete '/api/projects/:project_id/occurrences/:id' do
      halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

      occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
      halt 404 if occurrence.nil?

      Paleolog::Repo::Occurrence.delete(occurrence.id)
      counting_summary = Paleolog::CountingSummary.new(
        Paleolog::Repo::Occurrence.all_for_sample(
          OpenStruct.new(id: occurrence.counting_id),
          OpenStruct.new(id: occurrence.sample_id)
        )
      )
      {
        summary: {
          countable: counting_summary.countable_sum,
          uncountable: counting_summary.uncountable_sum,
          total: counting_summary.total_sum,
        },
        occurrence: {
          id: occurrence.id,
        }
      }.to_json
    end

    patch '/api/projects/:project_id/occurrences/:id' do
      halt 403 unless Paleolog::Repo::ResearchParticipation.can_manage_project?(session[:user_id], params[:project_id])

      occurrence = Paleolog::Repo::Occurrence.find_in_project(params[:id], params[:project_id])
      halt 404 if occurrence.nil?

      attributes = {}
      if params.key?(:shift)
        attributes[:quantity] = (occurrence.quantity || 0) + params[:shift].to_i
        attributes[:quantity] = nil if attributes[:quantity] < 0
      end
      attributes[:status] = params[:status] if params.key?(:status)
      attributes[:uncertain] = params[:uncertain] if params.key?(:uncertain)
      occurrence = Paleolog::Repo::Occurrence.update(occurrence.id, attributes) unless attributes.empty?
      counting_summary = Paleolog::CountingSummary.new(
        Paleolog::Repo::Occurrence.all_for_sample(
          OpenStruct.new(id: occurrence.counting_id),
          OpenStruct.new(id: occurrence.sample_id)
        )
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
        }
      }.to_json
    end

    # rubocop:disable Metrics/BlockLength
    get '/projects/:project_id/occurrences' do
      halt 403 unless Paleolog::Repo::ResearchParticipation.can_view_project?(session[:user_id], params[:project_id].to_i)

      @project = Paleolog::Repo::Project.find(params[:project_id].to_i)
      @section = Paleolog::Repo::Section.find_for_project(params[:section].to_i, @project.id) if params[:section]
      @sample = Paleolog::Repo::Sample.find_for_section(params[:sample].to_i, @section.id) if params[:sample]
      if params[:counting]
        @counting = Paleolog::Repo::Counting.find_for_project(params[:counting].to_i,
                                                                  @project.id,)
      end
      if @section.nil? || @counting.nil? || @sample.nil?
        redirect occurrences_path(@project,
                                  counting: @counting || @project.countings.first,
                                  section: @section || @project.sections.first,
                                  sample: @sample || @section&.samples&.first,)
      end

      occurrences =
        if @counting && @sample
          Paleolog::Repo::Occurrence.all_for_sample(@counting, @sample)
        else
          []
        end
      counting_summary = Paleolog::CountingSummary.new(occurrences)

      @summary = OpenStruct.new(
        countable: counting_summary.countable_sum,
        uncountable: counting_summary.uncountable_sum,
        total: counting_summary.total_sum,
      )
      @occurrences = occurrences.map do |occurrence|
        OpenStruct.new(
          id: occurrence.id,
          group_name: occurrence.species.group.name,
          species_name: occurrence.species.name,
          quantity: occurrence.quantity,
          status: occurrence.status,
          status_symbol: Paleolog::CountingSummary.status_symbol(occurrence.status) +
            (occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : ''),
          uncertain: occurrence.uncertain,
        )
      end

      using_project_layout { using_occurrences_layout { display 'occurrences/show.html' } }
    end
    # rubocop:enable Metrics/BlockLength
  end
end
