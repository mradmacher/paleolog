# frozen_string_literal: true

require 'sinatra/base'
require 'ostruct'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  # rubocop:disable Metrics/ClassLength
  class Occurrences < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects/:project_id/occurrences' do
      authorize!
    end

    # rubocop:disable Metrics/BlockLength
    get '/projects/:project_id/occurrences' do
      redirect projects_path unless Paleolog::Repo::ResearchParticipation.can_view_project?(session[:user_id],
                                                                                            params[:project_id].to_i,)

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
  # rubocop:enable Metrics/ClassLength
end
