# frozen_string_literal: true

require 'sinatra/base'
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

    get '/projects/:project_id/occurrences' do
      redirect projects_path unless Paleolog::Repo::ResearchParticipation.can_view_project?(session[:user_id],
                                                                                            params[:project_id].to_i,)

      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_participations,
      )
      if params[:counting]
        @counting = Paleolog::Repo::Counting.find_for_project(params[:counting].to_i,
                                                              @project.id,)
      end
      @section = Paleolog::Repo::Section.find_for_project(params[:section].to_i, @project.id) if params[:section]
      if @section && params[:sample]
        @sample = Paleolog::Repo::Sample.find_for_section(params[:sample].to_i,
                                                          @section.id,)
      end
      if @section.nil? || @counting.nil? || @sample.nil?
        redirect occurrences_path(@project,
                                  counting: @counting || @project.countings.first,
                                  section: @section || @project.sections.first,
                                  sample: @sample || @section&.samples&.first,)
      end

      using_project_layout { using_occurrences_layout { display 'occurrences/show.html' } }
    end
  end
end
